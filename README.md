<div align="center">
  <img src="assets/logo.png"/>
  <h1 align="center">Meadows ORM</h1>

  <img src="https://img.shields.io/github/actions/workflow/status/TeamMeadows/orm/build.yml">
  <img src="https://img.shields.io/github/release/TeamMeadows/orm.svg">
  <img src="https://img.shields.io/github/issues/TeamMeadows/orm.svg">
  <img src="https://img.shields.io/github/license/TeamMeadows/orm.svg">

  [<kbd> <br> Download <br> </kbd>][Download] | [<kbd> <br> Getting Started <br> </kbd>][Getting Started] | [<kbd> <br> Documentation (DeepWiki) <br> </kbd>][Documentation]
</div>

[Download]: https://github.com/TeamMeadows/orm/releases/latest
[Getting Started]: https://deepwiki.com/TeamMeadows/orm/1.2-quick-start-guide
[Documentation]: https://deepwiki.com/TeamMeadows/orm

Meadows ORM is an [ORM](https://en.wikipedia.org/wiki/Object%E2%80%93relational_mapping) system for Garry's Mod based on the [Atomic Framework](https://github.com/TeamMeadows/atomic-framework), which allows you to easily integrate it into your [Atomic](https://github.com/TeamMeadows/atomic-framework) projects.

## Features
- [x] Declarative style - you do not need to write SQL code
- [x] Automatic values escaping - you do not need to be care of SQL injections
- [x] Relations support
- [x] Based on coroutines (async)
- [x] Easy to embed in your project
- [x] [Prisma](https://prisma.io)-like interface to interact with your database
- [x] Indexes support
- [x] [Caching] support
  - *Indexes allows you to get values from cache with O(1) complexity
- [ ] Joins support - you can write complex queries with ease
- [ ] Prebuilded queries

## Examples
### Basics
- [Table Definition](./examples/table_definition.lua) — database table definition
- [Queries](./examples/queries.lua) — how to make queries
- [Summary](./examples/summary.lua) — everything in one file

### Advanced
- [Relations](./examples/relations.lua) — relationships between tables
- [Entity](./examples/entity.lua) — custom entity creation
- [Cache](./examples/cache.lua) — cached queries and CRUD operations
- [JSON](./examples/json.lua) — working with JSON data

<a href="https://github.com/TeamMeadows/atomic-framework">
  <p align="center">
    <img src="https://github.com/TeamMeadows/atomic-framework/blob/develop/assets/badges/dark/powered.png?raw=true"/>
    <img src="https://github.com/TeamMeadows/atomic-framework/blob/develop/assets/badges/dark/ecosystem.png?raw=true"/>
  </p>
</a>