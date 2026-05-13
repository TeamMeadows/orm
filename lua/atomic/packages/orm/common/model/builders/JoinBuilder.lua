---@class MeadowsORM: Atomic.Package
local package = current()

---@alias MeadowsORM.JoinBuilder.JoinKind "inner" | "left" | "right" | "full"

---@class MeadowsORM.JoinBuilder
---@field private _kind MeadowsORM.JoinBuilder.JoinKind
---@field private _tableName string
local JoinBuilder = package:class("JoinBuilder")

---@param kind MeadowsORM.JoinBuilder.JoinKind
function JoinBuilder:init(kind, tableName)
  self._kind = SQLStr(kind, true):upper()
  self._tableName = SQLStr(tableName, true)
end

---@return string
function JoinBuilder:build()
  local query = ("%S JOIN `%s`"):format(self._kind, self._tableName)

  return query
end