---@class MeadowsORM: Atomic.Package
local package = current()
package.utilities = {}

---@alias MeadowsORM.InternalSafeTypes string | number | boolean | Entity | nil

--- Escapes value
--- ```lua
--- MeadowsORM.utilities.escape(Player(1)) -- "NULL"
--- MeadowsORM.utilities.escape(true) -- "TRUE"
--- MeadowsORM.utilities.escape(false) -- "FALSE"
--- MeadowsORM.utilities.escape(5) -- "5"
--- MeadowsORM.utilities.escape("O'Reilly") -- "O\'Reilly"
--- MeadowsORM.utilities.escape("a\\b") -- "a\\\\b"
--- ```
---@param value MeadowsORM.InternalSafeTypes
---@return string
function package.utilities.escape(value)
  local type = type(value)

  if (type == "string") then
    value = value
      :gsub("\\", "\\\\")
      :gsub("'", "\\'")
      :gsub("\0", "\\0")
      :gsub("\n", "\\n")
      :gsub("\r", "\\r")
      :gsub("\b", "\\b")
      :gsub("\t", "\\t")
      :gsub("\26", "\\Z")

    return "'" .. value .. "'"
  elseif (type == "number") then
    return tostring(value)
  elseif (type == "boolean") then
    return value and "TRUE" or "FALSE"
  else
    return "NULL"
  end
end