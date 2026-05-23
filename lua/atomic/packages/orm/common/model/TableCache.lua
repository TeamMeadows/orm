---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.TableCache<T>: Atomic.Class
---@field private _table MeadowsORM.Table
---@field private _primaryKey string
---@field private _storage table<string, table<(integer | string), (Atomic.Class | table)>>
---@field private _storageLength integer
---@field private _indexes string[]
local TableCache = package:class("TableCache")

---@param table MeadowsORM.Table
function TableCache:init(table)
  self._table = table
  self._primaryKey = self:getPrimaryKey()

  self._storage = {}
  self._storage[self._primaryKey] = {}
  self._storageLength = 0

  self._indexes = {}
end

---@private
---@return string
function TableCache:getPrimaryKey()
  return self._table:getPrimaryKey()
end

---@param indexes string[]
function TableCache:useIndexes(indexes)
  ---@diagnostic disable-next-line
  local builder = self._table._builder
  for _, column in ipairs(indexes) do
    -- if not this check
    -- the objects in cache will rewrite themself, so
    -- basically all the indexes should be unique
    if (not builder:isColumnHasConstraint(column, package.UNIQUE) and not builder:isColumnHasConstraint(column, package.PRIMARY_KEY)) then
      error("unable to create cache index: column " .. tostring(column) .. " should be unique!")
    end

    self._storage[column] = {}
  end

  self._indexes = indexes
end

--- Returns an object in cache by primary key
---@generic T
---@param primaryKeyValue integer | string
---@return T?
function TableCache:get(primaryKeyValue)
  return self._storage[self._primaryKey][primaryKeyValue]
end

---@type table<MeadowsORM.WhereBuilder.WhereCompareIndexes, fun(value1: any, value2: any): boolean>
local compareFuncs = {
  eq = function(value1, value2) return value1 == value2 end,
  ne = function(value1, value2) return value1 ~= value2 end,
  lt = function(value1, value2) return value1 < value2 end,
  lte = function(value1, value2) return value1 <= value2 end,
  gt = function(value1, value2) return value1 > value2 end,
  gte = function(value1, value2) return value1 >= value2 end,
}

---@generic T
---@param value T
---@param valueToBe T
---@param compareOperation? MeadowsORM.WhereBuilder.WhereCompareIndexes @default=eq (equals)
---@return boolean
local function compare(value, valueToBe, compareOperation)
  local cmp = compareFuncs[compareOperation or "eq"]

  if (not cmp) then
    return false
  end

  return cmp(value, valueToBe)
end

--- Returns array of a objects
---@generic T
---@param self MeadowsORM.TableCache<T>
---@param column string
---@param value MeadowsORM.InternalSafeTypes
---@param operation? MeadowsORM.WhereBuilder.WhereCompareIndexes @default=eq (equals)
---@return (T)[]
function TableCache:find(column, value, operation)
  local result = {}

  if (self._storage[column] and (not operation or operation == "eq")) then
    return { self._storage[column][value] }
  end

  for _, object in pairs(self._storage[self._primaryKey]) do
    if (not compare(object[column], value, operation)) then
      continue
    end

    result[#result+1] = object
  end

  return result
end

---@generic T
---@param column string
---@param value MeadowsORM.InternalSafeTypes
---@return T?
function TableCache:findIndexed(column, value)
  local indexed = self._storage[column]
  return indexed and indexed[value]
end

--- Returns the number of objects stored in the cache
---@return integer
function TableCache:length()
  return self._storageLength
end

---@private
---@generic T
---@param column string
---@param object T
function TableCache:addInternal(column, object)
  self._storage[column][object[column]] = object
end

---@private
---@generic T
---@param column string
---@param columnValue integer | string
---@return T
function TableCache:deleteInternal(column, columnValue)
  local object = self._storage[column][columnValue]
  self._storage[column][columnValue] = nil
  return object
end

--- Adds object to cache
---
--- Overrides object if it already in cache
---@generic T
---@param self MeadowsORM.TableCache<T>
---@param object T
function TableCache:add(object)
  self:addInternal(self._primaryKey, object)

  if (#self._indexes > 0) then
    for _, index in ipairs(self._indexes) do
      self:addInternal(index, object)
    end
  end

  self._storageLength = self._storageLength + 1
end

--- Deletes an object from cache by primary key
---@param primaryKeyValue integer | string
function TableCache:delete(primaryKeyValue)
  local object = self:deleteInternal(self._primaryKey, primaryKeyValue)

  if (object and #self._indexes > 0) then
    for _, index in ipairs(self._indexes) do
      self:deleteInternal(index, object[index])
    end
  end

  self._storageLength = self._storageLength - 1
end

---@generic T
---@param column string
---@param value MeadowsORM.InternalSafeTypes
---@param operation? MeadowsORM.WhereBuilder.WhereCompareIndexes @default=eq (equals)
---@return integer Count of the objects that have been deleted
function TableCache:findAndDelete(column, value, operation)
  local primary = self._primaryKey
  local objects = self:find(column, value, operation)

  if (not objects) then
    return 0
  end

  for _, object in ipairs(objects) do
    self:delete(object[primary])
  end

  return #objects
end

function TableCache:iter()
  return pairs(self._storage[self._primaryKey])
end