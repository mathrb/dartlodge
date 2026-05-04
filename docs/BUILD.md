# Build Guide

## Prerequisites

- Flutter SDK (3.x or later) with web support enabled
- Dart SDK (comes with Flutter)
- Python 3 (for local web serving)

```bash
flutter config --enable-web
flutter pub get
```

After any change to a `@freezed` class or `@riverpod` provider, regenerate code before building:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Web

Flutter Web is the primary development and debug target. Game logic and UI behave identically to mobile; native-only features (camera, SQLite) are stubbed on web. The data layer uses Drift with IndexedDB via SQLite WASM instead of sqflite.

### One-time web asset setup

`web/` is gitignored, so a fresh clone has no `web/` directory at all. Scaffold it once per machine, then build the two assets that `flutter build web` does **not** produce automatically. Once present in `web/`, the build copies them into `build/web/` automatically.

#### 0. Scaffold `web/` (fresh clone only)

```bash
flutter create --platforms=web .                  # creates web/index.html, manifest, icons
printf "import 'package:drift/wasm.dart';\n\nvoid main() {\n  WasmDatabase.workerMainForOpen();\n}\n" > web/drift_worker.dart
```

#### 1. Compile the Drift web worker

```bash
dart compile js -O4 -o web/drift_worker.dart.js web/drift_worker.dart
```

You only need to recompile `web/drift_worker.dart` when the `drift` package version changes.

#### 2. Download sqlite3.wasm

The WASM binary must match the `sqlite3` version resolved in `pubspec.lock`. Check the version first:

```bash
grep -A7 "^  sqlite3:$" pubspec.lock | grep version
```

Then download the matching release from the sqlite3.dart GitHub releases:

```bash
curl -L -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-v<VERSION>/sqlite3.wasm"
```

Example for version `2.9.4`:

```bash
curl -L -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-v2.9.4/sqlite3.wasm"
```

Repeat this step whenever `sqlite3` is upgraded in `pubspec.lock`.

### Building

```bash
flutter build web
```

Both `drift_worker.dart.js` and `sqlite3.wasm` will be copied into `build/web/` as part of the build.

### Serving locally

Use Flutter's built-in web server to serve the app with correct MIME types:

```bash
flutter run -d web-server --web-port 8087 --web-hostname 0.0.0.0
```

This serves the app from the `build/web` directory with proper `.wasm` MIME type handling and binds to `0.0.0.0` so the app is reachable from other machines on the network.

Then open `http://<machine-ip>:8087` in any browser.

### Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `TypeError: Response has unsupported MIME type 'text/html' expected 'application/wasm'` | Serving with plain `python3 -m http.server` | Use `flutter run -d web-server` instead |
| `GET /sqlite3.wasm 404` | `web/sqlite3.wasm` not downloaded | Run the `curl` download step above |
| `GET /drift_worker.dart.js 404` | Worker not compiled | Run `dart compile js` step above |
| `ProviderException: Tried to use a provider that is in error state` | Any of the above asset errors cause the database provider to fail | Fix the underlying 404 first |
| Blank page, no error shown | 0-byte or invalid font files declared in `pubspec.yaml` block Flutter's first frame | Remove unused font declarations; never commit empty placeholder font files |
| Blank page, no error shown | CanvasKit loaded from gstatic CDN, blocked by `Cross-Origin-Embedder-Policy: require-corp` | `web/flutter_bootstrap.js` sets `canvasKitBaseUrl: "canvaskit/"` to use the locally bundled copy |
| Spinner never resolves / database never opens | `WasmDatabase.open()` starts a dedicated web worker and waits for its handshake. The handshake hangs permanently in Firefox and Edge (even without `crossOriginIsolated`). | `database_factory_web.dart` uses the `WasmDatabase` factory constructor instead, loading SQLite WASM directly on the main thread. `IndexedDbFileSystem` provides persistence. The `drift_worker.dart.js` file and `sqlite3.wasm` are still required in `web/` but the worker is not used. |

---

## Mobile (Android / iOS)

```bash
flutter run                # connected device or emulator
flutter build apk          # Android release APK
flutter build ios          # iOS release (requires macOS + Xcode)
```

Mobile uses sqflite directly; no web asset setup is needed.

---

## Running tests

```bash
flutter test                                          # all tests
flutter test test/contracts/                          # repository contract tests only
flutter test test/features/players/                  # single feature
```
