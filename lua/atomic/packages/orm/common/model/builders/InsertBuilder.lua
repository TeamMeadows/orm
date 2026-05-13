---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.SelectBuilder
local SelectBuilder = package:getClass("SelectBuilder")

---@class MeadowsORM.InsertBuilder
---@field private _table MeadowsORM.Table
---@field private _inserted table
---@field private _columns string[]
local InsertBuilder = package:class("InsertBuilder")

---@param table MeadowsORM.Table
function InsertBuilder:init(table)
  self._table = table
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
      values[#values + 1] = SQLStr(row[key])
    end

    rows[#rows + 1] = "(" .. table.concat(values, ", ") .. ")"
  end

  return table.concat(rows, ", ")
end

---@param disableReturningChangedRow? true
---@return string[], integer?
function InsertBuilder:build(disableReturningChangedRow)
  local columns = self:buildColumns()
  local values = self:buildValues()

  local returning
  if (not disableReturningChangedRow) then
    local builder = new(SelectBuilder, self._table)
    builder:where("and", self._table:getPrimaryKey(), "LAST_INSERT_ID", "eq", true)

    local builded = builder:build()

    returning = builded[1]
  end

  local insertQuery = "INSERT INTO `" .. SQLStr(self._table:getName(), true) .. "`"
    .. (columns and " (" .. columns .. ")" or "")
    .. (values and " VALUES " .. values or "")

  return { insertQuery, returning }, returning and 2 or nil
end