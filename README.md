# DartLodge

A **local-first**, open-source darts scoring and statistics app for Android and
iOS, built with Flutter. Plays offline by default; statistics are computed by
replaying the local game-event log so they always reflect the current data.

**Try it in your browser:** <https://mathrb.github.io/dartlodge/> — the latest
`main` is auto-deployed to GitHub Pages. Data is stored in your browser's
IndexedDB; clearing site data wipes your games.

## Game modes

- **X01** — 301 / 501 / 701 / 901 with configurable starting score, double-out / straight-out / master-out, leg/match formats
- **Cricket** — Standard, No-Score, Cut Throat, Random
- **Around the Clock** — single / double / triple variants
- **Bob's 27**, **Catch 40**, **Shanghai**
- **Checkout Practice** (170 finishing drill)

Per-player statistics (averages, checkout %, MPR, first-9 average, high-score
buckets) are tracked across all game types.

## Status

Local play, scoring, history, and statistics work end-to-end. The app is
**local-only today** — there is no remote backend, no account system, and no
cloud sync.

A self-hosted backend with computer-vision auto-scoring and remote multiplayer
is sketched in [`docs/BACKEND_INTEGRATION.md`](docs/BACKEND_INTEGRATION.md) as a
future direction; **it is not implemented**. Treat any backend / CV references
in design docs as roadmap, not shipping behaviour.

## Running

Flutter Web (Chrome) is the primary development target. iOS / Android builds
work but require platform-specific setup.

### Web (recommended for development)

A one-time asset setup is required after `flutter pub get`:

```bash
# Compile the Drift web worker
dart compile js -O4 -o web/drift_worker.dart.js web/drift_worker.dart

# Download sqlite3.wasm matching your pubspec.lock version
grep -A7 "^  sqlite3:$" pubspec.lock | grep version
curl -L -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<VERSION>/sqlite3.wasm"
```

Then:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome
# or for headless / remote access:
flutter run -d web-server --web-port 8087 --web-hostname 0.0.0.0
```

See [`docs/BUILD.md`](docs/BUILD.md) for full build troubleshooting.

### Android

The `android/` folder is intentionally gitignored and scaffolded per machine:

```bash
flutter create --platforms=android --org app .   # one-time, after fresh clone
bash tools/post-create-android.sh                 # override applicationId to app.dartlodge
flutter build apk --debug                         # or --release
```

Requires JDK 17 and the Android SDK on `PATH`. See `tools/release-debug.sh` for
the local sideload flow.

CI also produces release APKs via `.github/workflows/build-apk.yml`.

### iOS

Standard Flutter iOS workflow. Open `ios/Runner.xcworkspace` in Xcode and run on
a simulator or device after `flutter pub get`.

## Tests

```bash
flutter test                    # full suite
flutter test -r failures-only   # errors only
flutter analyze                 # static analysis
```

## Architecture

Feature-first Clean Architecture with strict layer boundaries.

- **Frontend (Flutter):** Riverpod (`@riverpod` codegen) for state, Freezed for
  immutable models, GoRouter for navigation.
- **Persistence:** SQLite via `sqflite` on mobile, `drift` (sqlite3 WASM) on
  web. Repository abstraction selects the backend in
  `lib/core/persistence/database_provider.dart`.
- **Game logic:** Every change to game state is appended to `game_events` as a
  typed event. Statistics are pure projections — never stored.
- **Crash reporting:** Sentry, opt-in via `--dart-define=SENTRY_DSN=<dsn>` at
  build time.

Detailed references:
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — concise overview
- [`docs/ARCHITECTURE_COMPLETE.md`](docs/ARCHITECTURE_COMPLETE.md) — full reference
- [`docs/DATABASE_DDL.md`](docs/DATABASE_DDL.md) — schema
- [`docs/STATE_MANAGEMENT.md`](docs/STATE_MANAGEMENT.md) — Riverpod conventions
- [`docs/games/`](docs/games/) — formal scoring rules and transition tables

## Contributing

Issues and PRs welcome. Before opening a PR, run `flutter test` and
`flutter analyze`.

`CLAUDE.md` is a behaviour contract for AI coding agents (Claude Code etc.) and
not required reading for human contributors — but it does mirror the
architecture rules below, so it's a fast way to learn the conventions.

## License

MIT — see [`LICENSE`](LICENSE).
