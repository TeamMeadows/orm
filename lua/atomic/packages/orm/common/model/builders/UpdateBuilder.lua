---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.SelectBuilder
local SelectBuilder = package:getClass("SelectBuilder")

---@type MeadowsORM.WhereBuilder
local WhereBuilder = package:getClass("WhereBuilder")

---@class MeadowsORM.UpdateBuilder
---@field private _table MeadowsORM.Table
---@field private _set table
---@field private _where MeadowsORM.WhereBuilder
local UpdateBuilder = package:class("UpdateBuilder")

---@param table MeadowsORM.Table
function UpdateBuilder:init(table)
  self._table = table
  self._set = {}
  self._where = new(WhereBuilder)
end

---@param column string
---@param value any
function UpdateBuilder:set(column, value)
  self._set[column] = value
end

---@param column string
---@param value any
---@param op MeadowsORM.WhereBuilder.WhereCompareIndexes
function UpdateBuilder:where(method, column, value, op)
  self._where:insertAnd(column, value, op)
end

---@return string?
function UpdateBuilder:buildWhere()
  local where = self._whereBuilded
  if (where) then
    return where
  end

  where = self._where:build()
  self._whereBuilded = where
  return where
end

---@private
---@return string?
function UpdateBuilder:buildSet()
  local parts = {}

  for column, value in pairs(self._set) do
    parts[#parts + 1] = "`" .. column .. "`=" .. SQLStr(value)
  end

  return table.concat(parts, ", ")
end

---@param disableReturningChangedRow? true
---@return string[], integer?
function UpdateBuilder:build(disableReturningChangedRow)
  local set = self:buildSet()
  local where = self:buildWhere()

  if (not where) then
    package.logger:debug("warning: where in UpdateBuilder is empty")
  end

  local returning
  if (not disableReturningChangedRow) then
    local builder = new(SelectBuilder, self._table, self._where)
    local builded = builder:build()
    returning = builded[1]
  end

  local updateQuery = "UPDATE `" .. SQLStr(self._table:getName(), true) .. "`"
    .. " SET " .. set
    .. (where and where or "")

  return { updateQuery, returning }, returning and 2 or nil
end