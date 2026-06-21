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
    timestamp = { serialize = naiveToTimestamp, deserialize = timestampToNaive },
    ---@diagnostic disable-next-line
    bool = { serialize = function(b) return b and "TRUE" or "FALSE" end, deserialize = tobool },
    ---@diagnostic disable-next-line
    json = { serialize = util.TableToJSON, deserialize = util.JSONToTable }
  }
}

package.types._convertors["boolean"] = package.types._convertors["bool"]

---@param convertKind "serialize" | "deserialize"
---@param value any
---@param type string
---@param isNotNullable? boolean
---@return MeadowsORM.InternalSafeTypes
function package.types:convert(convertKind, value, type, isNotNullable)
  if (not value and not isNotNullable) then
    return convertKind == "serialize" and NULL or nil
  end

  local typeConvertorTable = self._convertors[type]

  if (not typeConvertorTable) then
    return convertKind == "deserialize" and value or SQLStr(value, true)
  end

  local convertor = typeConvertorTable[convertKind]

  return value ~= nil and convertor(value) or nil
end

---@param value any
---@param type string
---@param isNotNullable? boolean
function package.types:convertFromDatabase(value, type, isNotNullable)
  return self:convert("deserialize", value, type, isNotNullable)
end

---@param value any
---@param type string
---@param isNotNullable? boolean
function package.types:convertToDatabase(value, type, isNotNullable)
  return self:convert("serialize", value, type, isNotNullable)
end