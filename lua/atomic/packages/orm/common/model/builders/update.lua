---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.UpdateBuilder
---@field private _tableName string
---@field private _updatableField string[]
local UpdateBuilder = package:class("UpdateBuilder")

---@param tableName string
function UpdateBuilder:init(tableName)
  self._tableName = tableName

  self._updatableField = {}
end

---@private
---@return string
function UpdateBuilder:getAffectedFields()
  local fields = #self._updatableField

  if #fields == 0 then
    return "*"
  end

  local result = ""

  for i, field in ipairs(fields) do
  end

  return result
end

function UpdateBuilder:build()
  local fields = self:getAffectedFields()

  return "UPDATE " .. SQLStr(self._tableName, true)
end