---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.WhereBuilder
local WhereBuilder = package:getClass("WhereBuilder")

---@class MeadowsORM.UpdateBuilder
---@field private _tableName string
---@field private _set table
---@field private _where MeadowsORM.WhereBuilder
local UpdateBuilder = package:class("UpdateBuilder")

---@param tableName string
function UpdateBuilder:init(tableName)
  self._tableName = tableName
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

local escape = package.utilities.escape

---@private
---@return string?
function UpdateBuilder:buildSet()
  local parts = {}

  for column, value in pairs(self._set) do
    parts[#parts + 1] = "`" .. column .. "`=" .. escape(value)
  end

  return table.concat(parts, ", ")
end

---@param disableReturningChangedRow? true
function UpdateBuilder:build(disableReturningChangedRow)
  local set = self:buildSet()
  local where = self._where:build()

  if (not where) then
    error("where is empty")
  end

  return "UPDATE `" .. SQLStr(self._tableName, true) .. "`"
    .. " SET " .. set
    .. where
    .. (not disableReturningChangedRow and ("SELECT * FROM `" .. SQLStr(self._tableName) .. "` " .. where) or "")
end