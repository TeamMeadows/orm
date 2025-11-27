---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.DeleteBuilder
---@field private _tableName string
---@field private _deletableField string[]
local DeleteBuilder = package:class("DeleteBuilder")

---@param tableName string
function DeleteBuilder:init(tableName)
  self._tableName = tableName

  self._deletableField = {}
end

---@private
---@return string
function DeleteBuilder:getAffectedFields()
  local fields = #self._deletableField

  if #fields == 0 then
    return "*"
  end

  local result = ""

  for i, field in ipairs(fields) do
  end

  return result
end

function DeleteBuilder:build()
  local fields = self:getAffectedFields()

  return "DELETE FROM " .. SQLStr(self._tableName, true)
end