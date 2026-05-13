---@class MeadowsORM: Atomic.Package
local package = current()

---@alias MeadowsORM.InternalSafeTypes string | number | boolean | Atomic.Time.NaiveDateTime | table

local Atomic = package:getDependency("atomic")
---@cast Atomic InternalAtomic

if (Atomic:getConfiguration():get("mysqlMultistatements") == false) then
	package.logger:warn("the `mysqlMultistatements` parameter of `atomic` package is set to `false`, which means that some queries may not be processed by the database.")
end

---@type MeadowsORM.Table
local Table = package:getClass("Table")

--- ```lua
--- local MeadowsORM = package:getDependency("team.meadows.orm")
--- ---@cast MeadowsORM MeadowsORM
---
--- local playersTable = MeadowsORM:create("users")
---   :id()
---   :column("steamid", "text", "unique")
---   :createdAt()
---   :updatedAt()
---   :build()
---
--- playersTable:findMany({
---   where = {
---     -- WHERE id < 9 AND id > 2
---     id = {
---       -- Where Id less than (<) 9
---       lt = 9,
---       -- And Where Id greater than (>) 2
---       gt = 2
---     }
---   }
--- })
--- ```
---@param tableName string
---@return MeadowsORM.Table
function package:create(tableName)
  return new(Table, tableName)
end

-- all available constraints

-- column constraints
package.AUTO_INCREMENT = package.constraints.column.AUTO_INCREMENT
package.PRIMARY_KEY = package.constraints.column.PRIMARY_KEY
package.NOT_NULL = package.constraints.column.NOT_NULL
package.UNIQUE = package.constraints.column.UNIQUE

--- column (on update/on delete) action constraints
package.NO_ACTION = package.constraints.action.NO_ACTION
package.CASCADE = package.constraints.action.CASCADE
package.RESTRICT = package.constraints.action.RESTRICT
package.SET_DEFAULT = package.constraints.action.SET_DEFAULT
package.SET_NULL = package.constraints.action.SET_NULL