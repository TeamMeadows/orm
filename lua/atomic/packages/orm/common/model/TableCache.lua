---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.TableCache<T>: Atomic.Class
---@field private _storage table<(integer | string), (Atomic.Class | table)>
---@field private _storageLength integer
local TableCache = package:class("TableCache")

---@param table MeadowsORM.Table
function TableCache:init(table)
  self._table = table
  self._storage = {}
  self._storageLength = 0
end

---@private
function TableCache:getPrimaryKey()
  return self._table:getPrimaryKey()
end

--- Returns an object in cache by primary key
---@generic T: table | Atomic.Class
---@param primaryKeyValue integer | string
---@return (T)?
function TableCache:get(primaryKeyValue)
  return self._storage[primaryKeyValue]
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
---@generic T: table | Atomic.Class
---@param self MeadowsORM.TableCache<T>
---@param column string
---@param value MeadowsORM.InternalSafeTypes
---@param operation? MeadowsORM.WhereBuilder.WhereCompareIndexes @default=eq (equals)
---@return (T)[]
function TableCache:find(column, value, operation)
  local result = {}

  for _, object in pairs(self._storage) do
    if (not compare(object[column], value, operation)) then
      continue
    end

    result[#result+1] = object
  end

  return result
end

--- Returns the number of objects stored in the cache
---@return integer
function TableCache:length()
  return self._storageLength
end

--- Adds object to cache
---
--- Overrides object if it already in cache
---@generic T: table | Atomic.Class
---@param self MeadowsORM.TableCache<T>
---@param object T
function TableCache:add(object)
  local primary = self:getPrimaryKey()
  self._storage[object[primary]] = object
  self._storageLength = self._storageLength + 1
end

--- Deletes an object from cache by primary key
---@param primaryKeyValue integer
function TableCache:clear(primaryKeyValue)
  self._storage[primaryKeyValue] = nil
  self._storageLength = self._storageLength - 1
end

---@generic T: table | Atomic.Class
---@param self MeadowsORM.TableCache<T>
---@param column string
---@param value MeadowsORM.InternalSafeTypes
---@param operation? MeadowsORM.WhereBuilder.WhereCompareIndexes @default=eq (equals)
---@return integer Count of the objects that have been deleted
function TableCache:findAndClean(column, value, operation)
  local primary = self:getPrimaryKey()
  local objects = self:find(column, value, operation)

  for _, object in ipairs(objects) do
    self:clear(object[primary])
  end

  return #objects
end

function TableCache:iter()
  return pairs(self._storage)
end