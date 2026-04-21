---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.TableCache: Atomic.Class
---@field private _storage table
local TableCache = package:class("TableCache")

function TableCache:init()
  self._storage = {}
end