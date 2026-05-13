---@class MeadowsORM: Atomic.Package
local package = current()

---@type MeadowsORM.WhereBuilder
local WhereBuilder = package:getClass("WhereBuilder")

---@class MeadowsORM.DeleteBuilder
---@field private _tableName string
---@field private _where MeadowsORM.WhereBuilder
local DeleteBuilder = package:class("DeleteBuilder")

---@param tableName string
function DeleteBuilder:init(tableName)
  self._tableName = tableName
  self._where = new(WhereBuilder)
end

---@param column string
---@param value any
---@param op MeadowsORM.WhereBuilder.WhereCompareIndexes
function DeleteBuilder:where(method, column, value, op)
  self._where:insertAnd(column, value, op)
end

---@return string[], integer?
function DeleteBuilder:build()
  local where = self._where:build()

  if (not where) then
    package.logger:debug("warning: where in DeleteBuilder is empty")
  end

  local query = "DELETE FROM `" .. SQLStr(self._tableName, true) .. "`"
    .. (where and where or "")

  return { query }
end