---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.Entity
local Entity = package:getClass("Entity")

---@type MeadowsORM.SelectBuilder
local SelectBuilder = package:getClass("SelectBuilder")

---@type MeadowsORM.InsertBuilder
local InsertBuilder = package:getClass("InsertBuilder")

---@type MeadowsORM.UpdateBuilder
local UpdateBuilder = package:getClass("UpdateBuilder")

---@type MeadowsORM.DeleteBuilder
local DeleteBuilder = package:getClass("DeleteBuilder")

--- Class that provides interaction with Database instance
---@class MeadowsORM.TableInterface<T>
---@field private _table MeadowsORM.Table
---@field private _class? Atomic.Class
---@field private _cache? table<(string | number), table> Not array (don't use it in ipairs!)
---@field private _cacheLength? integer
local TableInterface = package:class("TableInterface")

---@param table MeadowsORM.Table
function TableInterface:init(table)
  self._table = table

  ---@diagnostic disable-next-line invisible
  self._primaryKey = self._table._builder:getPrimaryKey()

  ---@diagnostic disable-next-line invisible
  if (self._table._cache) then
    self._cache = {}
    self._cacheLength = 0
  end
end

---@private
function TableInterface:__tostring()
  return "TableInterface [" .. tostring(self:getTableName()) .. "]"
end

---@return string
function TableInterface:getTableName()
  return self._table:getName()
end

---@return string
function TableInterface:getPrimaryKey()
  return self._primaryKey
end

---@param snakeCase string
---@return string PascalCase
local function snakeCaseToPascalCase(snakeCase)
  return (snakeCase:gsub("_(%l)", string.upper):gsub("^%l", string.upper))
end

---@param package Atomic.Package
---@param className string
---@return MeadowsORM.Entity
function TableInterface:entity(package, className)
  ---@type MeadowsORM.Entity
  local newEntity = package:class(className, Entity) -- class, not a instance of a class
  -- in this case we set an TableInterface reference as a STATIC variable
  -- (that would be available for all instances of new Entity inherited class), not a variable of instance of a class
  newEntity:setDatabase(self)

  if (self._table:getDeserializationClass() ~= nil) then
    error(tostring(self._table) .. " already has a deserialization class!")
  end

  self._table:deserializationClass(newEntity)

  for _, column in ipairs(self._table:getColumns()) do
    newEntity:accessor(column.name, snakeCaseToPascalCase(column.name))
  end

  return newEntity
end

---@private
---@async
---@generic T: Atomic.Class
---@param shouldReturn boolean Should SQL query return data?
---@param joins? {}[] -- todo
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

---@param timestamp string
---@return Atomic.Time.NaiveDateTime?
local function timestampToNaive(timestamp)
  if (not timestamp) then
    return
  end

  local iso = timestamp:gsub(" ", "T")
  return atomic.time.naiveDateTime.fromIso8601(iso)
end

---@param naive Atomic.Time.NaiveDateTime
---@return string?
local function naiveToTimestamp(naive)
  if (not naive) then
    return
  end

  local iso = naive:getIso8601()
  return select(1, iso:gsub("T", " "))
end

-- in - serialization & out - deserialization
---@type table<MeadowsORM.Table.Type, { in: fun(value: (string | number)): any, out: fun(value: any): string }>
local convertors = {
  timestamp = { ["in"] = timestampToNaive, out = naiveToTimestamp },
  ---@diagnostic disable-next-line
  bool = { ["in"] = tobool, out = function(b) return b and "TRUE" or "FALSE" end},
  ---@diagnostic disable-next-line
  json = { ["in"] = util.JSONToTable, out = util.TableToJSON }
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

  return cIn(value) or NULL
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
  -- todo join support
  for i, row in ipairs(rows) do
    local object = {}

    ---@diagnostic disable-next-line invisible
    for columnId, column in ipairs(self._table._builder._columns) do
      object[column.name] = normalizeValue(row[columnId], column.type)
    end

    normalized[i] = object
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

  self._cacheLength = self._cacheLength + 1
end

---@param ind integer | string
---@return table?
function TableInterface:findCached(ind)
  return self._cache[ind]
end

--- ``Warning``: This method searches for a cached object based on its column value.
---
--- Note that if your class does not have a field with the column name,
--- it will not be able to find this object in the cache.
---@param column string
---@param value any
---@return table[] foundObjects
function TableInterface:findCachedByFilter(column, value)
  local result = {}

  for _, obj in pairs(self._cache) do
    if (obj[column] == value) then
      result[#result+1] = obj
    end
  end

  return result
end

--- ``Warning``: This method searches for a cached object based on its column value.
---
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
function TableInterface:updateCache(ind, t)
  local oldValue = self._cache[ind]

  if (not oldValue) then
    return
  end

  self._cache[ind] = t

  return oldValue
end

---@param ind integer | string
---@return table?
function TableInterface:deleteFromCache(ind)
  local oldValue = self._cache[ind]

  self._cache[ind] = nil
  self._cacheLength = self._cacheLength - 1

  return oldValue
end

---@param column string
---@param value any
---@return table?
function TableInterface:deleteFromCacheByFilter(column, value)
  for primary, obj in pairs(self._cache) do
    if (obj[column] == value) then
      return self:deleteFromCache(primary)
    end
  end
end

---@private
---@return table?
function TableInterface:getCache()
  return self._cache
end

---@return integer
function TableInterface:getCacheLength()
  return self._cacheLength
end

---@alias MeadowsORM.TableInterface.WhereClause table<string, string | number | boolean | table<MeadowsORM.WhereBuilder.WhereCompareIndexes, (string | number | boolean)>>

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
  -- todo проверить v == NULL (так надёжнее)
  -- upd нахуй надо? в любом случае если ты энтити пушишь то ты его в бд не сохранишь, ебло, оно просто Entity:__tostring ебанёт и эту хуйню в бд закинет лол
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
---@param builder { where: fun(self, method: string, column: string, value: any, compare: MeadowsORM.WhereBuilder.WhereCompareIndexes) }
local applyWhere = function(builder, tab)
  for columnName, tab in pairs(tab) do
    if (type(tab) == "table") then
      local ind = next(tab)
      builder:where("and", columnName, prepareValue(tab[ind]), ind)
      continue
    end

    builder:where("and", columnName, prepareValue(tab), "eq")
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

local function isValueIn(tab, required, required2)
  for _, v in ipairs(tab) do
    if (v == required or v == required2) then
      return true
    end
  end

  return false
end

---@param builder MeadowsORM.TableBuilder
---@param columnName string
local function insureColumnIsUnique(builder, columnName)
  local columnT = builder:getColumnByName(columnName)

  -- primary key automatically set unique on your column
  if (not columnT or not columnT.constraints or not isValueIn(columnT.constraints, "unique", "primary key")) then
    error("column `" .. tostring(columnName) .. "` should be unique")
  end
end

---@async
---@param params MeadowsORM.TableInterface.FindUniqueArgs
---@return table?
function TableInterface:findUnique(params)
  for column in pairs(params.where) do
    ---@diagnostic disable-next-line
    insureColumnIsUnique(self._table._builder, column)
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

---@class MeadowsORM.TableInterface.CreateArgs
---@field data table<string, MeadowsORM.InternalSafeTypes>

---@async
---@param params MeadowsORM.TableInterface.CreateArgs
---@return table?
function TableInterface:create(params)
  local builder = new(InsertBuilder, self:getTableName(), self:getPrimaryKey())
  builder:insert(params)

  return self:query(builder:build(), true)
end

---@class MeadowsORM.TableInterface.CreateManyArgs: MeadowsORM.TableInterface.CreateArgs
---@field data table<string, MeadowsORM.InternalSafeTypes>[]

---@async
---@param params MeadowsORM.TableInterface.CreateManyArgs
---@return table[]?
function TableInterface:createMany(params)
  local builder = new(InsertBuilder, self:getTableName(), self:getPrimaryKey())
  builder:insert(params)

  return self:query(builder:build(), true)
end

---@class MeadowsORM.TableInterface.UpdateArgs
---@field data table<string, MeadowsORM.InternalSafeTypes>
---@field where? MeadowsORM.TableInterface.WhereClause

---@async
---@param params MeadowsORM.TableInterface.UpdateArgs
---@return table?
function TableInterface:update(params)
  local builder = new(UpdateBuilder, self:getTableName())

  for column, value in pairs(params.data) do
    builder:set(column, value)
  end

  if (params.where) then
    applyWhere(builder, params.where)
  end

  print(builder:build())
  return self:query(builder:build(), true)
end

---@class MeadowsORM.TableInterface.DeleteArgs
---@field where MeadowsORM.TableInterface.WhereClause

---@async
---@param params MeadowsORM.TableInterface.DeleteArgs
---@return table?
function TableInterface:delete(params)
  local builder = new(DeleteBuilder, self:getTableName())

  applyWhere(builder, params.where)

  return self:query(builder:build(), true)
end