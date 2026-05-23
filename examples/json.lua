-- yours package
---@class YoursPackage: Atomic.Package
local package = current()

local MeadowsORM = package:getDependency("team.meadows.orm")
---@cast MeadowsORM MeadowsORM

local NOT_NULL = MeadowsORM.NOT_NULL
local UNIQUE = MeadowsORM.UNIQUE
local DEFAULT_JSON_ARRAY = MeadowsORM.DEFAULT_JSON_ARRAY

-- creating (defining) an database table
local database = MeadowsORM:create("groups")
  :id() -- add `id` column
  :column("name", "varchar(16)", NOT_NULL + UNIQUE)
  :column("permissions", "json", NOT_NULL, DEFAULT_JSON_ARRAY) -- default = [] (empty array)
  :build() -- required! do not forget to call this method

---@param name string
local function loadGroup(name)
  async(function()
    local group = database:findUnique({
      where = {
        name = name
      }
    })

    if (not group) then
      return
    end

    print(#group.permissions) -- length of `permissions` column's array
  end)
end

loadGroup("admin")