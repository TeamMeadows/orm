local groupRawTable = orm:create("groups")
  :id()
  :column("name", "text", "unique", "notnull")
  :column("title", "text", "unique", "notnull")
  :createdAt()
  :updatedAt()

local group = groupRawTable:build()

local users = orm:create("users")
  :id()
  :steamid64()
  :column("name", "text", {"unique", "notnull"})
  :column("group", "text", {"unique", "notnull"}, 0)
  -- :column("steamid", "steamid64", "unique",)
  :relation(group, "id", "group") -- relation one-to-one by Id column by default

users:findMany({
  where = {
    steamid = steamid
  },
  include = {
    group = true
  }
})