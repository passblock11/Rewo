# Publishing to pub.dev

## Prerequisites

1. Publisher account verified at [pub.dev/publishers/avantiinc.xyz](https://pub.dev/publishers/avantiinc.xyz) (optional; unverified upload also works)
2. GitHub repo live at [github.com/passblock11/Rewo](https://github.com/passblock11/Rewo)
3. Google account linked for pub.dev authentication (`dart pub login`)
4. **Commit all changes** — pub warns when publishing from a dirty git state

## Pre-publish checklist

```bash
dart pub get
dart analyze
dart pub global run pana --no-warning   # expect 160/160 pub points
dart pub publish --dry-run
```

Fix any errors before publishing. Info-level lints and formatting must be clean for a perfect static-analysis score.

## Publish

```bash
cd dart_backend_framework
git add -A && git commit -m "Release rewo v1.0.15"
git push origin main
dart pub publish --force
```

Use `--force` in CI or non-interactive shells; otherwise confirm with `y` when prompted.

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
3. Update version references in `README.md`, `GETTING_STARTED.md`, and `create_project.dart`
4. Run `dart format .` and verify pana score
5. `dart pub publish`

## pub.dev quality (v1.0.15+)

| Check | Requirement |
|-------|-------------|
| `description` | 60–180 characters |
| `homepage` | Must respond to HTTP HEAD (use GitHub repo URL) |
| Documentation | ≥20% of public API has dartdoc |
| Static analysis | No analyzer issues; run `dart format` on entire repo |

See the live score at [pub.dev/packages/rewo/score](https://pub.dev/packages/rewo/score).
