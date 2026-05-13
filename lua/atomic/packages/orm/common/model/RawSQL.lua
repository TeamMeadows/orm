---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.RawSQL: Atomic.Class
---@field private sql string
local RawSQL = package:class("RawSQL")

function RawSQL:__tostring()
  return "RawSQL [" .. tostring(self.sql) .. "]"
end

---@param sql string
function RawSQL:init(sql)
  self.sql = sql
end

function RawSQL:read()
  return self.sql
end