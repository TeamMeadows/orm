---@class MeadowsORM: Atomic.Class
local package = current()

---@class MeadowsORM.WhereBuilder: Atomic.Class
---@field private _conditions { [1]: string, [2]: any, [3]: MeadowsORM.WhereBuilder.WhereCompareIndexes }[]
local WhereBuilder = package:class("WhereBuilder")

---@alias MeadowsORM.WhereBuilder.WhereCompare "=" | "<>" | ">" | "<" | ">=" | "<="
---@alias MeadowsORM.WhereBuilder.WhereCompareIndexes "eq" | "ne" | "lt" | "lte" | "gt" | "gte"
local compareIndexes = {
  eq = "=",
  ne = "<>",
  lt = "<",
  lte = "<=",
  gt = ">",
  gte = ">=",
}

function WhereBuilder:init()
  self._conditions = {}
end

---@param column string
---@param value any
---@param compare MeadowsORM.WhereBuilder.WhereCompareIndexes
function WhereBuilder:insertAnd(column, value, compare)
  self._conditions[#self._conditions+1] = { column, value, compare }
end

local escape = package.utilities.escape

---@private
---@return string?
function WhereBuilder:buildCondition()
  local result = ""

  for i, condition in ipairs(self._conditions) do
    local column = "`" .. condition[1] .. "`"
    local value = escape(condition[2])
    local compareSign = compareIndexes[condition[3]] or "="

    result = result .. (i > 1 and " AND " or "") .. column .. compareSign .. value
  end

  return #result ~= 0 and result or nil
end

---@return string?
function WhereBuilder:build()
  local condition = self:buildCondition()

  return condition and ("WHERE " .. condition) or nil
end