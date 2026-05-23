---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.Entity
local Entity = package:getClass("Entity")

---@type MeadowsORM.TableCache
local TableCache = package:getClass("TableCache")

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
---@field private _cache? MeadowsORM.TableCache
local TableInterface = package:class("TableInterface")

---@param table MeadowsORM.Table
function TableInterface:init(table)
  self._table = table

  ---@diagnostic disable-next-line invisible
  self._primaryKey = self._table._builder:getPrimaryKey()

  ---@diagnostic disable-next-line invisible
  if (self._table._cache) then
    self._cache = new(TableCache, self._table)

    local indexes = self._table:getIndexes()

    if (indexes and #indexes > 0) then
      self._cache:useIndexes(indexes)
    end
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

---@param columnName string
---@return MeadowsORM.TableBuilder.Column?
function TableInterface:getColumn(columnName)
  return self._table:getColumn(columnName)
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
    ---@diagnostic disable-next-line xd
    newEntity:accessor(column.name, snakeCaseToPascalCase(column.name))
  end

  return newEntity
end

---@private
---@async
---@param queries string[]
---@param resultRowIndex? integer @default = 1
---@param shouldReturn boolean Should SQL query return data?
---@param shouldCache? boolean @default = false
---@param joins? {}[] -- todo
---@return (Atomic.Class | table)[]
function TableInterface:query(queries, resultRowIndex, shouldReturn, shouldCache, joins)
  local data, err = package.database.transaction(queries, resultRowIndex)

  if (err) then
    package.logger:err("an error occurred while performing the query: %s", err)
    return {}
  end

  if (shouldReturn) then
    local results = self:normalizeResults(data, joins)

    if (results and #results > 0 and shouldCache and self._cache) then
      local cache = self:getCache()

      for _, object in ipairs(results) do
        cache:add(object)
      end
    end

    return results
  end

  return {}
end

---@private
---@generic T
---@param rows (string | number)[][]
---@param joins? table
---@return (Atomic.Class | table)
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
  --    todo raw rows might be != columns
  for i, row in ipairs(rows) do
    local object = {}

    ---@diagnostic disable-next-line invisible
    for columnId, column in ipairs(self._table._builder._columns) do
      -- if we SELECT column№3, column№4, columnId goes fuck down
      object[column.name] = package.types:convertFromDatabase(row[columnId], column.type)
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

  return casted
end

---@generic T
---@return MeadowsORM.TableCache<T>
function TableInterface:getCache()
  return self._cache
end

---@alias MeadowsORM.TableInterface.WhereClause table<string, string | number | boolean | table<MeadowsORM.WhereBuilder.WhereCompareIndexes, (string | number | boolean)>>

---@class MeadowsORM.TableInterface.MethodBase
---@field cache? boolean @default = false
---@field returning? boolean @default = true

---@class MeadowsORM.TableInterface.FindUniqueArgs: MeadowsORM.TableInterface.MethodBase
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

---@param builder MeadowsORM.TableBuilder
---@param columnName string
local function insureColumnIsUnique(builder, columnName)
  -- primary key automatically set unique on your column
  if (not builder:isColumnHasConstraint(columnName, package.UNIQUE) and not builder:isColumnHasConstraint(columnName, package.PRIMARY_KEY)) then
    error("column `" .. tostring(columnName) .. "` should be unique")
  end
end

---@async
---@generic T
---@param params MeadowsORM.TableInterface.FindUniqueArgs
---@return T?
function TableInterface:findUnique(params)
  for column in pairs(params.where) do
    ---@diagnostic disable-next-line
    insureColumnIsUnique(self._table._builder, column)
  end

  local builder = new(SelectBuilder, self._table)
  builder:limit(1)

  applySelectParams(builder, params)

  local queries, rowIndex = builder:build()

  local rows = self:query(queries, rowIndex, params.returning ~= false, params.cache)
  return type(rows) == "table" and rows[1] or nil
end

---@class MeadowsORM.TableInterface.FindFirstArgs: MeadowsORM.TableInterface.FindUniqueArgs
---@field where? MeadowsORM.TableInterface.WhereClause
---@field orderBy? table<string, "asc" | "desc">

---@async
---@generic T
---@param params MeadowsORM.TableInterface.FindFirstArgs
---@return T
function TableInterface:findFirst(params)
  local builder = new(SelectBuilder, self._table)
  builder:limit(1)

  applySelectParams(builder, params)

  local queries, rowIndex = builder:build()

  local rows = self:query(queries, rowIndex, params.returning ~= false, params.cache)
  return type(rows) == "table" and rows[1] or nil
end

---@async
---@generic T
---@param params? MeadowsORM.TableInterface.FindFirstArgs
---@return T[]
function TableInterface:findMany(params)
  local builder = new(SelectBuilder, self._table)

  if (params) then
    applySelectParams(builder, params)
  end

  local queries, rowIndex = builder:build()

  return self:query(queries, rowIndex, not params or params.returning ~= false, params and params.cache or nil)
end

---@class MeadowsORM.TableInterface.CreateArgs: MeadowsORM.TableInterface.MethodBase
---@field data table<string, MeadowsORM.InternalSafeTypes>

---@async
---@generic T
---@param params MeadowsORM.TableInterface.CreateArgs
---@return T
function TableInterface:create(params)
  local builder = new(InsertBuilder, self._table)
  builder:insert(params.data)

  local queries, rowIndex = builder:build()

  return self:query(queries, rowIndex, params.returning ~= false, params.cache)[1]
end

---@class MeadowsORM.TableInterface.CreateManyArgs: MeadowsORM.TableInterface.CreateArgs
---@field data table<string, MeadowsORM.InternalSafeTypes>[]

---@async
---@generic T
---@param params MeadowsORM.TableInterface.CreateManyArgs
---@return T[]
function TableInterface:createMany(params)
  local builder = new(InsertBuilder, self._table)
  builder:insert(params)

  local queries, rowIndex = builder:build()

  return self:query(queries, rowIndex, params.returning ~= false, params.cache)
end

---@class MeadowsORM.TableInterface.UpdateArgs: MeadowsORM.TableInterface.MethodBase
---@field data table<string, MeadowsORM.InternalSafeTypes>
---@field where MeadowsORM.TableInterface.WhereClause

---@async
---@generic T
---@param params MeadowsORM.TableInterface.UpdateArgs
---@return T @Updated row
function TableInterface:update(params)
  local builder = new(UpdateBuilder, self._table)

  if (not params.where) then
    error("where is not set")
  end

  for column in pairs(params.where) do
    ---@diagnostic disable-next-line
    insureColumnIsUnique(self._table._builder, column)
  end

  for column, value in pairs(params.data) do
    builder:set(column, value)
  end

  if (params.where) then
    applyWhere(builder, params.where)
  end

  local queries, rowIndex = builder:build()

  return self:query(queries, rowIndex, params.returning ~= false, params.cache)
end

---@class MeadowsORM.TableInterface.DeleteArgs: MeadowsORM.TableInterface.MethodBase
---@field where MeadowsORM.TableInterface.WhereClause

---@async
---@generic T
---@param params MeadowsORM.TableInterface.DeleteArgs
---@return T
function TableInterface:delete(params)
  local builder = new(DeleteBuilder, self:getTableName())

  applyWhere(builder, params.where)

  local queries, rowIndex = builder:build()

  return self:query(queries, rowIndex, params.returning ~= false, params.cache)
end