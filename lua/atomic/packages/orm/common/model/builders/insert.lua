---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.InsertBuilder
---@field private _tableName string
---@field private _insertableField string[]
local InsertBuilder = package:class("InsertBuilder")

---@param tableName string
function InsertBuilder:init(tableName)
  self._tableName = tableName

  self._insertableField = {}
end

---@private
---@return string
function InsertBuilder:getAffectedFields()
  local fields = #self._insertableField

  if #fields == 0 then
    return "*"
  end

  local result = ""

  for i, field in ipairs(fields) do
  end

  return result
end

function InsertBuilder:build()
  local fields = self:getAffectedFields()

  return "INSERT INTO " .. SQLStr(self._tableName, true)
end