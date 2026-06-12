# CLAUDE.md

This file is the authoritative behavioural contract for AI coding agents on this project. Read it fully before writing, editing, or deleting any code.

---

## Project Overview

A local-first, open-source darts scoring app for Android and iOS built with Flutter. Supports X01, Cricket, Around the Clock, Bob's 27, Catch 40, Shanghai, and Checkout Practice. Players can track statistics across all game types.

**Flutter Web is the development/debug target.** Run `flutter run -d chrome`. All game logic and UI behaves identically to mobile; native-only features (camera, SQLite) are abstracted via the Drift factory.

---

## Running the Project

```bash
flutter pub get
dart run build_runner build  # after any @freezed or @riverpod change (the legacy `--delete-conflicting-outputs` flag is now a silent no-op)
flutter run -d chrome
flutter run -d web-server --web-port 8087 --web-hostname 0.0.0.0  # headless/remote server
flutter test
flutter test -r failures-only  # errors only
flutter analyze                 # static analysis
```

**Mobile debugging:** No USB connection available. APKs can be built locally (see "Building Android APKs" below) or via GitHub Actions CI. To debug mobile-only issues, surface errors in the UI (e.g. timeouts with step labels) rather than relying on `flutter logs` or console output.

### Building Android APKs

`android/` is gitignored. Each dev scaffolds it once per machine:

```bash
flutter create --platforms=android --org app .   # one-time, after fresh clone or rm -rf android/
bash tools/post-create-android.sh                 # override applicationId to app.dartlodge + pin minSdk 23
flutter build apk --debug                         # or --release
```

Requires JDK 17 + Android SDK on `PATH` (`JAVA_HOME`, `ANDROID_HOME`). Non-interactive shells (incl. Bash tool calls) don't load `~/.bashrc` — use `tools/release-debug.sh` or prepend env exports inline. CI also produces release APKs.

**Sideloading to a phone:** `tools/release-debug.sh` bumps `versionCode`, rebuilds, and copies the APK to `releases/dartlodge-debug-<version>.apk` (folder gitignored). Serve `releases/` by whichever method (Python http.server, nginx, docker — devs choose). In-place upgrades require both an increased `versionCode` AND a matching signing key; debug builds on the same machine share `~/.android/debug.keystore` so upgrades just work; mixing local debug ↔ CI release ↔ another machine forces uninstall. Android identifies apps by `applicationId` + signing key, NOT by APK filename — different filenames with the same identity all upgrade the same installed app.

---

## Spec Document Index

Check the relevant spec before implementing. These are the source of truth.

| What you are building | Read this |
|---|---|
| Database schema and indexes | `docs/DATABASE_DDL.md` |
| Repository method signatures and exceptions | `docs/REPOSITORY_INTERFACES.md` |
| Game event types and payloads | `docs/GAME-EVENT-SPECIFICATIONS.md` |
| X01 scoring rules and transitions | `docs/games/x01.transitions.md` |
| Cricket scoring rules and transitions | `docs/games/cricket.transitions.md` |
| Around the Clock transitions | `docs/games/around-the-clock.md` |
| 170 Checkout Practice rules and transitions | `docs/games/checkout-practice.md` |
| Statistics definitions and projections | `docs/statistics/x01.projections.md`, `docs/statistics/statistics.architecture.md` |
| Projection test matrix | `docs/statistics/projection-test-matrix.md` |
| Riverpod providers, state patterns | `docs/STATE_MANAGEMENT.md` |
| Navigation flows and screen index | `docs/UI_SCREEN_FLOWS_V3_FINAL.md` |
| Design tokens, colors, typography, spacing | `docs/design/DESIGN_SYSTEM.md` |
| Data entities and field names | `docs/DATA.md` |
| Backend REST endpoints (optional) | `docs/API_CONTRACT.md` |
| Backend integration patterns (optional) | `docs/BACKEND_INTEGRATION.md` |
| Branching, CI, releases, signing | `docs/RELEASES.md` |
| Architecture diagrams | `docs/ARCHITECTURE_DIAGRAMS.md` |
| Concise architecture overview | `docs/ARCHITECTURE.md` |
| Full architecture reference | `docs/ARCHITECTURE_COMPLETE.md` |

### Web — one-time asset setup (required before first `flutter run`)

`web/` is gitignored (like `android/`). Each dev scaffolds it once per machine:

