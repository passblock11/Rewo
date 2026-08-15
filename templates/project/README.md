# {{title}}

A [Rewo](https://pub.dev/packages/rewo) API project by [Avanti Inc.](https://avantiinc.xyz)

## Quick start

```bash
dart pub get
cp .env.example .env
```

Server runs at **http://localhost:8080**

### Development (hot reload)

```bash
dart run bin/dev.dart
# or
dart run bin/server.dart --dev
```

### Production

```bash
# Run with Dart
dart run bin/server.dart

# Compile and run native binary (deploy)
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
| `dart run bin/dev.dart` | Dev server with hot reload |
| `dart run bin/server.dart --dev` | Same as above |
| `dart run bin/server.dart` | Production (no hot reload) |
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
