---@type PackageMeta
return {
  id = "team.meadows.orm",
  title = "Meadows ORM",
  description = "An ORM for MySQLOO",
  documentation = "https://github.com/TeamMeadows/orm",
  icon = "https://github.com/TeamMeadows/orm/raw/production/assets/logo.png",
  kind = "library",
  version = "1.0.0",
  files = {
    dir = "common",
    server = {
      "utilities",
      "model/builders/TableBuilder",
      "model/builders/WhereBuilder",
      "model/builders/SelectBuilder",
      "model/builders/InsertBuilder",
      "model/builders/UpdateBuilder",
      "model/builders/DeleteBuilder",
      "model/Entity",
      "model/TableInterface",
      "model/Table",
      "api",
      "database"
    }
  },
  dependencies = {
    server = {
      atomic = "^1.0.0-alpha.1"
    }
  }
}