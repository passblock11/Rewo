# {{title}}

A [Rewo](https://pub.dev/packages/rewo) API project by [Avanti Inc.](https://avantiinc.xyz)

## Quick start

```bash
dart pub get
cp .env.example .env
dart pub global activate rewo   # once per machine
```

Server runs at **http://localhost:8080**

### Development (hot reload)

```bash
rewo run --dev
# or
rewo dev
```

### Production

```bash
rewo run
```

### Deploy (compiled binary)

```bash
dart compile exe bin/server.dart -o server
./server
```

## Add a new API module

1. Create `lib/modules/my_module.dart` implementing `RewoModule`
2. Add it to `App.modules` in `lib/app.dart`
3. Restart the server

## Commands

| Command | Use |
|---------|-----|
| `rewo run --dev` | Dev server with hot reload |
| `rewo dev` | Same as above |
| `rewo run` | Production server |
| `rewo run 3000` | Production on custom port |
| `dart compile exe bin/server.dart -o server` | Build production binary |
| `./server` | Run compiled binary |
| `dart test` | Run tests |

## Project layout

```
bin/server.dart       # entry point (compile this)
lib/app.dart          # module registry
lib/modules/          # your API modules
test/                 # integration tests
.env                  # config (not committed)
```
