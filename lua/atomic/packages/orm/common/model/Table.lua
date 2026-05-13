---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.RawSQL
local RawSQL = package:getClass("RawSQL")

package.CURRENT_TIMESTAMP = new(RawSQL, "CURRENT_TIMESTAMP")

---@type MeadowsORM.TableBuilder
local TableBuilder = package:getClass("TableBuilder")

local constraints = package.constraints.column
local AUTO_INCREMENT = constraints.AUTO_INCREMENT
local NOT_NULL = constraints.NOT_NULL
local PRIMARY_KEY = constraints.PRIMARY_KEY
local UNIQUE = constraints.UNIQUE

---@type MeadowsORM.TableInterface
local TableInterface = package:getClass("TableInterface")

---@alias MeadowsORM.Table.Type "char" | "tinytext" | "text" | "mediumtext" | "tinyint" | "smallint" | "mediumint" | "int" | "bigint" | "float" | "double" | "bool" | "json" | "date" | "time" | "datetime" | "timestamp"

--- Class that implements structure of a MySQL's Table.
---
--- Internally used in [`TableInterface`](./TableInterface.lua)
---@class MeadowsORM.Table
---@field protected _class? Atomic.Class
---@field protected _cache boolean
---@field protected _builder MeadowsORM.TableBuilder
local Table = package:class("Table")

---@param tableName string
function Table:init(tableName)
  self._builder = new(TableBuilder, tableName)
  self._cache = false
end

---@return string
function Table:getName()
  ---@diagnostic disable-next-line
  return self._builder._tableName
end

---@return string
function Table:getPrimaryKey()
  return self._builder:getPrimaryKey()
end

---@return MeadowsORM.TableBuilder.Column[]
function Table:getColumns()
  return self._builder:getColumns()
end

---@param columnName string
---@return MeadowsORM.TableBuilder.Column?
function Table:getColumn(columnName)
  return self._builder:getColumnByName(columnName)
end

---@param columnName string
---@param requiredConstraint integer
function Table:isColumnHasConstraint(columnName, requiredConstraint)
  return self._builder:isColumnHasConstraint(columnName, requiredConstraint)
end

---@return Atomic.Class?
function Table:getDeserializationClass()
  return self._class
end

---@param name string
---@param type MeadowsORM.Table.Type | string
---@param columnConstraints? integer
---@param default? string | MeadowsORM.RawSQL
---@param onUpdate? string | MeadowsORM.RawSQL
---@return self
function Table:column(name, type, columnConstraints, default, onUpdate)
  self._builder:column(name, type, columnConstraints, default, onUpdate)

  return self
end

--- Creates a [one-to-one relationship](https://en.wikipedia.org/wiki/One-to-one_(data_model)) between two tables
---@param table MeadowsORM.Table | MeadowsORM.TableInterface | string
---@param internalColumn string
---@param currentColumn? string | integer
---@param onDelete? integer
---@return self
function Table:relation(table, internalColumn, currentColumn, onDelete)
  local isSelf = type(table) == "string"

  ---@diagnostic disable-next-line invisible
  local builder = not isSelf and (table._builder or table._table and table._table._builder)
  ---@diagnostic disable-next-line
  self._builder:relation(isSelf and self._builder or builder, isSelf and table or internalColumn, isSelf and internalColumn or currentColumn, isSelf and currentColumn or onDelete)

  return self
end

--- Adds a column `id`
---@return self
function Table:id()
  return self:column("id", "int", AUTO_INCREMENT + PRIMARY_KEY)
end

--- Adds a column `updated_at`, which will be automatically created with the current date when a new record is added.
--- ```lua
--- local usersTable = orm:create("users")
---   :createdAt()
--- ```
---@return self
function Table:createdAt()
  return self:column("created_at", "timestamp", NOT_NULL, package.CURRENT_TIMESTAMP)
end

--- Adds a column `updated_at`, which will be automatically updated with every write.
--- ```lua
--- local usersTable = orm:create("users")
---   :updatedAt()
--- ```
---@return self
function Table:updatedAt()
  return self:column("updated_at", "timestamp", NOT_NULL, package.CURRENT_TIMESTAMP, package.CURRENT_TIMESTAMP)
end

---@param class Atomic.Class
---@return self
function Table:deserializationClass(class)
  self._class = class
  return self
end

---@return self
function Table:cache()
  if (not self._builder:getPrimaryKey()) then
    error("caching only works with tables that have an primary key column")
  end

  self._cache = true

  return self
end

---@return MeadowsORM.TableInterface
function Table:build()
  local sql = self._builder:build()

  package.logger:trace(sql)

  async(function()
    local _, err = atomic.mysql.query(sql)

    if (err) then
      package.logger:err("unable to create table `%s`: %s", self:getName(), err)
    end
  end)

  return new(TableInterface, self)
end