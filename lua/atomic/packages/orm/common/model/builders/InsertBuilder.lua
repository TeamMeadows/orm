---@class MeadowsORM: Atomic.Package
local package = current()

---@class MeadowsORM.InsertBuilder
---@field private _tableName string
---@field private _primaryKey string
---@field private _inserted table
---@field private _columns string[]
local InsertBuilder = package:class("InsertBuilder")

---@param tableName string
---@param primaryKey string
function InsertBuilder:init(tableName, primaryKey)
  self._tableName = tableName
  self._primaryKey = primaryKey
  self._inserted = {}
  self._columns = {}
end

---@param data table<string, any>
function InsertBuilder:insert(data)
  if (#self._columns == 0) then
    for columnName in pairs(data) do
      self._columns[#self._columns + 1] = columnName
    end
  end

  self._inserted[#self._inserted + 1] = data
end

local escape = package.utilities.escape

---@private
---@return string?
function InsertBuilder:buildColumns()
  local columns = {}

  for _, columnName in ipairs(self._columns) do
    columns[#columns + 1] = "`" .. columnName .. "`"
  end

  return table.concat(columns, ", ")
end

---@private
---@return string?
function InsertBuilder:buildValues()
  local rows = {}

  for _, row in ipairs(self._inserted) do
    local values = {}

    for _, key in ipairs(self._columns) do
      values[#values + 1] = escape(row[key])
    end

    rows[#rows + 1] = "(" .. table.concat(values, ", ") .. ")"
  end

  return table.concat(rows, ", ")
end

---@param disableReturningChangedRow? true
function InsertBuilder:build(disableReturningChangedRow)
  local columns = self:buildColumns()
  local values = self:buildValues()

  return "INSERT INTO `" .. SQLStr(self._tableName, true) .. "`"
    .. (columns and " (" .. columns .. ")" or "")
    .. (values and " VALUES " .. values or "")
    .. (not disableReturningChangedRow and ("SELECT * FROM `" .. SQLStr(self._tableName) .. "` WHERE `" .. self._primaryKey .. "`=LAST_INSERT_ID();") or "")
end