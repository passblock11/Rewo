<p align="center">
  <strong style="font-size: 2.5rem;">⚡ Rewo</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/rewo"><img src="https://img.shields.io/pub/v/rewo.svg" alt="pub version"></a>
  <a href="https://pub.dev/packages/rewo/score"><img src="https://img.shields.io/pub/points/rewo" alt="pub points"></a>
  <a href="https://pub.dev/packages/rewo"><img src="https://img.shields.io/badge/Dart-%3E%3D3.3.0-0175C2" alt="Dart SDK"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license"></a>
</p>

<p align="center">
  <strong>Spring power. Flutter simplicity. Express ease.</strong>
</p>

<p align="center">
  A modern Dart backend framework for building REST APIs — fast to learn, easy to deploy, and ready for production.
</p>

---

## What is Rewo?

**Rewo** helps you build backend APIs (the server side of apps and websites) using **Dart** — the same language used in Flutter.

You do **not** need to know Spring, Node.js, or Python. If you can write basic Dart, you can build a full API with Rewo:

- **Routes** — define URLs like `/api/users`
- **Modules** — organize code into clean folders
- **Auth** — login with JWT tokens
- **Database** — connect Postgres or any database you like
- **Deploy** — compile to a small native binary

Think of Rewo as **Express.js for Dart**, with batteries included.

---

## 🚀 Key Features

### Core Architecture

- **⚡ High Performance** — shelf, native, or HTTP/2 server engines
- **🧩 Modular Design** — one file per feature (`RewoModule`)
- **💉 Dependency Injection** — register services once, use anywhere
- **⚙️ Configuration** — `.env` file + environment variables

### Development Tools

- **🛠️ CLI** — `rewo create my_api` scaffolds a full project
- **🔥 Hot Reload** — `rewo run --dev` restarts on save (like nodemon)
- **📖 OpenAPI** — auto-generated at `/openapi.json`
- **🧪 Testing** — call routes without starting a real server

### Data & Storage

- **🐘 Postgres** — built-in pool when `DATABASE_URL` is set
- **🔌 Any ORM** — Drift, Stormberry, mongo_dart, raw SQL
- **📁 File Storage** — save uploads to disk (swap for S3 later)
- **📄 Pagination** — `Page` + `PageRequest` helpers

### Security & Auth

- **🔐 JWT** — sign and verify access tokens
- **🛡️ Middleware** — CORS, rate limiting, security headers
- **✅ Validation** — email, required fields, min/max length
- **👤 Roles** — protect routes by user role (`admin`, `user`, …)

### Production Ready

- **💾 Caching** — in-memory cache with TTL
- **📬 Job Queue** — background tasks without extra services
- **⏰ Scheduler** — run code every N seconds
- **❤️ Health Checks** — `/health`, `/ready`, `/metrics`

---

## 📦 Installation

### Step 1 — Install the CLI (one time)

```bash
dart pub global activate rewo
```

> **What this does:** installs the `rewo` command on your computer so you can create and run projects.

### Step 2 — Add Rewo to an existing project

```yaml
# pubspec.yaml
dependencies:
  rewo: ^1.0.14
```

Then run:

```bash
dart pub get
```

---

## 📋 Requirements

| Requirement | Version |
|-------------|---------|
| **Dart SDK** | `>= 3.3.0` |
| **Platforms** | Windows, macOS, Linux |
| **Database** | Optional (Postgres, MySQL, MongoDB, SQLite, …) |

---

## ⚡ Quick Start

Get your first API running in **under 2 minutes**.

### 1. Create a new project

```bash
rewo create my_api
cd my_api
dart pub get
cp .env.example .env
```

### 2. Start the dev server (hot reload)

```bash
rewo run --dev
```

### 3. Open in browser

```
http://localhost:8080
```

You should see a JSON welcome message. Your API is live.

### 4. Production

```bash
rewo run
```

### 5. Deploy (compiled binary)

```bash
dart compile exe bin/server.dart -o server
./server
```

---

## 📚 20 Code Examples (Copy & Paste)

Each example is **self-contained** and explains *what* it does before *how*.

---

### Example 1 — Smallest possible API (Hello World)

**What:** One file, one route, no project scaffold.

```dart
import 'package:rewo/rewo.dart';

Future<void> main() async {
  await Rewo.run((app) {
    app.get('/hello', (_) async => {'message': 'Hello World'});
  }, config: AppConfig(port: 8080));
}
```

**Try it:** `curl http://localhost:8080/hello`

---

### Example 2 — Create a module (recommended pattern)

**What:** Modules keep your code organized — one module per feature (users, auth, products).

