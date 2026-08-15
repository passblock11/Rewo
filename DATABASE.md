# Database & ORM in Rewo

Rewo does **not** lock you into one database or ORM. Use built-in Postgres support, any SQL driver, or any Dart ORM.

## Environment variables

| Variable | Use |
|----------|-----|
| `DATABASE_URL` | Primary connection (Postgres, MySQL URL, etc.) |
| `DIRECT_URL` | Migrations / DDL (Supabase session mode, port 5432) |
| `MYSQL_URL` | MySQL / MariaDB |
| `MONGODB_URI` | MongoDB |
| `SQLITE_PATH` | SQLite file path |

## Built-in: Postgres (raw SQL)

```env
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
```

```dart
final pool = ctx.container.resolve<PostgresPool>();
await pool.query('SELECT * FROM users');
```

Auto-wired on startup when `DATABASE_URL` is `postgresql://...`.

## Any database — `configureDatabase`

Register **your** driver or ORM in bootstrap:

```dart
RewoBootstrap.run(
  modules: modules,
  configureDatabase: (app, config) async {
    // Example: MongoDB
    // final db = await Db.create(config.databaseUrl!);
    // app.singleton<Db>(db);

    // Example: Drift ORM (SQLite)
    // app.singleton<AppDatabase>(AppDatabase());

    // Example: MySQL raw driver
    // final conn = await MySqlConnection.connect(...);
    // app.singleton<MySqlConnection>(conn);
  },
);
```

Use in modules:

```dart
app.get('/users', (ctx) async {
  final db = ctx.container.resolve<AppDatabase>(); // your ORM
  return db.select(db.users).get();
});
```

## ORMs that work with Rewo

Rewo is ORM-agnostic. Register the generated client on `Rewo.container`:

| ORM | Database | Package |
|-----|----------|---------|
| **Drift** | SQLite, Postgres | `drift` |
| **Stormberry** | Postgres | `stormberry` |
| **Prisma** | — | N/A in Dart server |
| **mongo_dart** | MongoDB | `mongo_dart` |
| **Raw SQL** | Any | `postgres`, `mysql_client`, etc. |

## Custom `DatabasePlugin`

Ship a reusable connector for your team:

```dart
class MongoDatabasePlugin implements DatabasePlugin {
  @override
  bool supports(DatabaseConfig config) =>
      config.kind == DatabaseKind.mongodb;

  @override
  Future<void> connect(Rewo app, DatabaseConfig config) async { ... }

  @override
  Future<void> disconnect(Rewo app) async { ... }

  @override
  Future<bool> healthCheck(Rewo app) async { ... }
}

RewoBootstrap.run(
  modules: modules,
  databasePlugins: [PostgresDatabasePlugin(), MongoDatabasePlugin()],
);
```

## Migrations

- **SQL files**: `dart run bin/migrate.dart` (uses `DIRECT_URL`)
- **ORM migrations**: use your ORM's tool (`drift_dev`, `stormberry`, etc.)
- **Supabase**: SQL editor or `supabase db push`

Both can coexist: ORM for app code, SQL files for ops.
