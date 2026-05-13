---@class Example: Atomic.Package
local package = current()

local MeadowsORM = package:getDependency("team.meadows.orm")
---@cast MeadowsORM MeadowsORM

--- this is bitflags
--- you can summary them to combine
local UNIQUE = MeadowsORM.UNIQUE
local NOT_NULL = MeadowsORM.NOT_NULL

--- 1. Describing table structure

local group = MeadowsORM:create("groups")
  :id() -- add `id` column with auto increment
  :column("name", "text", UNIQUE + NOT_NULL)
  :column("title", "text", UNIQUE + NOT_NULL)
  :createdAt() -- add `created_at` column, that will be automatically insert current timestamp when you create new row in database
  :updatedAt() -- add `updated_at` column, that will be automatically updated when you update something in a database row
  :build() -- needed to create TableInterface (class that would be provide methods to interact with this table in database)
  -- also, `build` method is creating an `CREATE TABLE` SQL query and automatically sends it to the database
  -- so its basically creates an table in database in runtime

local users = MeadowsORM:create("users")
  :id()
  :column("name", "text", UNIQUE + NOT_NULL)
  :column("group", "text", UNIQUE + NOT_NULL, "0")
  :relation(group, "id", "group") -- relation one-to-one by Id column by default
  :build()

--- 2. Creating Entity (class)

-- it is optional
--
-- sets the deserialisation class for the table
-- this means that when raw data from the database is received by MeadowsORM, it will convert it into this class (deserialise it)

---@class Example.Group: MeadowsORM.Entity
---@field private id integer
---@field private name string
---@field private title string
---@field private created_at Atomic.Time.NaiveDateTime
---@field private updated_at Atomic.Time.NaiveDateTime
local Group = group:entity(package, "Group")

---@param raw table Raw row from a database
function Group:init(raw)
  -- REQUIRED! + should be on EXACTLY first line of your constructor method!
  super(self, raw) -- this line call `MeadowsORM.Entity.init` method, providing `raw` to it as an argument
  -- why? `MeadowsORM.Entity.init` method setting fields up
end

-- you can create new methods here
-- to use it later

--- 3. Intecation with database

-- your query should be in coroutine!
-- (you can put it in coroutine using `async` function that defined by Atomic Framework)
-- as in this example

async(function()
  -- Object of a class Group (that we define at line 39)
  local userWithId2 = users:findUnique({
    where = { -- selecting user with id == 2
      id = 2
    }
  })

  if (userWithId2) then
    assert(userWithId2.group == "user")
  else
    print("user with id = 2 not found")
  end

  -- selecting users with id that LESS THAN (lt) 4

  -- Array of objects of a class Group
  local users = users:findMany({
    where = {
      id = {
        lt = "4"
      }
    }
  })

  assert(#users < 4)
end)