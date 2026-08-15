# DartServe — Dart Backend Framework

A Spring-like, Flutter-simple backend framework for Dart.

## Features

- **HTTP routing** — REST controllers with fluent route registration
- **Dependency injection** — constructor-based, singleton/factory/lazy
- **Middleware** — logging, CORS, error handling, auth
- **Validation** — request body validation
- **Events** — in-process event bus
- **Scheduling** — interval-based cron tasks
- **Transactions** — commit/rollback hooks
- **Repository** — generic in-memory CRUD

## Quick start

```bash
dart pub get
dart run example/main.dart
```

## Run tests

```bash
dart test
dart run example/main.dart test   # integration smoke test
```

## Example controller

```dart
class UserController extends RestController {
  UserController(this._users);
  final UserService _users;

  @override
  String get basePath => '/users';

  @override
  void registerRoutes(RouteRegistrar r) {
    r.get('/', list);
    r.post('/', create, statusCode: 201);
    r.get('/:id', get);
  }

  Future<List<Map<String, dynamic>>> list(RequestContext ctx) async { ... }
}
```

## API endpoints (example app)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Health check |
| GET | `/users` | List users |
| POST | `/users` | Create user |
| GET | `/users/:id` | Get user |
| DELETE | `/users/:id` | Delete user |
| GET | `/users/admin/stats` | Admin stats (requires Bearer token) |
