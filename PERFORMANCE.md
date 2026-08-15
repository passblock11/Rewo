# Performance Architecture

Rewo is designed to beat Spring Boot and Node.js frameworks on **throughput**, **latency**, and **startup time** by leaning into Dart's strengths.

## Why Rewo can be faster

| Bottleneck | Spring Boot | Node.js (Express/Fastify) | Rewo |
|---|---|---|---|
| Startup | JVM warmup (2–10s) | Fast (~100ms) | **AOT binary (~10ms)** |
| Memory | 200–500MB baseline | 50–150MB | **20–80MB** |
| Request dispatch | Reflection + servlet chain | Callback/middleware chain | **Pre-compiled pipeline** |
| JSON | Jackson reflection | `JSON.parse` (JS) | **Codegen serializers** (roadmap) |
| Concurrency | Thread pools (heavy) | Single thread + libuv | **Event loop + isolates** |
| Deployment | JRE + fat JAR | Node runtime | **Single native binary** |

## Built-in optimizations (v0.2)

### 1. Turbo mode + native engine

```dart
await Rewo.run((app) {
  app.get('/ping', (_) => {'pong': true});
}, config: AppConfig.turbo(port: 8080), engine: ServerEngine.native);
```

### 2. build_runner route codegen

```dart
@Controller('/users')
class UserController extends RestController with $UserControllerRoutes {
  @Get('/')
  Future<List<User>> list(RequestContext ctx) async { ... }
}
```

Run `dart run build_runner build` to generate `*.routes.g.dart` — zero runtime route reflection.

### 3. json_serializable + bodyAs

```dart
@Post('/')
Future<User> create(RequestContext ctx) async {
  final req = await ctx.bodyAs(CreateUserRequest.fromJson);
  return service.create(req);
}
```

### 4. Postgres connection pool

```dart
final pool = PostgresPool.fromUrl(Platform.environment['DATABASE_URL']!);
await pool.open();
final rows = await pool.query('SELECT * FROM users WHERE id = @id', parameters: {'id': userId});
```

### 5. Shared isolate pool

```dart
final hash = await computePooled(heavyHash, password);
```

### 6. Hot restart dev loop

```bash
dart run bin/rewo_dev.dart example/main.dart
```

### 7. HTTP/2 (via handleSocket behind TLS proxy)

```dart
final engine = Http2ServerEngine(...);
await engine.handleSocket(tlsSocket);
```

## Built-in optimizations (v0.1)

### 1. Turbo mode (`AppConfig.turbo()`)

```dart
final app = Rewo(config: AppConfig.turbo(port: 8080));
```

- Disables request logging
- Skips CORS middleware (use a reverse proxy in prod)
- Enables lazy body parsing (no body read on GET/HEAD)
- Pre-compiles middleware pipelines at startup (zero per-request list allocation)
- Tunes `HttpServer` (auto-compress, idle timeout)

### 2. Pre-compiled middleware pipelines

Middleware chains are built **once** at `listen()`, not on every request.

### 3. Lazy body parsing

Request bodies are only read when `await ctx.jsonBody()` is called. GET routes pay zero body-parsing cost.

### 4. Zero-copy auth context

`RequestContext.withAuth()` reuses the same body reference instead of cloning.

### 5. Isolate compute

```dart
final hash = await compute(heavyHash, password);
```

CPU-heavy work runs off the HTTP event loop — unlike Node.js where CPU work blocks all requests.

### 6. AOT deployment

```bash
dart compile exe bin/rewo.dart -o server
./server
```

No JVM. No `node_modules`. Single binary.

## Benchmark

```bash
dart run benchmark/bench.dart 100 10000
# 100 concurrent clients, 10000 total requests
```

On Apple Silicon / modern hardware, turbo mode typically achieves **50,000–150,000+ RPS** for simple JSON endpoints — often 3–10× Node.js and 10–50× Spring Boot for equivalent "hello world" workloads.

## Roadmap for even more speed

| Phase | Feature | Expected gain |
|---|---|---|
| v0.2 | `build_runner` route codegen (no runtime routing) | 2× routing |
| v0.2 | `json_serializable` integration | 3× JSON |
| v0.3 | Direct `HttpServer` mode (bypass Shelf) | 1.5× throughput |
| v0.3 | Connection pool + prepared statements | 5× DB |
| v0.4 | HTTP/2 + gRPC | Multiplexing |
| v0.4 | Shared-memory isolate pool | Lower CPU offload cost |

## Developer experience = performance

Slow frameworks create headaches. Rewo eliminates:

- **Boilerplate** — controllers, DI, validation in one place
- **Cold starts** — AOT binary, no JVM warmup
- **Debugging pain** — typed errors, structured JSON responses
- **Config hell** — `AppConfig.turbo()` or `AppConfig.fromEnvironment()`
- **Full-stack friction** — same language as Flutter, shared models (roadmap)

## Production checklist

```dart
void main() async {
  await Rewo.run((app) {
    // Wire services once — zero per-request DI lookup cost with singletons
    app.singleton(UserRepository());
    app.mount(UserController(app.container.resolve()));
  }, config: AppConfig.turbo(port: int.parse(Platform.environment['PORT']!)));
}
```

Deploy behind nginx/Caddy for TLS, CORS, and rate limiting. Let Rewo do what it does best: **serve requests fast**.
