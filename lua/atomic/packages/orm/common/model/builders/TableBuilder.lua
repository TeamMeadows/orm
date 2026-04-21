---@class MeadowsORM: Atomic.Package
local package = current()

---@alias MeadowsORM.TableBuilder.Column { name: string, type: MeadowsORM.Table.Type, constraints?: MeadowsORM.Table.Constraints[], default?: string, onUpdate?: MeadowsORM.Table.Constraints.OnAction }

---@class MeadowsORM.TableBuilder
---@field private _tableName string
---@field private _columns MeadowsORM.TableBuilder.Column[]
---@field private _columnsMap table<string, integer>
---@field private _constraints string[]
---@field private _primaryKey? string
local TableBuilder = package:class("TableBuilder")

---@param tableName string
function TableBuilder:init(tableName)
  self._tableName = tableName
  self._columns = {}
  self._columnsMap = {}
  self._constraints = {}
end

---@return string
function TableBuilder:getName()
  return self._tableName
end

---@return string
function TableBuilder:getPrimaryKey()
  return self._primaryKey
end

---@param columnName string
---@param constraints MeadowsORM.Table.Constraints[]
function TableBuilder:trySetPrimaryKey(columnName, constraints)
  for _, constraint in ipairs(constraints) do
    if (constraint == "primary key") then
      self._primaryKey = columnName
      break
    end
  end
end

---@param name string
---@param type string
---@param constraints? MeadowsORM.Table.Constraints[]
---@param default? string
---@param onUpdate? MeadowsORM.Table.Constraints.OnAction
function TableBuilder:column(name, type, constraints, default, onUpdate)
  if (not self._primaryKey and constraints) then
    self:trySetPrimaryKey(name, constraints)
  end

  local id = #self._columns+1
  self._columns[id] = { name = name, type = type, constraints = constraints, default = default, onUpdate = onUpdate }
  self._columnsMap[name] = id
end

---@return MeadowsORM.TableBuilder.Column[]
function TableBuilder:getColumns()
  return self._columns
end

---@param columnName string
---@return MeadowsORM.Table.Type?
function TableBuilder:getColumnType(columnName)
  return self:getColumnByName(columnName).name
end

---@param columnIndex integer
---@return MeadowsORM.TableBuilder.Column?
function TableBuilder:getColumn(columnIndex)
  return self._columns[columnIndex]
end

---@param columnName string
---@return MeadowsORM.TableBuilder.Column?
function TableBuilder:getColumnByName(columnName)
  local id = self._columnsMap[columnName]

  return self._columns[id]
end

---@private
---@param columnName string
---@return MeadowsORM.Table.Type
function TableBuilder:getColumnTypeOrThrow(columnName)
  local column = self:getColumnByName(columnName)

  if (not column) then
    error("table " .. tostring(self:getName()) .. " does not have column \"" .. tostring(columnName) .. "\"")
  end

  return column.type
end

---@param builder MeadowsORM.TableBuilder
---@param column string
---@param thisColumn string
---@param onDelete? MeadowsORM.Table.Constraints.OnAction | string
---@return self
function TableBuilder:relation(builder, column, thisColumn, onDelete)
  local t1 = builder:getColumnTypeOrThrow(column)
  local t2 = self:getColumnTypeOrThrow(thisColumn)

  if t1 ~= t2 then
    -- types of related columns should be equal
    error(builder:getName() .. "." .. column .. ": expected " .. t1 .. ", got " .. self:getName() .. "." .. thisColumn .. " (" .. t2 .. ")")
  end

  local constraintSql = "FOREIGN KEY (`" .. SQLStr(thisColumn, true) .. "`) REFERENCES `" .. SQLStr(builder:getName(), true) .. "` (`" .. SQLStr(column, true) .. "`)" .. (onDelete and " " .. " ON DELETE " .. SQLStr(onDelete, true) or "")

  self._constraints[#self._constraints+1] = constraintSql

  return self
end

local constrainsOrder = { "primary key", "auto_increment", "not null", "unique" }

---@param constraints string[]?
---@return string
local function buildColumnConstraints(constraints)
  if (not constraints or #constraints == 0) then
    return ""
  end

  local order = {}
  for i, v in ipairs(constrainsOrder) do
    order[v] = i
  end

  table.sort(constraints, function(a, b)
    return order[a] < order[b]
  end)

  local str = table.concat(constraints, " ")

  return #str > 0 and " " .. str or str
end

---@return string[]
function TableBuilder:buildColumns()
  local result = {}

  for i, c in ipairs(self._columns) do
    local constraints = buildColumnConstraints(c.constraints)
    local default = c.default and " DEFAULT " .. c.default or "" -- yep we won't escape it
    local onUpdate = c.onUpdate and " ON UPDATE " .. SQLStr(c.onUpdate, true) or ""
    result[i] = "`" .. c.name .. "` " .. c.type .. "" .. constraints .. default .. onUpdate
  end

  return result
end

---@param tab1 any[]
---@param tab2 any[]
local function mix(tab1, tab2)
  for _, v in ipairs(tab2) do
    tab1[#tab1+1] = v
  end
end

--- Builds self into SQL query string
---@return string
function TableBuilder:build()
  local query = "CREATE TABLE IF NOT EXISTS `" .. SQLStr(self._tableName, true) .. "` ("

  local body = {}

  -- columns
  local columns = self:buildColumns()
  mix(body, columns)
  -- constraints
  mix(body, self._constraints)

  -- build body
  local count = #body -- body count lol
  for i, v in ipairs(body) do
    query = query .. v .. (i == count and "" or ",")
  end

  query = query .. ")"

  package.logger:trace(query)

  return query
end