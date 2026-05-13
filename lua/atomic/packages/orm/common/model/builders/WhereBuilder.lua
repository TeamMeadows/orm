---@class MeadowsORM: Atomic.Class
local package = current()

---@class MeadowsORM.WhereBuilder: Atomic.Class
---@field private _conditions { [1]: string, [2]: any, [3]: MeadowsORM.WhereBuilder.WhereCompareIndexes, [4]: boolean }[]
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
---@param isFunction? boolean @default = false
function WhereBuilder:insertAnd(column, value, compare, isFunction)
  self._conditions[#self._conditions+1] = { column, value, compare, isFunction or false }
end

---@private
---@return string?
function WhereBuilder:buildCondition()
  local result = ""

  for i, condition in ipairs(self._conditions) do
    local column = "`" .. condition[1] .. "`"
    local isFunction = condition[4]
    local value = condition[2]
    value = isFunction and value .. "()" or SQLStr(value)
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