```bash
flutter create --platforms=web .                  # scaffolds web/ (index.html, manifest, icons)
printf "import 'package:drift/wasm.dart';\n\nvoid main() {\n  WasmDatabase.workerMainForOpen();\n}\n" > web/drift_worker.dart
```

Then build the two assets the Flutter web build does NOT produce automatically:

```bash
# 1. Compile the Drift web worker (only needed when drift version changes)
dart compile js -O4 -o web/drift_worker.dart.js web/drift_worker.dart

# 2. Download sqlite3.wasm matching pubspec.lock version
grep -A7 "^  sqlite3:$" pubspec.lock | grep version   # check version
curl -L -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<VERSION>/sqlite3.wasm"
```

Missing any of these files causes a silent 404 that breaks the database provider. See `docs/BUILD.md` for full troubleshooting.

---

## Architecture Constraints

These are hard constraints. Breaking them requires explicit human approval.

### 1. Feature-First Clean Architecture

```
lib/features/<feature>/
  domain/       ← pure Dart only — NO Flutter, NO drift, NO http
  data/         ← implements domain interfaces; contains drift code
  presentation/ ← Flutter widgets and Riverpod providers
```

- `domain/` has zero imports of `package:flutter`, `package:drift`, or `package:dio`.
- No feature imports another feature directly. Cross-feature communication via `core/` providers or shared domain entities only. Concrete runtime-wiring seam: a port/holder provider in `core/` (the producer feature `bind`s/`bump`s it; the consumer `watch`/`listen`s it); register the implementation at the composition root (`main.dart` `ProviderScope` override or `app_router`), which alone may import feature widgets. (Examples: `DartInputSink`, `boardOverlayBuilder`, `ActiveTurnSignal`.)
- `core/` contains no domain logic — only infrastructure (database wiring, error types, shared utilities).

### 2. Dependency Direction

```
UI widgets → Riverpod Notifiers → Use Cases → Repository Interfaces ← Repository Implementations
```

No widget reads a repository directly. No use case touches Flutter.

### 3. Games Are Event Streams

Every change to game state must be expressed as a `GameEvent` appended to `game_events`. See `docs/GAME-EVENT-SPECIFICATIONS.md`.

> **If it changes the game, it must be an event. No exceptions.**

### 4. Statistics Are Projections — Never Stored

Statistics are computed by replaying `game_events`. Never write code that stores a computed average, checkout percentage, or win rate in the database.

### 5. Immutable State

All state classes use `freezed`. Never mutate state in place. Always use `copyWith`.

---

## Technology Decisions

| Concern | Decision |
|---|---|
| State management | Riverpod with code generation (`@riverpod`, `riverpod_generator`) |
| Immutable state / entities | `freezed` |
| Cross-platform database | `drift` with Drift factory pattern (`lib/core/persistence/drift/`) |
| HTTP client (backend, optional) | `dio` |
| Secure token storage | `flutter_secure_storage` |
| Navigation | `go_router` |
| UUID generation | `uuid` |
| Code generation runner | `build_runner` |
| Crash reporting | `sentry_flutter` (initialized in `lib/main.dart`; do not remove `SentryFlutter.init`) |

Platform selection (native SQLite vs WASM) happens once in the Drift factory. Everywhere else sees only the repository interface.

**Platform-only plugins (camera, ultralytics_yolo, etc.):** put the impl behind a `domain` interface and conditionally import it — `import 'x_stub.dart' if (dart.library.io) 'x_io.dart';` — with a web no-op stub. Verify no `lib/` file imports the `_io` impl unconditionally (`grep`) or `flutter run -d chrome` breaks. Native Android/iOS permissions a plugin needs are merged from the plugin's own manifest (no edit to the gitignored `android/`); iOS `Info.plist` strings are added per-machine.

---

## Riverpod Conventions

Follow `docs/STATE_MANAGEMENT.md` exactly. Rules that are easiest to violate:
- Provider names strip the `Notifier` suffix: `FooNotifier` → `fooProvider`; family variant `FooNotifier.build(String id)` → `fooProvider('id')`.
- The same suffix stripping applies to **function-style** providers: `@riverpod Foo fooNotifier(Ref ref)` generates `fooProvider`, not `fooNotifierProvider`. Don't reach for `xxxNotifierProvider` — grep the `.g.dart` if unsure.
- Use `ref.watch()` inside `build()`. Use `ref.read()` only in event handlers and notifier methods.
- Never touch `ref` in `State.dispose()` (unsafe once deactivated) — capture the notifier in a field during `initState` if you need it later. Never *mutate* a provider during `build` / the `initState` body / `dispose` (→ "modified during build" / "ref unsafe" errors); do binds/bumps from an `addPostFrameCallback` or an event handler. `ref.listen()` belongs in `build()`.
- Handle all three `AsyncValue` states in every widget: `data`, `loading`, `error`. Never use `.value!` without fallbacks.
- Use `AsyncValue.value` (returns `T?`) — not `valueOrNull` — in Riverpod 3.x.

