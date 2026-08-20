# Rewo Examples

Runnable examples live in this folder. Start with `example/main.dart`.

> **Package:** [pub.dev/packages/rewo](https://pub.dev/packages/rewo) · **Version:** `^1.0.15` · [Framework repo](https://github.com/passblock11/Rewo)

## Run the demo API

```bash
cd example
dart pub get
dart run main.dart
```

Then open: http://localhost:8080

## What each file shows

| File | Feature |
|------|---------|
| `main.dart` | Minimal Rewo app with routes |
| `tasks_api/main.dart` | Full CRUD module pattern |
| `generated_user_controller.dart` | Annotation-based routes (codegen) |

For **20 copy-paste examples** (auth, validation, database, cache, jobs, tests, deploy), see the main [README](../README.md#-20-code-examples-copy--paste).

## API reference

Public types such as [`Rewo`](https://pub.dev/documentation/rewo/latest/rewo/Rewo-class.html), [`RewoModule`](https://pub.dev/documentation/rewo/latest/rewo/RewoModule-class.html), and [`RewoBootstrap`](https://pub.dev/documentation/rewo/latest/rewo/RewoBootstrap-class.html) are documented on pub.dev after each release.
