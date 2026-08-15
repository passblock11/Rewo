## 1.0.10

- Move codegen deps (`build`, `source_gen`, `analyzer`) to dev_dependencies so apps can `dart compile exe` for production deploys
- Stop exporting `codegen/builder.dart` from the main library

## 1.0.9

- Pluggable database layer: any DB via `configureDatabase` or custom `DatabasePlugin`
- Built-in `PostgresDatabasePlugin`; env supports `MYSQL_URL`, `MONGODB_URI`, `SQLITE_PATH`
- See [DATABASE.md](DATABASE.md) for ORM integration (Drift, Stormberry, mongo_dart, etc.)

## 1.0.8

- Add `put`, `patch`, and `delete` route helpers on `Rewo`

## 1.0.7

- Auto-connect `PostgresPool` when `DATABASE_URL` is set in `.env`
- Database health check on `/ready` and pool cleanup on shutdown

## 1.0.6

- Hot reload now stops the **previous** port before binding a new one (fixes orphan servers when `PORT` changes in `.env`)

## 1.0.5

- Fix `.env` `PORT` not applied when `bin/server.dart` read env before `DotEnv.load()`
- Clearer "port already in use" error with fix instructions
- Improve hot-reload port release between restarts
- `DevServer.cliPort()` / `DevServer.resolvedPort()` helpers

## 1.0.4

- Developer-friendly error responses in dev mode (file, line, type, hint, stack)
- Clearer console output for unhandled route errors

## 1.0.3

- `rewo run` runs the current project's `bin/server.dart` (production)
- `rewo run --dev` / `rewo dev` for hot-reload development
- Updated README and getting-started docs for dev/prod workflow

## 1.0.2

- Fix `.gitignore` / `.pubignore` excluding `lib/src/storage/` from repo and pub publish
- Include `lib/src/storage/storage.dart` in published package (fixes pub.dev dartdoc analysis)

## 1.0.1

- Fix project template `pubspec.yaml` YAML syntax for `rewo create`
- Fix analyzer warnings for pub.dev validation

## 1.0.0

- First pub.dev release of **Rewo** (`rewo`)
- Modular backend framework: routing, DI, middleware, validation
- JWT auth, sessions, role-based access, rate limiting
- OpenAPI generation, health/metrics endpoints, graceful shutdown
- `.env` config loading and validation
- Local file storage, in-memory repository, transactions
- Native HTTP server engine and HTTP/2 support
- `rewo create` CLI to scaffold new backend projects
- `rewo dev` and `bin/dev.dart` hot-reload development workflow
- `RewoBootstrap` and `RewoModule` for unified multi-API servers
- `TestApp` utility for integration testing
- Route codegen via `build_runner`

## 0.3.0

- Internal development milestone (pre-release)

## 0.2.0

- Added config, storage, JWT, cache, queue, OpenAPI, pagination

## 0.1.0

- Initial MVP: routing, DI, middleware, events, scheduler