```dart
// lib/modules/hello_module.dart
import 'package:rewo/rewo.dart';

class HelloModule implements RewoModule {
  @override
  String get name => 'hello';

  @override
  void register(Rewo app) {
    app.get('/api/hello', (_) async => {'message': 'Hello from a module!'});
  }
}
```

Register it in `lib/app.dart`:

```dart
static List<RewoModule> get modules => [
  HelloModule(),
];
```

---

### Example 3 — GET and POST routes

**What:** `GET` reads data. `POST` creates data from JSON body.

```dart
@override
void register(Rewo app) {
  // GET — return a list
  app.get('/api/items', (_) async => [
        {'id': '1', 'title': 'Milk'},
        {'id': '2', 'title': 'Bread'},
      ]);

  // POST — read JSON from request body
  app.post('/api/items', (ctx) async {
    final body = await ctx.jsonBody();
    final title = body['title'] as String? ?? '';
    return {'id': '3', 'title': title, 'created': true};
  });
}
```

**Try it:**

```bash
curl -X POST http://localhost:8080/api/items \
  -H "Content-Type: application/json" \
  -d '{"title":"Eggs"}'
```

---

### Example 4 — URL parameters (`:id`)

**What:** `:id` in the path becomes a variable you can read.

```dart
app.get('/api/items/:id', (ctx) async {
  final id = ctx.param('id')!;
  return {'id': id, 'title': 'Item $id'};
});

app.delete('/api/items/:id', (ctx) async {
  final id = ctx.param('id')!;
  return {'deleted': true, 'id': id};
});
```

**Try it:** `curl http://localhost:8080/api/items/42`

---

### Example 5 — Query parameters (`?page=1`)

**What:** Values after `?` in the URL.

```dart
app.get('/api/search', (ctx) async {
  final q = ctx.query('q') ?? '';
  final limit = int.tryParse(ctx.query('limit') ?? '10') ?? 10;
  return {'query': q, 'limit': limit, 'results': []};
});
```

**Try it:** `curl "http://localhost:8080/api/search?q=dart&limit=5"`

---

### Example 6 — Input validation (email, required, length)

**What:** Reject bad data **before** it hits your database. Returns `422` automatically.

```dart
app.post('/api/signup', (ctx) async {
  final body = await ctx.jsonBody();
  final email = (body['email'] as String? ?? '').trim();
  final password = body['password'] as String? ?? '';

  Validator.validateOrThrow(
    {'email': email, 'password': password},
    {
      'email': const ValidateRule.email(),      // rejects emoji, invalid formats
      'password': const ValidateRule(required: true, minLength: 8),
    },
  );

  return {'ok': true, 'email': email};
});
```

**Invalid email** (emoji) → `422` with `{ "email": "email must be a valid email" }`

---

### Example 7 — JWT: create a login token

**What:** After login, give the user a token. They send it on every protected request.

```dart
@override
void register(Rewo app) {
  final jwt = JwtService(secret: app.config.jwtSecret, expiry: Duration(hours: 1));
  app.singleton(jwt);

  app.post('/api/login', (ctx) async {
    final body = await ctx.jsonBody();
    final email = body['email'] as String? ?? '';

    // In real apps: check password against database here
    final token = jwt.sign({
      'sub': 'user-123',           // user id
      'email': email,
      'roles': ['user'],
      'type': 'access',
    });

    return {'access_token': token, 'token_type': 'Bearer'};
  });
}
```

Set in `.env`:

```env
JWT_SECRET=your-super-secret-key-min-16-chars
```

---

### Example 8 — Protect a route with JWT middleware

**What:** Only logged-in users can access this route.

```dart
app.get(
  '/api/me',
  (ctx) async {
    return {
      'userId': ctx.userId,
      'roles': ctx.roles,
    };
  },
  middleware: [JwtMiddleware(jwt).handler],
);
```

**Try it:**

```bash
# Without token → 401 Unauthorized
curl http://localhost:8080/api/me

# With token → 200 OK
curl http://localhost:8080/api/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

### Example 9 — Role-based access (admin only)

**What:** Only users with the `admin` role can access.

```dart
app.get(
  '/api/admin/stats',
  (_) async => {'users': 100, 'orders': 500},
  middleware: [
    JwtMiddleware(jwt, roles: ['admin']).handler,
  ],
);
```

---

### Example 10 — Dependency Injection (register once, use everywhere)

**What:** Create a service class and inject it into routes via the container.

```dart
class UserService {
  Future<Map<String, dynamic>> getProfile(String id) async {
    return {'id': id, 'name': 'Tejas'};
  }
}

