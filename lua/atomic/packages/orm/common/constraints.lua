---@class MeadowsORM: Atomic.Package
local package = current()
---@private
package.constraints = {}

local lshift = bit.lshift
local doflag = function(n) return lshift(1, n) end

-- flag table
-- ATTENTION: flag tables MUST be sorted in the order in which they are used in MySQL
-- e.g PRIMARY_KEY should be before AUTO_INCREMENT
package.constraints.column = {
  PRIMARY_KEY = doflag(0),
  AUTO_INCREMENT = doflag(1),
  NOT_NULL = doflag(2),
  UNIQUE = doflag(3)
}

---@private
---@type table<integer, string>
package.constraints.columnMap = {
  [package.constraints.column.AUTO_INCREMENT] = "AUTO_INCREMENT",
  [package.constraints.column.PRIMARY_KEY] = "PRIMARY KEY",
  [package.constraints.column.NOT_NULL] = "NOT NULL",
  [package.constraints.column.UNIQUE] = "UNIQUE"
}

-- column action (on update/on delete) constraints

-- flag table
---@enum MeadowsORM.TableOnAction
package.constraints.action = {
  NO_ACTION = doflag(0),
  CASCADE = doflag(1),
  RESTRICT = doflag(2),
  SET_DEFAULT = doflag(3),
  SET_NULL = doflag(4),
}

---@private
---@type table<integer, string>
package.constraints.actionMap = {
  [package.constraints.action.NO_ACTION] = "NO ACTION",
  [package.constraints.action.CASCADE] = "CASCADE",
  [package.constraints.action.RESTRICT] = "RESTRICT",
  [package.constraints.action.SET_DEFAULT] = "SET DEFAULT",
  [package.constraints.action.SET_NULL] = "SET NULL",
}

--- Returns sorted array of constraints indexes
---
---@private
---@param constraintOf "column" | "action"
---@param constraints integer
---@return integer[]?
function package.constraints:toRawArray(constraintOf, constraints)
  local flags = self[constraintOf]

  if (not flags) then
    return
  end

  local result = {}

  ---@cast flags table<string, integer>
  for _, flag in pairs(flags) do
    if (bit.band(constraints, flag) ~= flag) then
      continue
    end

    result[#result+1] = flag
  end

  return #result > 0 and table.sort(result) or result
end

--- Returns sorted array of constraints
---
---@private
---@param constraintOf "column" | "action"
---@param constraints integer
---@return string[]
function package.constraints:toArray(constraintOf, constraints)
  local flags = self:toRawArray(constraintOf, constraints)

  if (not flags) then
    return {} -- <- undebuggable
  end

  local result = {}

  for _, flag in ipairs(flags) do
    local constraint = self[constraintOf .. "Map"][flag]

    if (not constraint) then
      continue
    end

    result[#result+1] = constraint
  end

  return result
end