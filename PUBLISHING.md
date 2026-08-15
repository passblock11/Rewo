# Publishing to pub.dev

## Prerequisites

1. Publisher account verified at [pub.dev/publishers/avantiinc.xyz](https://pub.dev/publishers/avantiinc.xyz)
2. GitHub repo live at `https://github.com/passblock11/Rewo`
3. Google account linked for pub.dev authentication
4. **Commit all changes** — pub warns when publishing from a dirty git state

## Pre-publish checklist

```bash
dart pub get
dart test --concurrency=1
dart pub publish --dry-run
```

Fix any errors before publishing. Warnings about analyzer info-level lints are OK.

## Publish

```bash
cd dart_backend_framework
git add -A && git commit -m "Release rewo v1.0.0"
dart pub publish
```

When prompted, confirm with `y`. On first publish, select publisher **avantiinc.xyz** if asked.

First publish may take a few minutes to appear on [pub.dev/packages/rewo](https://pub.dev/packages/rewo).

## After publishing

Users install with:

```bash
dart pub add rewo
# or
dart pub global activate rewo
rewo create my_api
```

Update `CreateProjectCommand.latestPublishedVersion` in `lib/src/cli/create_project.dart` whenever you bump the package version.

## Version bumps

1. Update `version` in `pubspec.yaml`
2. Add entry to `CHANGELOG.md`
3. Update `latestPublishedVersion` in `create_project.dart`
4. `dart pub publish`
