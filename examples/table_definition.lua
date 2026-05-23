-- yours package
---@class YoursPackage: Atomic.Package
local package = current()

-- importing MeadowsORM as an dependency of yours package
local MeadowsORM = package:getDependency("team.meadows.orm")
---@cast MeadowsORM MeadowsORM

--- importing basic constraints
local NOT_NULL = MeadowsORM.NOT_NULL

local RawSQL = MeadowsORM.RawSQL

-- creating (defining) an database table
local database = MeadowsORM:create("users")
  :id() -- add `id` column
  :column("name", "tinytext", NOT_NULL)
  :column("status", "tinytext", NOT_NULL)
  :column("some_new_column", "varchar(32)", NOT_NULL, RawSQL("default_value"))
  :createdAt() -- add `created_at` column
  :updatedAt() -- add `updated_at` column. it will automatically updated when you will update row in database
  :build() -- required! do not forget to call this method

-- build method transforms object from table definition (class Table),
-- to new object that you will use to making sql queries (class TableInterface).