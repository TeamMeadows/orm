---@type Atomic.Package.Metadata
return {
  id = "team.meadows.orm",
  title = "Meadows ORM",
  description = "An ORM system for Garry's Mod",
  documentation = "https://github.com/TeamMeadows/orm/wiki",
  icon = "https://github.com/TeamMeadows/orm/raw/production/assets/logo.png",
  kind = "library",
  version = "1.0.0",
  files = {
    server = {
      "common/model/builders/table.lua",
      "common/model/builders/select.lua",
      "common/model/builders/insert.lua",
      "common/model/builders/update.lua",
      "common/model/builders/delete.lua",
      "common/model/tableinterface.lua",
      "common/model/table.lua",
      "common/api.lua",
      "common/database.lua"
    }
  }
}
