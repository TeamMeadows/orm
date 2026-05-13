---@class MeadowsORM: Atomic.Package
local package = current()

---@param timestamp string
---@return Atomic.Time.NaiveDateTime?
local function timestampToNaive(timestamp)
  if (not timestamp) then
    return
  end

  local iso = timestamp:gsub(" ", "T")
  return atomic.time.naiveDateTime.fromIso8601(iso)
end

---@param naive Atomic.Time.NaiveDateTime
---@return string?
local function naiveToTimestamp(naive)
  if (not naive) then
    return
  end

  local iso = naive:getIso8601()
  return select(1, iso:gsub("T", " "))
end

package.types = package.types or {
  ---@private
  ---@type table<string, { serialize: function, deserialize: function }>
  _convertors = {
    timestamp = { serialize = timestampToNaive, deserialize = naiveToTimestamp },
    ---@diagnostic disable-next-line
    bool = { serialize = tobool, deserialize = function(b) return b and "TRUE" or "FALSE" end},
    ---@diagnostic disable-next-line
    json = { serialize = util.JSONToTable, deserialize = util.TableToJSON }
  }
}

---@param convertKind "serialize" | "deserialize"
---@param value any
---@param type string
function package.types:convert(convertKind, value, type)
  local typeConvertorTable = self._convertors[type]

  if (not typeConvertorTable) then
    return convertKind == "serialize" and value or SQLStr(value, true)
  end

  local convertor = typeConvertorTable[convertKind]

  return convertor(value)
end

---@param value any
---@param type string
function package.types:convertFromDatabase(value, type)
  return self:convert("serialize", value, type)
end

---@param value any
---@param type string
function package.types:convertToDatabase(value, type)
  return self:convert("deserialize", value, type)
end