---

## File Conventions

| What | Where |
|---|---|
| New use case | `lib/features/<feature>/domain/usecases/<name>_use_case.dart` |
| New provider | `lib/features/<feature>/presentation/providers/<name>_provider.dart` |
| New state class | `lib/features/<feature>/presentation/state/<name>_state.dart` (always `@freezed`) |
| New screen | `lib/features/<feature>/presentation/pages/<name>_page.dart` |
| New widget | `lib/features/<feature>/presentation/widgets/<name>_widget.dart` |
| New repository impl | `lib/features/<feature>/data/repositories/<name>_repository_impl.dart` |

State classes always include `factory <ClassName>.initial()`. Screens are `ConsumerWidget` or `ConsumerStatefulWidget`. Pure UI widgets with no providers are `StatelessWidget`.

---

## Segment Format Convention

Used in `dart_throws.segment`, `DartThrown` event payloads, and all engine logic. Never deviate.

| Hit | String |
|---|---|
| Single 20 | `'20'` |
| Double 20 | `'D20'` |
| Triple 20 | `'T20'` |
| Single bull | `'SB'` |
| Double bull | `'DB'` |
| Miss | `'MISS'` |

---

## Key Rules

**GameConfig dispatch:** Use `maybeMap` (not `maybeWhen`) — callbacks receive typed subclass instances: `config.maybeMap(x01: (c) => c.startingScore, orElse: () => '')`. Requires explicit `import 'game_config.dart'`; not available via transitive import.

**Repository exceptions:** All exceptions extend `RepositoryException` (`lib/core/error/repository_exception.dart`). Never throw raw `Exception` from a repository implementation.

**Contract tests:** Every repository implementation must pass the shared contract tests in `test/contracts/`. Never skip or comment out tests to make CI pass.

**Database:** drift on every platform (`NativeDatabase.createInBackground` on mobile/desktop, `WasmDatabase` over IndexedDB on web). Schema lives in `lib/core/persistence/drift/database.dart`; `databaseVersion = 1`. `PRAGMA foreign_keys = ON` is set in `MigrationStrategy.beforeOpen`. Completed games are read-only — enforced in application logic, not triggers. The canonical SQL DDL reference is `docs/DATABASE_DDL.md`. After editing drift table classes, run `dart run build_runner build`.

**Drift foreign keys:** Plain `text()()` emits NO foreign key clause — you must call `.references(Type, #col, onDelete: KeyAction.{cascade|restrict|setNull})` explicitly. `PRAGMA foreign_keys = ON` is a no-op without `.references()`. When two columns in a table reference the same parent (e.g. `game_sessions.host_player_id` and `current_turn_player_id` both → `players`), add `@ReferenceName('xxx')` annotations to disambiguate manager-API helpers, or build_runner warns.

**Test database setup:** Drift tests use `AppDatabase(NativeDatabase.memory())` directly — see `test/drift_test_base.dart`. With FK enforcement active, fixtures must respect FK order: insert players before competitors, games before competitors/dart_throws/game_events, and use `playerRepo.createPlayer()` to seed referenced player IDs before any `createGame` call.

**Test game setup ordering:** Drift enforces read-only on completed games. In tests: create game with `isComplete: false` → insert darts/events → call `gameRepo.completeGame()`. Never set `isComplete: true` at creation if you need to insert data afterward.

**Statistics scope resets:** Turn resets on `TurnStarted`, Leg resets on `LegCompleted`, Match resets on `GameCompleted`. No other reset points.

**DartThrown payload keys:** `competitor_id`, `player_id`, `segment`, `multiplier`, `score`, `input_method` only (see `buildDartThrownEvent` in `lib/features/game/domain/usecases/game_use_case_helpers.dart`). No `turn_number`, no `dart_number` — reconstruct turn grouping via `TurnStarted`/`TurnEnded` event boundaries if needed.

