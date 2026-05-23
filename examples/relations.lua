-- yours package
---@class YoursPackage: Atomic.Package
local package = current()

local MeadowsORM = package:getDependency("team.meadows.orm")
---@cast MeadowsORM MeadowsORM

--- importing basic constraints
local NOT_NULL = MeadowsORM.NOT_NULL
local UNIQUE = MeadowsORM.UNIQUE
local DEFAULT_JSON_ARRAY = MeadowsORM.DEFAULT_JSON_ARRAY
local SET_NULL = MeadowsORM.SET_NULL
local SET_DEFAULT = MeadowsORM.SET_DEFAULT

local RawSQL = MeadowsORM.RawSQL

local groups = MeadowsORM:create("groups")
  :id()
  :column("name", "varchar(32)", NOT_NULL + UNIQUE)
  :column("permissions", "json", NOT_NULL, DEFAULT_JSON_ARRAY)
  :column("inherits", "int", NOT_NULL)
  -- column `inherits` is related to this table's column `id`
  -- relation groups.id <-> groups.inherits
  :relation("inherits", "id", SET_NULL)
  -- and if you'll remove an group (row) from groups
  -- the relation will set to null (ON DELETE = SET NULL)
  :build()

local users = MeadowsORM:create("users")
  :id()
  :column("steam_id", "varchar(32)", NOT_NULL + UNIQUE)
  :column("group", "int", NOT_NULL, RawSQL("1")) -- default group = 1
  -- column `group` is related to groups's table column `id`
  -- relation users.group <-> groups.id
  :relation(groups, "group", "id", SET_DEFAULT)
  -- if you'll remove an group (row) from groups
  -- group of an user will set to default (ON DELETE = SET DEFAULT)
  :build()