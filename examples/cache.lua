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
  :index("steam_id", false, true) -- index also being used for fast search in cache (O(1))
  :cache() -- applying cache (TableCache class)
  :build()

--- Example №1 - find query
local function loadUser(player)
  local user = database:findUnique({
    where = {
      steam_id = player:SteamID()
    },
    cache = true -- inserting found row in cache = true
  })

  if (not user) then
    user = database:create({
      data = {
        steam_id = player:SteamID()
      },
      cache = true -- insering new created row in cache = true
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