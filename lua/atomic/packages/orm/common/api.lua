---@class MeadowsORM: Atomic.Package
local package = current()

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