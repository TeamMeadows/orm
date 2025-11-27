---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.SelectBuilder
local SelectBuilder = package:getClass("SelectBuilder")

---@type MeadowsORM.InsertBuilder
local InsertBuilder = package:getClass("InsertBuilder")

---@type MeadowsORM.UpdateBuilder
local UpdateBuilder = package:getClass("UpdateBuilder")

---@type MeadowsORM.DeleteBuilder
local DeleteBuilder = package:getClass("DeleteBuilder")

---@class MeadowsORM.TableInterface<T>
---@field private _table MeadowsORM.Table
---@field private _class? Atomic.Class
---@field private _cache? table<string | number, table> Not array (don't use it in ipairs!)
local TableInterface = package:class("TableInterface")

---@param table MeadowsORM.Table
function TableInterface:init(table)
  self._table = table

  ---@diagnostic disable-next-line invisible
  self._primaryKey = self._table._builder:getPrimaryKey()

  ---@diagnostic disable-next-line invisible
  if (self._table._cache) then
    self._cache = {}
  end
end

---@return string
function TableInterface:getTableName()
  return self._table:getName()
end

---@private
---@async
---@generic T: Atomic.Class
---@param shouldReturn boolean Should SQL query return data?
---@param joins? {  }[] -- todo
---@return (T | table)[] | nil
function TableInterface:query(query, shouldReturn, joins)
  local data, err = package.database.query(query)

  if (err) then
    package.logger:err("an error occurred while performing the query %s: %s", debug.getcaller(2), err)

    return {}
  end

  if (shouldReturn) then
    local results, casted = self:normalizeResults(data, joins)

    if (self._cache) then
      self:cache(results, casted or results)
    end

    return casted or results
  end
end

---@type table<MeadowsORM.Table.Type, { in: fun(value: string | number): any; out: fun(value: any): string }>
local convertors = {
  -- todo
  ---@diagnostic disable-next-line
  timestamp = { ["in"] = function(s) return end, ["out"] = function(s) return end, },
  ---@diagnostic disable-next-line
  bool = { ["in"] = function(b) return tobool(b) end, out = function(b) return b and "1" or "0" end},
  ---@diagnostic disable-next-line
  json = { ["in"] = function(s) return util.JSONToTable(s) end, out = function(t) return util.TableToJSON(t) end }
}

---@param value any
---@param type MeadowsORM.Table.Type
---@return any
local function normalizeValue(value, type)
  local convertor = convertors[type] or {}
  local cIn = convertor["in"]

  if (not cIn) then
    return value
  end

  return cIn(value)
end

---@private
---@generic T: Atomic.Class
---@param rows (string | number)[][]
---@param joins? table
---@return T[], T[]?
function TableInterface:normalizeResults(rows, joins)
  if (#rows == 0) then
    return rows
  end

  local class = self._table:getDeserializationClass()

  ---@diagnostic disable-next-line invisible
  local builder = self._table._builder
  ---@diagnostic disable-next-line invisible
  local types = builder._columnsMap

  ---@type table<string, any>[]
  local normalized = {}

  for i, row in ipairs(rows) do
    normalized[i] = {}

    for rowInd, rowValue in ipairs(row) do
      -- todo join support
      local column = builder:getColumn(rowInd)

      if (not column) then
        error("unknown column №" .. tostring(rowInd) .. " with value `" .. tostring(rowValue) .. "`")
      end

      normalized[i][column.name] = normalizeValue(rowValue, column.type)
    end
  end

  if (not class) then
    return normalized
  end

  local casted = {}

  for i, row in ipairs(normalized) do
    casted[i] = new(class, row)
  end

  return normalized, casted
end

---@private
---@params raw table[] Raw data from database
---@params normalized table[] Casted `raw` to class
function TableInterface:cache(raw, normalized)
  local key = self._primaryKey

  for i, value in ipairs(raw) do
    self._cache[value[key]] = normalized[i]
  end
end

---@param ind integer | string
---@return table?
function TableInterface:findCached(ind)
  return self._cache[ind]
end

--- ``Warning``: This method searches for a cached object based on its column value.
--- Note that if your class does not have a field with the column name,
--- it will not be able to find this object in the cache.
---@param column string
---@param value any
---@return table[] foundObjects
function TableInterface:findCachedByFilter(column, value)
  local result = {}

  for primary, obj in pairs(self._cache) do
    if (obj[column] == value) then
      result[#result+1] = obj
    end
  end

  return result
end

--- ``Warning``: This method searches for a cached object based on its column value.
--- Note that if your class does not have a field with the column name,
--- it will not be able to find this object in the cache.
---@param column string
---@param value any
---@return { index: string, row: table }[] foundObjects
function TableInterface:findCachedByFilterNumerated(column, value)
  local result = {}

  for primary, obj in pairs(self._cache) do
    if (obj[column] == value) then
      result[#result+1] = { index = primary, row = obj }
    end
  end

  return result
end

---@param ind integer | string
---@param t table
---@return table?
function TableInterface:updateCached(ind, t)
  self._cache[ind] = t
end

---@param ind integer | string
---@return table?
function TableInterface:deleteCached(ind)
  self._cache[ind] = nil
end

---@return integer
function TableInterface:cacheLength()
  return self._cache and #self._cache or 0
end

---@alias MeadowsORM.TableInterface.WhereClause table<string, string | number | boolean | table<MeadowsORM.SelectBuilder.WhereCompareIndexes, string | number | boolean>>

---@class MeadowsORM.TableInterface.FindUniqueArgs
---@field where MeadowsORM.TableInterface.WhereClause
---@field select? table<string, true>
---@field include? table<string, true>

--- ```lua
--- prepareValue(NULL) => "NULL"
--- prepareValue("somedata") => "somedata"
--- ```
---@param v any
---@return any
local prepareValue = function(v)
  return isentity(v) and "NULL" or v
end

--- ```lua
--- local compareSymbol, value = parseFieldOfWhere("value")
--- print(compareSymbol, value) -- "equals", "value"
---
--- local compareSymbol, value = parseFieldOfWhere(NULL)
--- print(compareSymbol, value) -- "equals", "NULL"
---
--- local compareSymbol, value = parseFieldOfWhere({ lt: "value" })
--- print(compareSymbol, value) -- "lt", "value"
--- ```
-- -@param tab string | table<MeadowsORM.SelectBuilder.WhereCompareIndexes, string | number | boolean>
---@param tab MeadowsORM.TableInterface.WhereClause
---@param builder MeadowsORM.SelectBuilder
local applyWhere = function(builder, tab)
  for columnName, tab in pairs(tab) do
    if (type(tab) == "table") then
      local ind = next(tab)
      builder:where("and", columnName, prepareValue(tab[ind]), ind)
      continue
    end

    builder:where("and", columnName, prepareValue(tab), "equals")
  end
end

---@param builder MeadowsORM.SelectBuilder
---@param params MeadowsORM.TableInterface.FindFirstArgs | MeadowsORM.TableInterface.FindUniqueArgs
local function applySelectParams(builder, params)
  if (params.where) then
    applyWhere(builder, params.where)
  end

  if (params.select) then
    builder:select(params.select)
  end

  if (params.include) then
    for name in pairs(params.include) do
      builder:include(name)
    end
  end

  if (params.orderBy) then
    for column, order in pairs(params.orderBy) do
      builder:addOrderBy(column, order)
    end
  end
end

local isValueIn = function(tab, required, required2)
  for _, v in ipairs(tab) do
    if (v == required or v == required2) then
      return true
    end
  end

  return false
end

---@async
---@param params MeadowsORM.TableInterface.FindUniqueArgs
---@return table?
function TableInterface:findUnique(params)
  for column in pairs(params.where) do
    ---@diagnostic disable-next-line invisible
    local columnT = self._table._builder:getColumnByName(column)

    -- primary key automatically set unique on your column
    if (not columnT or not columnT.constraints or not isValueIn(columnT.constraints, "unique", "primary key")) then
      error("column `" .. tostring(column) .. "` should be unique")
    end
  end

  local builder = new(SelectBuilder, self._table)
  builder:limit(1)

  applySelectParams(builder, params)

  local rows = self:query(builder:build(), true)
  return type(rows) == "table" and rows[1] or nil
end

---@class MeadowsORM.TableInterface.FindFirstArgs: MeadowsORM.TableInterface.FindUniqueArgs
---@field orderBy? table<string, "asc" | "desc">

---@async
---@param params MeadowsORM.TableInterface.FindFirstArgs
---@return table?
function TableInterface:findFirst(params)
  local builder = new(SelectBuilder, self._table)
  builder:limit(1)

  applySelectParams(builder, params)

  local rows = self:query(builder:build(), true)
  return type(rows) == "table" and rows[1] or nil
end

---@async
---@param params? MeadowsORM.TableInterface.FindFirstArgs
---@return table[]?
function TableInterface:findMany(params)
  local builder = new(SelectBuilder, self._table)

  if (params) then
    applySelectParams(builder, params)
  end

  return self:query(builder:build(), true)
end