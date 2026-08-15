# Rewo (`rewo`)

[![pub package](https://img.shields.io/pub/v/rewo.svg)](https://pub.dev/packages/rewo)
[![publisher](https://img.shields.io/pub/publisher/rewo)](https://pub.dev/publishers/avantiinc.xyz)

> Spring power. Flutter simplicity. Express ease.

**Rewo** is a modular Dart backend framework for building REST APIs. Scaffold a new project in one command, add modules, compile to a native binary — one server, all APIs included.

Published by [Avanti Inc.](https://avantiinc.xyz) · [pub.dev](https://pub.dev/packages/rewo)

---

## Install

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rewo: ^1.0.1
```

Or scaffold a full project with the CLI:

```bash
dart pub global activate rewo
rewo create my_api
```

Or scaffold without global install (from any project that has `rewo`):

```bash
dart pub global activate rewo
rewo create my_api
```

---

## Quick start (new project)

```bash
rewo create my_api
cd my_api
dart pub get
cp .env.example .env
dart run bin/dev.dart        # hot reload
# or
dart run bin/server.dart     # production run
```

Your project layout:

```
my_api/
  bin/server.dart       # entry point
  bin/dev.dart          # hot-reload dev server
  lib/app.dart          # register modules here
  lib/modules/          # your API modules
  test/
  .env
```

---

## Add an API module

```dart
// lib/modules/hello_module.dart
import 'package:rewo/rewo.dart';

class HelloModule implements RewoModule {
  @override
  String get name => 'hello';

  @override
  void register(Rewo app) {
    app.get('/api/hello', (_) async => {'message': 'Hello World'});
  }
}
```

Register in `lib/app.dart`:

```dart
static List<RewoModule> get modules => [
  HelloModule(),
];
```

---

## Features

| Category | Feature |
|----------|---------|
| **CLI** | `rewo create` project scaffolding |
| **Dev** | Hot-reload via `bin/dev.dart` or `rewo dev` |
| **HTTP** | REST routing, native server, HTTP/2, OpenAPI |
| **Auth** | JWT, sessions, Bearer tokens, role-based access |
| **Core** | Dependency injection, events, scheduler, modules |
| **Data** | Validation, in-memory repo, transactions, pagination |
| **Ops** | Health/readiness, metrics, graceful shutdown |
| **Config** | `.env` loading and validation |
| **Deploy** | `dart compile exe bin/server.dart -o server` |

---

## Minimal app (no scaffold)

```dart
import 'package:rewo/rewo.dart';

void main() async {
  await Rewo.run((app) {
    app.get('/hello', (_) async => {'message': 'Hello World'});
  }, config: AppConfig(port: 8080));
}
```

---

## Configuration (`.env`)

```env
PORT=8080
HOST=0.0.0.0
ENV=development
JWT_SECRET=change-me-in-production
SERVER_ENGINE=native
STORAGE_PATH=./storage
```

---

## Commands

```bash
rewo create my_api          # scaffold project
dart run bin/dev.dart             # hot-reload dev
dart run bin/server.dart          # run server
dart test                         # tests
dart compile exe bin/server.dart -o server
```

---

## Documentation

- [Getting Started](https://github.com/passblock11/Rewo/blob/main/GETTING_STARTED.md)
- [Performance](https://github.com/passblock11/Rewo/blob/main/PERFORMANCE.md)
- [Changelog](CHANGELOG.md)

---

## License

MIT © [Avanti Inc.](https://avantiinc.xyz)