**Computing stats over an event slice:** All projection wiring lives in `PlayerStatsAssembler` (`lib/features/statistics/domain/assemblers/`). Use the method that matches the scope: `fromEvents` (career), `gameStatsFromEvents` (per-game), `playerStatsForGameFromEvents` (per-player-per-game), `legCompetitorStatsFromEvents` (per-leg). Repos and use cases load events and delegate. If you need a new projection bundle, add it to the assembler — do not re-wire `ProjectionRunner` directly in repos or use cases. Snapshot keys: `x01_average`, `x01_checkout`, `x01_highest_checkout`, `x01.highScoreBuckets`, `cricket.mpt`, `cricket.markBuckets`, `cricket.firstNineMpr`. First-nine projections (`cricket.firstNineMpr`, X01 first-nine PPR) only count when `TurnStarted` events are present — fixtures emitting just `DartThrown`/`TurnEnded` silently produce null first-nine stats.

**`local_sequence` is per-game, not global:** every new game restarts `local_sequence` at 1, so multiple games' events share the same sequence range. Any query that loads events across multiple games MUST sort by `(game_id, local_sequence)` — sorting by `local_sequence` alone interleaves games and corrupts projection state across game boundaries. `ProjectionRunner.run()` enforces this internally; SQL queries feeding it should match.

**`GameStats.gameType` is load-bearing:** the post-game summary branches on `gameStats.gameType == GameType.cricket.name` to choose MPR vs PPR labels and rows. Every return path of `getGameStats` (including the empty-darts early return) must set it, in both repository implementations.

**Statistics loader vs computation:** Statistics computation lives in `PlayerStatsAssembler` (shared). The loader queries live in `lib/core/persistence/drift/repositories/statistics_repository_drift.dart` — load events + dart_throws, then delegate to the assembler. When changing how stats are computed, update only the assembler.

**Watchable queries:** drift's per-query reactivity is automatic — `select(...).watch()` re-fires whenever drift sees a write to one of the referenced tables. No notify-after-write protocol to remember.

