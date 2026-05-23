---@class MeadowsORM: Atomic.Package
local package = current()

local PRIMARY_KEY = package.constraints.column.PRIMARY_KEY

---@alias MeadowsORM.TableBuilder.Column { name: string, type: MeadowsORM.Table.Type, constraints?: integer, default?: (string | MeadowsORM.RawSQL), onUpdate?: (integer | MeadowsORM.RawSQL) }

---@type MeadowsORM.RawSQL
local RawSQL = package:getClass("RawSQL")

---@class MeadowsORM.TableBuilder
---@field private _tableName string
---@field private _columns MeadowsORM.TableBuilder.Column[]
---@field private _columnsMap table<string, integer>
---@field private _constraints string[]
---@field private _primaryKey? string
---@field private _indexes? [(string | string[]), boolean, boolean][]
local TableBuilder = package:class("TableBuilder")

---@param tableName string
function TableBuilder:init(tableName)
  self._tableName = tableName
  self._columns = {}
  self._columnsMap = {}
  self._constraints = {}
  self._indexes = {}
end

---@return string
function TableBuilder:getName()
  return self._tableName
end

---@return string
function TableBuilder:getPrimaryKey()
  return self._primaryKey
end

---@private
---@param columnName string
---@param columnConstraints integer
function TableBuilder:setPrimaryKey(columnName, columnConstraints)
  if (not self._primaryKey and self:isColumnHasConstraint(columnName, columnConstraints)) then
    self._primaryKey = columnName
  end
end

---@param columnName string
---@param requiredConstraint integer
function TableBuilder:isColumnHasConstraint(columnName, requiredConstraint)
  local column = self:getColumnByName(columnName)

  if (not column) then
    return false
  end

  return bit.band(column.constraints or 0, requiredConstraint) == requiredConstraint
end

---@param name string
---@param type string
---@param columnConstraints? integer
---@param default? string | MeadowsORM.RawSQL
---@param onUpdate? integer | MeadowsORM.RawSQL
function TableBuilder:column(name, type, columnConstraints, default, onUpdate)
  if (self._columns[name]) then
    error("column " .. tostring(name) .. " is already exists")
  end

  local id = #self._columns+1
  self._columns[id] = { name = name, type = type, constraints = columnConstraints, default = default, onUpdate = onUpdate }
  self._columnsMap[name] = id

  if (not self._primaryKey and self:isColumnHasConstraint(name, PRIMARY_KEY)) then
    self._primaryKey = name
  end
end

---@return MeadowsORM.TableBuilder.Column[]
function TableBuilder:getColumns()
  return self._columns
end

---@param columnName string
---@return MeadowsORM.Table.Type?
function TableBuilder:getColumnType(columnName)
  return self:getColumnByName(columnName).type
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

---@return string[]?
---@return string[]?
function TableBuilder:getIndexes()
  local indexes = self._indexes

  if (not indexes) then
    return
  end

  local result = {}

  for _, entry in ipairs(indexes) do
    local indexList = entry[1]

    if (istable(indexList)) then
      ---@cast indexList string[]

      for _, value in ipairs(indexList) do
        result[#result + 1] = value
      end
    else
      ---@cast indexList string
      result[#result + 1] = indexList
    end
  end

  return result
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
---@param internalColumn string
---@param currentColumn string
---@param onDelete? integer
---@return self
function TableBuilder:relation(builder, internalColumn, currentColumn, onDelete)
  local t1 = builder:getColumnTypeOrThrow(internalColumn)
  local t2 = self:getColumnTypeOrThrow(currentColumn)

  -- types of related columns should be equal
  if (t1 ~= t2) then
    error(tostring(builder:getName()) .. "." .. tostring(internalColumn) .. ": expected " .. tostring(t1) .. ", got " .. tostring(self:getName()) .. "." .. tostring(currentColumn) .. " (" .. tostring(t2) .. ")")
  end

  ---@type string?
  local onDeleteStr

  if (onDelete) then
    local onDeleteConstraints = package.constraints:toArray("action", onDelete)

    if (#onDeleteConstraints > 1) then
      error("the number of `ON DELETE` constraints must be exactly one")
    end

    onDeleteStr = onDeleteConstraints[1]
  end

  local onDeleteSql = (onDeleteStr and " " .. " ON DELETE " .. SQLStr(onDeleteStr, true) or "")
  self._constraints[#self._constraints+1] = ("FOREIGN KEY (`%s`) REFERENCES `%s` (`%s`)%s"):format(SQLStr(currentColumn, true), SQLStr(builder:getName(), true), SQLStr(internalColumn, true), onDeleteSql)

  return self
end

---@param columns string | string[]
---@param isUnique? boolean @default = false
---@param isCacheOnly? boolean @default = false
function TableBuilder:index(columns, isUnique, isCacheOnly)
  self._indexes[#self._indexes+1] = { columns, isUnique or false, isCacheOnly or false }
end

---@return string[]
function TableBuilder:buildColumns()
  local result = {}

  for i, c in ipairs(self._columns) do
    local constraints = table.concat(package.constraints:toArray("column", c.constraints or 0), " ")
    ---@diagnostic disable-next-line
    local default = c.default and " DEFAULT " .. (isInstanceOf(c.default, RawSQL) and c.default:read() or SQLStr(c.default)) or ""
    ---@diagnostic disable-next-line
    local onUpdate = c.onUpdate and " ON UPDATE " .. (isInstanceOf(c.onUpdate, RawSQL) and c.onUpdate:read() or SQLStr(c.onUpdate)) or ""
    result[i] = "`" .. SQLStr(c.name, true) .. "` " .. SQLStr(c.type, true) .. "" .. (#constraints > 0 and " " .. constraints or "") .. default .. onUpdate
  end

  return result
end

---@return string[]?
function TableBuilder:buildIndexes()
  local result = {}

  for _, index in ipairs(self._indexes) do
    local isCacheOnly = index[3]

    if (isCacheOnly) then
      continue
    end

    local columns = index[1]
    ---@diagnostic disable-next-line
    local indexName = istable(columns) and table.concat(columns, "_") or columns
    ---@cast indexName string
    ---@diagnostic disable-next-line
    local columnsList = istable(columns) and table.concat(columns, ",") or columns

    result[#result+1] = ("CREATE INDEX%s %s ON %s(%s)"):format(index[2] and " " .. "UNIQUE" .. " " or "", SQLStr(indexName, true), SQLStr(self._tableName, true), columnsList)
  end

  return result
end

---@param tab1 string[]
---@param tab2 string[]
---@return string[]
local function mix(tab1, tab2)
  local result = {}

  for _, v in ipairs(tab1) do
    result[#result+1] = v
  end

  for _, v in ipairs(tab2) do
    result[#result+1] = v
  end

  return result
end

--- Builds self into SQL query string
---@return string[]
function TableBuilder:build()
  local table = ("CREATE TABLE IF NOT EXISTS `%s` (%s)"):format(SQLStr(self._tableName, true), table.concat(mix(self:buildColumns(), self._constraints), ", "))
  local indexes = self:buildIndexes()

  return { table, indexes and unpack(indexes) or nil }
end