@override
void register(Rewo app) {
  app.singleton(UserService());

  app.get('/api/users/:id', (ctx) async {
    final service = ctx.container.resolve<UserService>();
    return service.getProfile(ctx.param('id')!);
  });
}
```

---

### Example 11 — Connect any database (`configureDatabase`)

**What:** Rewo does not force one ORM. You register **your** database in one place.

```dart
// lib/database/setup.dart
Future<void> configureDatabase(Rewo app, AppConfigValues config) async {
  final url = config.databaseUrl;
  if (url == null) return;

  // Example: your own connection / ORM
  // final db = await MyDatabase.connect(url);
  // app.singleton<MyDatabase>(db);

  app.health.register('database', () async {
    // return true if DB is reachable
    return true;
  });
}
```

Wire it in bootstrap:

```dart
RewoBootstrap.run(
  modules: modules,
  configureDatabase: configureDatabase,
);
```

See [DATABASE.md](DATABASE.md) for Postgres, Drift, Stormberry, MongoDB, and more.

---

### Example 12 — Postgres raw SQL (built-in)

**What:** If `DATABASE_URL` starts with `postgresql://`, Rewo auto-connects a pool.

```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/mydb
```

```dart
app.get('/api/users', (ctx) async {
  final pool = ctx.container.resolve<PostgresPool>();
  final rows = await pool.query('SELECT id, email FROM users LIMIT 10');
  return rows; // each row is a Map: {'id': '...', 'email': '...'}
});
```

---

### Example 13 — Events (decouple code with EventBus)

**What:** When something happens (user created), notify other parts of your app without tight coupling.

```dart
class UserCreatedEvent {
  UserCreatedEvent(this.email);
  final String email;
}

@override
void register(Rewo app) {
  // Listen
  app.events.on<UserCreatedEvent>((e) {
    print('📣 New user signed up: ${e.email}');
    // send welcome email, update analytics, etc.
  });

  // Emit
  app.post('/api/users', (ctx) async {
    final body = await ctx.jsonBody();
    app.events.emit(UserCreatedEvent(body['email'] as String));
    return {'ok': true};
  });
}
```

---

### Example 14 — Caching (speed up repeated reads)

**What:** Store expensive results in memory for a few minutes.

```dart
@override
void register(Rewo app) {
  final cache = app.container.resolve<Cache>();

  app.get('/api/weather', (ctx) async {
    return cached(cache, 'weather-london', () async {
      // simulate slow API call
      await Future.delayed(Duration(seconds: 2));
      return {'city': 'London', 'temp': 18};
    }, ttl: Duration(minutes: 5));
  });
}
```

Second request within 5 minutes → instant response from cache.

---

### Example 15 — Background jobs (JobQueue)

**What:** Do slow work (send email, resize image) without making the user wait.

```dart
@override
void register(Rewo app) {
  final queue = app.container.resolve<JobQueue>();

  app.post('/api/contact', (ctx) async {
    final body = await ctx.jsonBody();
    final email = body['email'] as String;

    queue.add('send-email', () async {
      print('Sending email to $email...');
      await Future.delayed(Duration(seconds: 1));
      print('Email sent!');
    });

    return {'ok': true, 'message': 'We will reply soon'};
  });
}
```

User gets `200 OK` immediately. Email sends in the background.

---

### Example 16 — Scheduled tasks (cron-style)

**What:** Run code automatically every N seconds.

```dart
@override
void register(Rewo app) {
  app.schedule(60, () async {
    print('🕐 Cleanup ran at ${DateTime.now()}');
    // delete expired sessions, purge old logs, etc.
  });
}
```

---

### Example 17 — Pagination (page & limit)

**What:** Return large lists in pages instead of all at once.

```dart
app.get('/api/products', (ctx) async {
  final pageReq = PageRequest.fromQuery(ctx.queryParameters);
  final allItems = List.generate(100, (i) => {'id': '$i', 'name': 'Product $i'});

  final start = pageReq.offset;
  final slice = allItems.skip(start).take(pageReq.limit).toList();

  return Page(
    items: slice,
    page: pageReq.page,
    limit: pageReq.limit,
    total: allItems.length,
  ).toJson((item) => item);
});
```

**Try it:** `curl "http://localhost:8080/api/products?page=2&limit=10"`

---

### Example 18 — File upload & storage

**What:** Save files to disk under `./storage`.

```dart
@override
void register(Rewo app) {
  final storage = app.container.resolve<Storage>();

  app.post('/api/upload', (ctx) async {
    final form = ctx.multipart;
    if (form == null) throw BadRequestException('multipart form required');

    final file = form.files['file'];
    if (file == null) throw BadRequestException('file is required');

    final path = 'uploads/${DateTime.now().millisecondsSinceEpoch}_${file.filename}';
    await storage.write(path, file.bytes);

    return {'path': path, 'url': storage.url(path)};
  }, middleware: [multipartParser()]);
}
```

