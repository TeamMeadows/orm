-- Entity is a basic class, that implements logic to automatically update

---@class YoursPackage: Atomic.Package
local package = current()

local MeadowsORM = package:getDependency("team.meadows.orm")
---@cast MeadowsORM MeadowsORM

local NOT_NULL = MeadowsORM.NOT_NULL
local UNIQUE = MeadowsORM.UNIQUE
local RawSQL = MeadowsORM.RawSQL

local database = MeadowsORM:create("users")
  :id()
  :column("steam_id", "varchar(32)", NOT_NULL + UNIQUE)
  :column("money", "int", NOT_NULL, RawSQL("0"))
  :index("steam_id", false, true) -- false, true => cache index only, needed to O(1) object in cache find
  :cache()
  :build()

-- creating entity
-- first argument is yours package
-- second is a class name
---@class YoursPackage.User: MeadowsORM.Entity
---@field private id integer
---@field private steam_id string
---@field private money integer
---@field getId fun(self: self): integer
---@field setId fun(self: self, id: integer)
---@field getSteamId fun(self: self): string
---@field setSteamId fun(self: self, steamId: string)
---@field getMoney fun(self: self): integer
---@field setMoney fun(self: self, money: integer)
local User = database:entity(package, "User")

-- the methods as `getId`, `setMoney` will be automatically created by MeadowsORM
-- so you only need to describe it via LuaLS annotations (only if you use LuaLS)

---@param raw table Raw row (table) directly from the database
function User:init(raw)
  -- Required!
  -- It will setup your fields
  self:super(raw) -- Required!!!
end

function User:addMoney(money)
  -- it will automatically update the value in database
  self:setMoney(self:getMoney() + money)

  -- if you don't wanna update it automatically
  -- you can just change the field by yourself
  self.money = self:getMoney() + money
end

-- also you able to get your entity through `package.getClass` method
---@type YoursPackage.User
local UserClass = package:getClass("User")

--- Example №1 - find query
local function loadUser(player)
  local user = database:findUnique({
    where = {
      steam_id = player:SteamID()
    },
    cache = true
  })

  if (not user) then
    user = database:create({
      data = {
        steam_id = player:SteamID()
      },
      cache = true
    })
  end
end

---@param player Player
---@return YoursPackage.User?
local function getUser(player)
  local cache = database:getCache()
  -- O(1) user get
  return cache:findIndexed("steam_id", player:SteamID())
end

---@param money integer
---@param operation? MeadowsORM.WhereBuilder.WhereCompareIndexes
local function getUsersWithMoney(money, operation)
  local cache = database:getCache()
  -- O(n) users get
  return cache:find("money", money, operation or "eq")
end

local user = getUser(Player(1))
print(user and user:getMoney())

-- find users with money=1000
getUsersWithMoney(1000)

-- find users with money>1000
getUsersWithMoney(1000, "gt") -- gt = greater than

-- find users with money>=1000
getUsersWithMoney(1000, "gte") -- gte = greater than and equals

-- find users with money<1000
getUsersWithMoney(1000, "lt") -- lt = less than

-- find users with money<=1000
getUsersWithMoney(1000, "lte") -- lte = less than and equals