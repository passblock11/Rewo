# Getting Started with Rewo

Rewo is a Dart backend framework — scaffold a project, add modules, ship a native binary.

---

## 1. Install

### As a dependency (existing Dart project)

```bash
dart pub add rewo
```

```yaml
# pubspec.yaml
dependencies:
  rewo: ^1.0.2
```

### CLI + new project (recommended)

```bash
dart pub global activate rewo
export PATH="$PATH:$HOME/.pub-cache/bin"   # add to ~/.zshrc once

rewo create my_api
cd my_api
dart pub get
cp .env.example .env
```

---

## 2. Run your API

Install the CLI once:

```bash
dart pub global activate rewo
```

### Development (hot reload)

```bash
rewo run --dev
# or
rewo dev
```

Open **http://localhost:8080** — try `/health`, `/api/items`. Edits in `lib/` restart the server automatically.

### Production

```bash
rewo run
```

### Deploy (compiled binary)

```bash
dart compile exe bin/server.dart -o server
./server
```

Copy `.env` next to the `server` binary, or set environment variables on the host.

---

## 3. Project structure

```
my_api/
  bin/
    server.dart       # entry point (compile this)
    dev.dart          # hot-reload shortcut
  lib/
    app.dart          # register modules here
    modules/          # your API modules
  test/
  .env                # config (copy from .env.example)
```

---

## 4. Add an API module

**Step 1** — Create `lib/modules/users_module.dart`:

```dart
import 'package:rewo/rewo.dart';

class UsersModule implements RewoModule {
  @override
  String get name => 'users';

  @override
  void register(Rewo app) {
    app.get('/api/users', (_) async => [
      {'id': '1', 'name': 'Alice'},
    ]);

    app.post('/api/users', (ctx) async {
      final body = await ctx.jsonBody();
      return {'created': true, 'name': body['name']};
    });
  }
}
```

**Step 2** — Register in `lib/app.dart`:

```dart
static List<RewoModule> get modules => [
  ItemsModule(),
  UsersModule(),   // add this
];
```

**Step 3** — Save file → server restarts automatically in dev mode.

---

## 5. Configuration (`.env`)

```env
PORT=8080
HOST=0.0.0.0
ENV=development
JWT_SECRET=change-me-in-production
SERVER_ENGINE=shelf
STORAGE_PATH=./storage
```

---

## 6. Deploy as native binary

```bash
dart compile exe bin/server.dart -o server
./server
```

One binary, all your APIs included.

---

## 7. CLI reference

```bash
rewo create my_api              # scaffold new project
rewo create my_api --output ..  # create in parent folder
rewo run --dev                  # hot-reload (from project root)
rewo run                        # production server
```

---

## 8. Framework features

| Feature | Description |
|---------|-------------|
| `RewoModule` | Plug-in API modules |
| `RewoBootstrap` | Wire env, DI, modules, listen |
| JWT + sessions | Built-in auth |
| OpenAPI | Auto `/openapi.json` |
| `TestApp` | Integration tests without HTTP |
| Hot reload | `rewo run --dev` or `rewo dev` |

---

## Need help?

- [README](https://github.com/passblock11/Rewo#readme)
- [pub.dev/packages/rewo](https://pub.dev/packages/rewo)
- [Avanti Inc.](https://avantiinc.xyz)