**Repository contract tests:** `runHybridTests` (`test/hybrid_test_runner.dart`) spins up a fresh in-memory `AppDatabase` per test against the shared `*_contract.dart` suites. The "hybrid" name is vestigial from the dual-backend era (issue #112) — there is now a single backend.

**Adding a cricket variant:** four coordinated edits — (1) `_cricketVariants()` entry in `variant_selection_page.dart`, (2) a `cricketXxxRules` content block in `rules/content/cricket_rules.dart`, (3) the slug → rules entry in `kGameRules` (`rules_registry.dart`), (4) the slug in `expectedSlugs` in `rules_registry_test.dart` (the registry test fails CI if you miss this). The info-icon shows "Rules unavailable." silently if (3) is missing — only the test enforces coverage.

**Adding a "right-after-TurnStarted" cricket event:** every site that emits the event (`CreateGameUseCase`, `ProcessCricketDartUseCase`, the three TurnStarted emission sites in `active_cricket_game_provider.dart`) must emit it; AND `UndoLastDartUseCase` must add the event type to BOTH its supersession-collection loop and its replay-skip branch — otherwise a turn-boundary undo replays the cancelled turn's event and corrupts state. Same applies to projections: add to `consumedEventTypes` on every cricket projection (or extend the shared `CricketTargetsTracker` mixin) AND the `legHistoryFromEvents` inline tracker in `PlayerStatsAssembler`.

**RNG in use cases:** event-emitting use cases that need randomness (e.g. `CreateGameUseCase`, `ProcessCricketDartUseCase` for `CrazyTargetsRolled`) accept an optional `math.Random?` constructor parameter that defaults to `math.Random()` in production. Tests inject a seeded `math.Random(seed)` for determinism. RNG runs **once at emission**, the value lands in the event payload, and `engine.apply()` is pure — replay never re-rolls.

**Cricket scoring × target mode are orthogonal axes:** `CricketGameConfig` exposes `scoring` ∈ {`standard`, `cut-throat`, `no-score`} and `targetMode` ∈ {`fixed`, `random`, `crazy`}; `GameState` mirrors them as `cricketScoring`/`cricketTargetMode` plus a dynamic `cricketTargets: List<int>` (+ implicit Bull) and `cricketLockedTargets: Set<int>`. The engine reads the target set from state — never from a hardcoded `[15..20]` constant — so any target mode is accepted by the same code path. Legacy configs carrying a single `variant` string deserialise to `{scoring: <that>, targetMode: 'fixed'}` via a `readValue` mapping at JSON read time; **no event migration**, historical replay stays correct. Stats loader buckets cricket games by `targetMode` (today only `fixed` is wired; `random`/`crazy` cohorts arrive with PRs #237/#238). See `docs/plans/2026-05-19-cricket-target-modes-design.md`.

**Cricket mark-bucket field overload:** `CompetitorStats.{five..nine}MarkTurns` are populated as **exact-N** counts by `getGameStats` and `ComputeLegStatsUseCase` (read from the `*Exact` snapshot keys) but as **≥-N** counts by `getPlayerStats` (read from the `*MarkTurns` keys). Same field, different cohorts by call path.

**Statistics scope is required:** `getPlayerStats` and `watchPlayerStats` take `required GameType gameType`. PPR-shaped fields are X01-only and cricket fields are cricket-only — a single call cannot mix types coherently. The player-picker AVG badge consumes `playerStatsProvider`, which passes `GameType.x01`.

**Notifier tests:** Use `ProviderContainer` with `overrides`. Never instantiate notifiers directly. Use `ProviderScope` with `overrides` for widget tests.

**Widget test finders:** `StatFormatter.fmtDouble` strips trailing zeros — e.g. `170.0` → `'170'`, which collides with raw `int` values rendered the same way. Prefer `findsNWidgets(n)` or more specific finders (`find.descendant`) over `findsOneWidget` when stat rows may share literals.

**Colors:** Always use themed color tokens from `docs/design/DESIGN_SYSTEM.md`. Never hardcode color values directly in widgets.

**DESIGN_SYSTEM specifics the review repeatedly catches:** inactive/opponent score numerals use `cs.onSurfaceVariant` (active = `onSurface`, practice target = `primary`); `label-sm` over-line above a hero numeral uses `primaryFixed` (not `onSurfaceVariant`); game-board player names = `labelMedium` ALL-CAPS `letterSpacing: 1.2`; score numerals never scale/wrap — constrain the container, never wrap a score in `FittedBox(scaleDown)`.

**Number formatting:** Use `StatFormatter` (`lib/core/utils/stat_formatter.dart`) for all statistics display — `fmtDouble`, `fmtPct`, `fmtPerLeg`. Never use inline `toStringAsFixed()` in statistics UI. `test.yml`'s "Stats UI formatter gate" greps `lib/features/*/presentation/` for `toStringAsFixed` and fails CI on ANY match (not just stats) — route every number through `StatFormatter` (it wraps `toStringAsFixed` in `core/utils`, outside the gate), even non-stat labels like a `2.5×` zoom readout.

**Auto-scorer camera preview:** `CameraPreview` handles device orientation itself (its own internal `AspectRatio` + `RotatedBox`; `controller.value.aspectRatio` is ALWAYS the landscape sensor ratio). Do NOT wrap it in your own `Center > AspectRatio(controller.value.aspectRatio)` — on a portrait screen that shrinks the preview to a letterboxed band (this is what #408 did). Detection runs on `takePicture()`'s raw sensor frame (landscape buffer), **served as-is — the app does not rotate it**. The model needs the board roughly upright, so a portrait-held phone (board sideways in the landscape buffer) detects poorly until the model is trained for that orientation (#393); the app-side fix is **not** rotation (a rotation auto-detect was tried and dropped — it can't tell upright from upside-down). Preview-display orientation and detection-input orientation are independent — don't conflate them.

**Auto-scorer camera (YOLOView path):** the in-game preview + aim view run a live `YOLOView` with native streaming inference (`onResult` ~3 Hz, `inferenceFrequency: 3`) — NOT a `takePicture`/`_busy` polling loop (`_detectTick`/`_tick`/`_busy` are gone). Frame stills come from `YOLOViewController.capturePhoto(withOverlays: false)`. The auto/fire-and-forget callers (`_captureEmitted`/`_captureCorrected`) run in a `try/catch` (a dropped capture must never disrupt scoring) with no busy guard. The user-triggered manual buttons (`_manualCapture`, the aim view's `_capture`) instead `tapToFocus(0.5,0.5)` + await `kAutoScorerFocusSettle` before the shot (capturePhoto does NOT autofocus, so a manual still is otherwise blurry) and hold a `_capturing` flag that disables the button while in flight (debounces double-taps); that flag does NOT gate the auto callers, which can still interleave. Every manual path also gates on `dataCollectionEnabledProvider` before persisting (like the auto paths). The legacy predict path (`AutoScorerSession.onFrame`/`detectOnly` → `DartDetector`) still exists but isn't the in-game path.

**Auto-scorer capture sidecar is a probe contract:** the `CaptureRecord` JSON shape (`capture_record.dart`) is the `ddp-preprocess` ingest contract. Adding a key = coordinated edit: `toJson` + `fromJson` (with a backward-compat default for old sidecars) + `withCorrection` (preserve it) + the `unorderedEquals` key-set test in `capture_record_test.dart` (fails CI otherwise). Probe-side consumption needs a reciprocal change in the probe repo.

**Capture writes respect the opt-in:** any path that persists a training capture (emission, manual button, or correction-driven) MUST gate on `dataCollectionEnabledProvider` — the store is non-null even when the toggle is off, so an ungated write silently hoards frames the user opted out of.

**`DartInputSink` carries `submitDart` AND `advanceTurn`:** the auto-scorer→game port has two methods. `advanceTurn()` backs the opt-in "auto-advance when board is cleared" feature (`autoAdvanceOnClearEnabledProvider`, default off): the YOLOView preview calls it on a board-clear (`TrackerPhase.rebaselined`) **guarded by `_sawDartsThisTurn`** — `rebaselined` also fires on a transform-only empty board at turn start, so without that guard it skips players who haven't thrown. Each board's sink impl must **no-op when a modal/celebration is pending or the game is complete** (X01's `advanceTurn` dismisses the bust/leg modals, so without the guard an auto-advance would blow past an unacknowledged win; cricket's `nextPlayer` doesn't dismiss them — the guard is the sole safety net) and must bump `activeTurnSignal` like the manual NEXT button. Pure decision lives in `shouldAutoAdvance` (`domain/tracking/auto_advance.dart`); the widget trigger is device-only.

**Round semantics:** A "round" is one full rotation where ALL competitors throw. `totalRounds` is the correct field name. Do not use `maxRounds` or count per-competitor turns or individual dart throws as rounds.

**Per-leg round cap:** X01 and Cricket enforce a round cap per leg (see `GameConfigurationConstants` and engine logic). When the cap is hit with no winner, the leg is decided by current standing — do not extend rounds silently. Both engines and any UI showing round progress must respect this.

**Spec edits:** When asked to update a spec or document, only edit that document — do not modify code files unless explicitly asked.

**UI refactors:** After any widget redesign or UI refactor, update the corresponding test expectations in the same session before committing.

**Navigation — `context.go()` vs `context.push()`:** `context.go()` REPLACES the entire route stack — Android's physical back button then has nothing to pop and exits the app. Use `context.push()` for any forward navigation that should be back-poppable (Home → Stats/History/Players/Settings, list → detail, etc.). Reserve `context.go()` for intentional stack resets: game completion → home, post-deletion redirects, deep-link landing pages. If a screen MUST be reached via `go()` (e.g. the variant selection flow), wrap its body in `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) context.go(GameRoutes.home); })` like `variant_selection_page.dart` does, so the Android back button still works.

**Branch naming:** All work goes on a branch off `main` named `<type>/<slug>` where type ∈ {`feat`, `fix`, `docs`, `chore`, `hotfix`}. Slugs are short and dash-separated (`feat/cricket-stats-export`). Never commit directly to `main`.

**PR titles:** Soft Conventional Commits — `feat(cricket): ...`, `fix(x01): ...`, `docs: ...`, `chore(deps): ...`. PR titles become squash-merge commit messages and feed GitHub's auto-generated release notes.

**Squash-merge only:** PRs are always squash-merged. Don't rebase-merge or merge-commit. Branches auto-delete after merge.

**PR reviews:** every PR — including small or "obvious" ones — gets reviewed via the `code-review:code-review` skill before merge. Self-review via `gh pr diff` is not sufficient. The skill runs an 8-step pipeline (eligibility → CLAUDE.md fetch → summary → 5 parallel Sonnet reviews covering CLAUDE.md compliance / bugs / git history / prior PR comments / in-code comments → confidence scoring at 0/25/50/75/100 → filter ≥80 → post). Issues that score below 80 should still be fixed by the author if real (just not posted as inline comments). CI must be green before merging.

**Releases are tag-driven:** Pushing a tag `vX.Y.Z` (or `vX.Y.Z-rcN` for pre-release) triggers `release.yml`, which builds and publishes the signed APK to GitHub Releases. Every merge to `main` also auto-tags `v<pubspec-version>-rc<N>` (N = next-available rc number) via `auto-rc.yml` and publishes a pre-release — devs do not push RC tags manually. Never manually upload an APK to a release. Tags must point to a commit that's reachable from `main` (`release.yml` enforces this). Full process in `docs/RELEASES.md`.

**Version bumps:** When asked to bump the version, edit only `pubspec.yaml`'s `version:` field (e.g. `1.0.0+0` → `1.1.0+0`) in a `chore: bump version to X.Y.Z` PR. The `+N` suffix is a placeholder; CI overrides `versionCode` from `github.run_number` on tag builds.

**CI does not run `build_runner`:** Generated `.g.dart` / `.freezed.dart` / `.mocks.dart` files are committed. After editing any `@freezed`, `@riverpod`, or `@GenerateMocks` annotation, regenerate locally and commit the result in the same PR — CI will fail otherwise.

**Analyze in CI:** `test.yml` runs `flutter analyze --no-fatal-infos`. Warnings block CI; infos are advisory. ~190 info-level lints are tolerated (deprecated `overrideWith`, `curly_braces_in_flow_control_structures`, `avoid_print` in test infra). Cleaning them is optional polish — never tighten this flag without raising it. **Always run project-wide `flutter analyze --no-fatal-infos` before pushing — `flutter analyze <path>` may not surface unused-import / unused-variable warnings that the project-wide variant catches.** For a fast pre-push check that filters out the info noise, grep: `flutter analyze --no-fatal-infos 2>&1 | grep -E '^\s*(warning|error) •'` — empty output means CI-clean. Run this **after** your last file change, not just once early in the session: warnings introduced by later test/import edits will otherwise slip through.

**"Unused" in `lib/` may be forgotten wiring:** When `flutter analyze` flags an unused field, parameter, or import in `lib/`, check whether it represents incomplete wiring (a setter that updates a field nothing reads, a constructor param never used in the body) before deleting. If unsure, ask — silent deletion can lock in a no-op user-facing control as the intended behavior.

**Camera/device-only changes aren't widget-testable** (no `CameraPreview` in `flutter test`, no web camera) — verify on a real device. PR builds upload the debug APK as a 7-day artifact (`build-apk.yml`); download it from the PR's *Build APK* Actions run (or `gh run download <id>`) to sideload without merging. Different signing key than local/release builds → uninstall the existing app first.

**Camera-first board layout + tests:** boards branch on `cameraFirst = autoScoringOn && cameraPreview != null` — the camera-first column lives behind `if (cameraFirst)` (manual layout in `else`), `GameStatusBarWidget(showDarts: false)` moves the darts to `ProminentDartBandWidget`, and the primary state uses `HeroMetricWidget` / per-game strips (`X01OtherPlayersStripWidget`, `CricketMarksStripWidget`, `PracticePlayersStripWidget`; `PracticeTargetDisplayWidget(heroSize: true)`). Inside `if (cameraFirst)`, Dart promotes `cameraPreview` non-null — call it WITHOUT `!` (else `unnecessary_non_null_assertion`). Unlike the live `CameraPreview`, the camera-first **chrome IS widget-testable**: override `autoScoringEnabledProvider` with a fake whose `build()` returns true AND `boardCameraPreviewBuilderProvider.overrideWithValue((c, id) => const SizedBox(key: ValueKey('camera-stub')))`. Default board tests run in manual mode (neither overridden → `cameraFirst` false).

**X01 strategy values are lowercase short forms:** `'straight'` / `'double'` / `'master'` for both `inStrategy` and `outStrategy` (`GameState` defaults). Engines and projections compare against these literals; UI labels (e.g. "Double Out") live in a display mapper only. Never store the friendly labels.

**`DartCorrected` payload key is `original_event_id`:** a string referencing the corrected `DartThrown.eventId`. Any replay-aware code path (`UndoLastDartUseCase`, `PlayerStatsAssembler.fromEvents`) must collect these and skip the originals.

**Projection snapshots are two-level:** top level keyed by `engine.descriptor.id` (e.g. `'x01.doubleOut'`), inner map keyed by field name (e.g. `'doubleOutSuccessRate'`). Wiring a new engine into `PlayerStatsAssembler.fromEvents` means reading at both levels — running an engine without reading its snapshot is a silent no-op.

**`.flutter-plugins-dependencies` and `pubspec.lock`** regenerate on every `flutter pub get` / `flutter run` / `build_runner build`; never commit either unless the dep set actually changed. Both commonly show `M` in `git status` — `git checkout pubspec.lock .flutter-plugins-dependencies` before staging to keep PR diffs clean.

**Stage explicit paths — never `git add -A` / `git add .`:** the working tree carries many untracked scratch files (`*.png` / `*.yml` / exported capture `*.jpg` at the repo root, `e2e/node_modules`, `.playwright-*`). A blanket add stages hundreds of junk files — always `git add <specific paths>`.

**Sentry error handlers:** `SentryFlutter.init` auto-installs `FlutterError.onError` and `PlatformDispatcher.instance.onError` via `FlutterErrorIntegration` and `OnErrorIntegration` (sentry_flutter ≥ ~7.x; current pin `^9.16.1`). Do NOT add manual handlers in `main.dart` — they would override Sentry's wiring and silence the crash pipeline. See the `lib/main.dart` header comment.

**`endGame()` / `endDrill()` write `is_complete=true` to the DB but do NOT mutate `state.value.gameState.isComplete`** — the post-game-navigation listener (`practice_board_page` / `x01_board_page` etc.) watches that flag and would otherwise route every menu-driven exit through post-game instead of home. When you need an authoritative "is this game complete?" signal outside the active-game provider (e.g. from the router's `onExit`), read it from `GameRepository.getGame(id)`, not the notifier state. See `app_router.dart`'s `_gameIsComplete` helper for the pattern.

**Cricket variant labels live in three places and must stay aligned:** `variant_selection_page.dart` (picker — Title Case), `cricket_board_page.dart` (in-game header — Title Case), `game_summary_card_widget.dart` (history list — lowercase by design). When you change one site's `scoring × targetMode` label formula, audit the other two. The shared rule: fixed → `scoring` alone; random/crazy + standard → just the mode; random/crazy + non-standard → `mode · scoring`.

**X01 `TurnEnded` payload carries `turn_score` (`turn_start_score - turn_end_score` per `docs/statistics/x01.projections.md` §5.2).** `ProcessDartUseCase` computes it; `buildTurnEndedEvent` accepts an optional `turnScore` int. `X01AverageProjection` prefers this delta over per-dart sum (so bust + Double-In not-in turns contribute 0 to PPR), and falls back to dart-sum when absent for backward compatibility with pre-#318 events. Any new X01 dart-emission path MUST pass `turnScore` or new games will use the legacy convention.

---

## Issue tracker conventions

**Priority labels** (color-coded on GitHub):
- `P0` (red) — critical: wrong user-facing output or broken core flows
- `P1` (orange) — important: correctness or architectural inconsistencies
- `P2` (yellow) — hygiene: anti-patterns, dead code, doc drift

PR titles for issues that ship in multiple PRs use `(refs #N)` and the body ends with `Closes parts of #N.`; the closing `Closes #N` is reserved for the final PR.

---

## Things You Must Not Do

- Store statistics (averages, ratios, percentages) as pre-calculated values in the database
- Import `drift`, `flutter`, or `dio` in any `domain/` layer file
- Import one feature's code from another feature's folder
- Call `ref.read()` inside a widget's `build()` method
- Catch exceptions inside `AsyncValue.guard()`
- Use `!` on `AsyncValue.value` in user-facing UI without loading and error handling
- Mutate `GameState` in place — always `copyWith`
- Skip or comment out contract tests to make CI pass
- Add database triggers — immutability of completed games is application logic only
- Add packages without checking whether the existing stack already covers the need
- Commit the `android/` folder — it is gitignored and scaffolded per machine via `flutter create --platforms=android .`
- Push commits directly to `main` — always go through a PR
- Tag a commit that's not on `main` (release CI refuses to build it; the only exception is hotfixes — see `docs/RELEASES.md`)
- Manually upload APKs to a GitHub Release — releases are produced by `release.yml` from tags only

---

## When Uncertain

1. **Check the spec docs first.** Most questions are answered in `docs/`.
2. **Check the game rules.** `docs/games/` has formal transition tables.
3. **Do not invent architecture.** If a pattern isn't in `docs/STATE_MANAGEMENT.md` or `docs/ARCHITECTURE_COMPLETE.md`, raise it before implementing.
4. **Do not change repository interface signatures** unilaterally — they are shared contracts.
5. **Raise ambiguities explicitly.** If a transition table doesn't cover a case, say so.
