-- yours package
---@class YoursPackage: Atomic.Package
local package = current()

local MeadowsORM = package:getDependency("team.meadows.orm")
---@cast MeadowsORM MeadowsORM

local database = MeadowsORM:create("users")
  -- ...
  :build()

--- Example №1 - getting player from database
---@param player Player
local function loadPlayer(player)
  async(function()
    local user = database:findUnique({
      where = {
        steam_id = player:SteamID()
      }
    })

    if (not user) then
      user = database:create({
        data = {
          steam_id = player:SteamID(),
          group = "user"
        }
      })
    end

    print(user) -- "User [STEAM_ID]"
  end)
end

--- Example №2 - getting all players from database
local function loadPlayers()
  async(function()
    local users = database:findMany({})
    PrintTable(users)
  end)
end

--- Example №3 - creating new player
---@param player Player
local function createPlayer(player)
  async(function()
    local user = database:create({
      data = {
        steam_id = player:SteamID(),
        group = "user"
      }
    })
  end)
end

--- Example №4 - updating already existing player
---@param player Player
---@param group string
local function updatingPlayer(player, group)
  async(function()
    local user = database:update({
      where = {
        steam_id = player:SteamID(),
      },
      data = {
        group = group
      },
    })

    PrintTable(user)
  end)
end