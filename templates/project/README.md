# {{title}}

A [Rewo](https://pub.dev/packages/rewo) API project by [Avanti Inc.](https://avantiinc.xyz)

## Quick start

```bash
dart pub get
cp .env.example .env
dart run bin/server.dart
```

Server runs at **http://localhost:8080**

## Add a new API module

1. Create `lib/modules/my_module.dart` implementing `RewoModule`
2. Add it to `App.modules` in `lib/app.dart`
3. Restart the server

## Commands

```bash
dart run bin/server.dart              # run server
dart run bin/dev.dart                 # hot reload dev server
dart test                             # run tests
dart compile exe bin/server.dart -o server   # production binary
```

## Project layout

```
bin/server.dart       # entry point (compile this)
lib/app.dart          # module registry
lib/modules/          # your API modules
test/                 # integration tests
.env                  # config (not committed)
```
