---@class MeadowsORM: Atomic.Package
local package = current()

---@alias MeadowsORM.SelectBuilder.WhereCompare "=" | ">" | "<" | ">=" | "<="
---@alias MeadowsORM.SelectBuilder.WhereCompareIndexes "equals" | "lt" | "lte" | "gt" | "gte"
local compareIndexes = {
  equals = "=",
  lt = "<",
  lte = "<=",
  gt = ">",
  gte = ">=",
}

---@class MeadowsORM.SelectBuilder
---@field private _table MeadowsORM.Table
---@field private _where table<"and", { column: string, value: any, compare: MeadowsORM.SelectBuilder.WhereCompare }[]>
---@field private _select string[]
---@field private _orderBy { column: string, order: "asc" | "desc" }[]?
---@field private _limit? integer
local SelectBuilder = package:class("SelectBuilder")

---@param table MeadowsORM.Table
function SelectBuilder:init(table)
  self._table = table

  self._where = {
    ["and"] = {},
  }
  self._select = {}
  self._orderBy = {}
end

---@param column string
---@param order string
function SelectBuilder:addOrderBy(column, order)
  self._orderBy[#self._orderBy+1] = { column = column, order = order }
end

---@param method "and"
---@param column string
---@param value any
---@param compare MeadowsORM.SelectBuilder.WhereCompareIndexes
function SelectBuilder:where(method, column, value, compare)
  self._where[method][#self._where[method]+1] = { column = column, value = value, compare = compareIndexes[compare] or compare }
end

---@param tab table<string, boolean>
function SelectBuilder:select(tab)
  for column in pairs(tab) do
    ---@diagnostic disable-next-line invisible
    if (not self._table._builder:getColumnType(column)) then
      ---@diagnostic disable-next-line invisible
      error("no column " .. tostring(column) .. " in table " .. tostring(self._table._builder._tableName))
    end

    self._select[#self._select+1] = column
  end
end

---@param i integer
function SelectBuilder:limit(i)
  self._limit = i
end

---@private
---@return string?
function SelectBuilder:buildWhere()
  local result = ""

  local tab = self._where["and"]
  local count = #tab

  for i, v in pairs(tab) do
    result = result .. "" .. v.column .. v.compare .. SQLStr(v.value) .. (i == count and "" or " AND ")
  end

  return #result ~= 0 and result or nil
end

---@private
---@return string?
function SelectBuilder:buildJoin()
  return -- will break
end

---@private
---@return string?
function SelectBuilder:buildOrder()
  local result = ""
  local count = self._orderBy

  for i, order in ipairs(self._orderBy) do
    result = result .. order.column .. " " .. order.order:upper() .. (i == count and "" or ",")
  end

  return #result ~= 0 and result or nil
end

---@private
---@return integer?
function SelectBuilder:getLimit()
  return self._limit
end

---@private
---@return string
function SelectBuilder:getSelectedFields()
  local fields = self._select
  local count = #fields

  if count == 0 then
    return "*"
  end

  local result = ""

  for i, field in ipairs(fields) do
    result = result .. "`" .. SQLStr(field, true) .. "`" .. (i == count and "" or ",")
  end

  return result
end

function SelectBuilder:build()
  local fields = self:getSelectedFields()
  local where = self:buildWhere()
  local join = self:buildJoin() -- todo
  local order = self:buildOrder()
  local limit = self:getLimit()

  ---@diagnostic disable-next-line invisible
  return "SELECT " .. SQLStr(fields, true) .. " FROM `" .. SQLStr(self._table._builder._tableName, true) .. "`"
    .. (where and " WHERE " .. where or "")
    .. (join and " JOIN " .. join or "")
    .. (order and " ORDER BY " .. order or "")
    .. (limit and " LIMIT " .. SQLStr(limit, true) or "")
end