---

### Example 19 — Serve static files (HTML, images)

**What:** Serve a `public/` folder at `/public`.

```dart
@override
void register(Rewo app) {
  app.useStaticFiles('public', prefix: '/public');
}
```

Put `public/index.html` → open `http://localhost:8080/public/index.html`

---

### Example 20 — Test your API without HTTP

**What:** Fast unit tests — no real server, no port conflicts.

```dart
import 'package:rewo/rewo.dart';
import 'package:test/test.dart';

void main() {
  test('GET /hello returns message', () async {
    final testApp = await TestApp.create((app) {
      app.get('/hello', (_) async => {'message': 'hi'});
    });

    final result = await testApp.call('GET', '/hello');
    expect(result, {'message': 'hi'});
  });
}
```

Run: `dart test`

---

## 🗂️ Project Structure (after `rewo create`)

```
my_api/
├── bin/
│   └── server.dart          # Entry point — starts the server
├── lib/
│   ├── app.dart             # Registers your modules
│   └── modules/             # Your API features (one file each)
│       ├── auth_module.dart
│       └── items_module.dart
├── test/
│   └── api_test.dart
├── .env                     # Secrets & config (never commit!)
├── .env.example             # Template for teammates
└── pubspec.yaml
```

---

## ⚙️ Configuration (`.env`)

Copy `.env.example` to `.env` and edit:

```env
# Server
PORT=8080
HOST=0.0.0.0
ENV=development

# Auth (required in production — min 16 characters)
JWT_SECRET=change-me-in-production

# Database (optional)
DATABASE_URL=postgresql://user:pass@localhost:5432/mydb
DIRECT_URL=postgresql://user:pass@localhost:5432/mydb

# Engine: shelf | native | http2
SERVER_ENGINE=shelf

# Storage
STORAGE_PATH=./storage
LOG_REQUESTS=true
RATE_LIMIT=100
```

| Variable | What it does |
|----------|--------------|
| `PORT` | Which port the server listens on |
| `HOST` | `0.0.0.0` = accept connections from anywhere (needed for Docker/Render) |
| `ENV` | `production` enables stricter security checks |
| `JWT_SECRET` | Secret key used to sign login tokens |
| `DATABASE_URL` | Your database connection string |

---

## 🛠️ CLI Commands Cheat Sheet

| Command | What it does |
|---------|--------------|
| `rewo create my_api` | Create a new project |
| `rewo run --dev` | Dev server with hot reload |
| `rewo dev` | Same as `rewo run --dev` |
| `rewo run` | Production server |
| `rewo run 3000` | Run on port 3000 |
| `dart compile exe bin/server.dart -o server` | Build deployable binary |
| `dart test` | Run tests |

---

## 🌐 Built-in Endpoints

Every Rewo app includes these automatically:

| URL | Purpose |
|-----|---------|
| `GET /` | Welcome JSON with module list |
| `GET /health` | Liveness check (`{"status":"alive"}`) |
| `GET /ready` | Readiness (checks database health) |
| `GET /metrics` | Basic request metrics |
| `GET /openapi.json` | OpenAPI spec for your routes |

---

## 🚢 Deploy to Production

### Docker (Render, Fly.io, Railway)

```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/server /app/server
ENV HOST=0.0.0.0
CMD ["./server"]
```

Set environment variables in your hosting dashboard: `JWT_SECRET`, `DATABASE_URL`, `HOST=0.0.0.0`.

---

## 📖 More Documentation

- [DATABASE.md](DATABASE.md) — Postgres, ORMs, custom database plugins
- [GETTING_STARTED.md](GETTING_STARTED.md) — step-by-step beginner guide
- [PERFORMANCE.md](PERFORMANCE.md) — HTTP/2, isolates, tuning
- [CHANGELOG.md](CHANGELOG.md) — version history

---

## 📞 Support & Community

- 🐛 **Bug Reports** — [GitHub Issues](https://github.com/passblock11/Rewo/issues)
- 💡 **Feature Requests** — [GitHub Discussions](https://github.com/passblock11/Rewo/discussions)
- 📦 **pub.dev** — [pub.dev/packages/rewo](https://pub.dev/packages/rewo)

### Getting Help

1. Read this README — most questions are answered above
2. Check [existing issues](https://github.com/passblock11/Rewo/issues)
3. Open a new issue with your code + error message

---

<p align="center">
  Built with ❤️ for the Dart community by <a href="https://avantiinc.xyz">Avanti Inc.</a>
</p>

<p align="center">
  <em>Empowering developers to build powerful backend APIs with the elegance and performance of Dart.</em>
</p>

---

## License

MIT © [Avanti Inc.](https://avantiinc.xyz)
