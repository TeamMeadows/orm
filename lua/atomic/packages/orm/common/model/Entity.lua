---@class MeadowsORM: Atomic.Package
local package = current()

--- Class that implements basic logic , for better developer experience
---
--- # Example
--- ```lua
--- ---@class AdminMod: Atomic.Package
--- local package = current()
---
--- ---@class AdminMod.Group: MeadowsORM.Entity
--- local Group = groupTable:entity(package, "Group")
---
--- ---@param raw table<string, any>
--- function Group:init(raw)
---   super(self, raw)
--- end
--- ```
---@class MeadowsORM.Entity: Atomic.Class
---@field protected _table MeadowsORM.TableInterface
local Entity = package:class("Entity")

function Entity:init(raw)
  for k, v in pairs(raw) do
    self[k] = v
  end
end

---@protected
---@param column string
function Entity:save(column)
  if (not self._table) then
    error("database is not set for " .. tostring(self))
  end

  async(function()
    local primaryKey = self._table:getPrimaryKey()
    local columnType = self._table:getColumn(column).type

    self._table:update({
      where = {
        [primaryKey] = self[primaryKey]
      },
      data = {
        [column] = package.types:convertToDatabase(self[column], columnType)
      },
      returning = false
      -- cache = true
      --
      -- there is no need in cache update
      -- because we already updated affected field, see `Entity.accessor`
    })
  end)
end

---@param tableInterface MeadowsORM.TableInterface
function Entity:setDatabase(tableInterface)
  self._table = tableInterface
end

---@protected
---@param field string snake_case
---@param methodName string camelCase
function Entity:accessor(field, methodName)
  local methodCapped = methodName:sub(1,1):upper() .. methodName:sub(2)

  self["set" .. methodCapped] = function(self, value)
    self[field] = value
    self:save(field)
  end

  self["get" .. methodCapped] = function(self)
    return self[field]
  end
end