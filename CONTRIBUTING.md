# Contributing to DartLodge

Thanks for your interest! This is a solo-maintained, local-first Flutter
darts app. Issues, bug reports, and pull requests are welcome.

## Before you start

For non-trivial changes (new game modes, schema changes, architectural
refactors), **please open an issue first** so we can align on the approach
before you spend time coding. Small fixes (typos, obvious bugs, doc tweaks)
can go straight to a PR.

## Getting set up

```bash
git clone https://github.com/mathrb/dartlodge.git
cd dartlodge
flutter pub get
```

### Generate code

After any change to a `@freezed` or `@riverpod` annotated class:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Web (primary dev target)

A one-time asset setup is required:

```bash
# Compile the Drift web worker
dart compile js -O4 -o web/drift_worker.dart.js web/drift_worker.dart

# Download sqlite3.wasm matching pubspec.lock
grep -A7 "^  sqlite3:$" pubspec.lock | grep version
curl -L -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-v<VERSION>/sqlite3.wasm"
```

Then:

```bash
flutter run -d chrome
```

See [`docs/BUILD.md`](docs/BUILD.md) for full build troubleshooting.

### Android

`android/` is intentionally gitignored and scaffolded per machine:

```bash
flutter create --platforms=android --org app .
bash tools/post-create-android.sh
flutter build apk --debug
```

Requires JDK 17 and the Android SDK on `PATH`.

## Pull request flow

1. Fork the repository on GitHub.
2. Create a feature branch on your fork
   (`feat/short-name`, `fix/short-name`, `docs/short-name`, …).
3. Make your changes. Keep PRs focused on a single concern.
4. Run the local checks (see below) — CI runs them too.
5. Push to your fork and open a PR against `main`.
6. Reference any related issue (`Closes #123`) in the description.

## Required checks

PRs must pass these before merge. CI enforces them; please run them locally
first:

```bash
flutter analyze
flutter test
```

If `flutter test` reports failures, a focused run helps:

```bash
flutter test -r failures-only
```

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/).
Format: `<type>(<scope>): <subject>`.

Common types in use here:

- `feat(scope): …` — new feature
- `fix(scope): …` — bug fix
- `refactor(scope): …` — internal change, no behaviour shift
- `docs(scope): …` — documentation only
- `chore(scope): …` — build, tooling, dependency, repo housekeeping
- `test(scope): …` — adding or fixing tests

Examples from history:

```
feat(game): enforce per-leg round cap for X01 and Cricket (closes #71)
fix(history): show per-leg stats breakdown in Game Detail (closes #69)
chore(android): version-archived debug builds in releases/
```

## Architecture and code conventions

The project follows a strict feature-first Clean Architecture. The
authoritative rules live in:

- [`CLAUDE.md`](CLAUDE.md) — written for AI agents, but the most concise
  description of the architectural contract: layer rules, naming
  conventions, things you must not do.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — concise overview.
- [`docs/ARCHITECTURE_COMPLETE.md`](docs/ARCHITECTURE_COMPLETE.md) — full
  reference.
- [`docs/STATE_MANAGEMENT.md`](docs/STATE_MANAGEMENT.md) — Riverpod
  conventions.
- [`docs/games/`](docs/games/) — formal game rules / transition tables.

Read the relevant doc *before* writing code that touches that area. Pull
requests that violate the layer rules (e.g. importing `flutter` into a
`domain/` file, storing computed statistics, mutating state without
`copyWith`) will be asked to rework.

## Reporting bugs

Use the **bug report** issue template. Include:

- Steps to reproduce
- Expected vs actual behaviour
- Platform (iOS / Android / web)
- Flutter version (`flutter --version`)

## Reporting security vulnerabilities

**Do not open public issues for security bugs.** See
[`SECURITY.md`](SECURITY.md) for the private reporting flow.

## Code of conduct

By participating, you agree to abide by the
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

Contributions are licensed under the MIT License (see
[`LICENSE`](LICENSE)). By submitting a pull request, you agree to license
your contribution under the same terms.
