---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.Table
local Table = package:getClass("Table")

--- ```lua
--- local orm = package:getDependency("team.meadows.orm")
---
--- local playersTable = orm:create("users")
---   :id()
---   :column("steamid", "text", "unique")
---   :createdAt()
---   :updatedAt()
---   :build()
---
--- player:findMany({
---   where = {
---     id = 5
---   }
--- })
--- ```
---@param tableName string
---@return MeadowsORM.Table
function package:create(tableName)
  return new(Table, tableName)
end