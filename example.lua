---@diagnostic disable
local group = orm:create("groups")
  :id()
  :column("name", "text", "unique", "notnull")
  :column("title", "text", "unique", "notnull")
  :createdAt()
  :updatedAt()
  :build()

local users = orm:create("users")
  :id()
  :steamid64()
  :column("name", "text", {"unique", "notnull"})
  :column("group", "text", {"unique", "notnull"}, 0)
  :relation(group, "id", "group") -- relation one-to-one by Id column by default

users:findMany({
  where = {
    steamid = steamid
  },
  include = {
    group = true
  }
})