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
| Crash reporting | `sentry_flutter` (conditionally initialized in `lib/main.dart` — opt-out, see the Sentry rule in `docs/rules/git-ci-release.md`; do not remove the `SentryFlutter.init` call) |

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

> Hard-won project rules. The everyday **Workflow essentials** below apply to every change and stay inline. Everything else is grouped by domain in the **Rules Index** — open the matching `docs/rules/*.md` file *before* you start work in that area. The one-line ⚠️ tripwires flag the most surprising/destructive gotchas so the warning fires even before you open the file.

### Workflow essentials (apply to every change)

- **Branch first.** All work goes on a branch off `main` named `<type>/<slug>`, type ∈ {`feat`, `fix`, `docs`, `chore`, `hotfix`}, slug short and dash-separated (`feat/cricket-stats-export`). Never commit directly to `main`.
- **PR titles** = soft Conventional Commits (`feat(cricket): …`, `fix(x01): …`, `docs: …`, `chore(deps): …`) — they become the squash-merge message and feed release notes.
- **Squash-merge only.** Never rebase-merge or merge-commit. Branches auto-delete after merge.
- **Every PR is reviewed** via the `code-review:code-review` skill before merge (not `gh pr diff`); CI must be green. Full pipeline → `docs/rules/git-ci-release.md`.
- **CI does not run `build_runner`.** Generated `.g.dart` / `.freezed.dart` / `.mocks.dart` are committed — after editing any `@freezed` / `@riverpod` / `@GenerateMocks`, regenerate locally and commit in the same PR.
- **Run `flutter analyze --no-fatal-infos` as the LAST step before push** (project-wide, not per-path). Quick CI-clean check: `flutter analyze --no-fatal-infos 2>&1 | grep -E '^\s*(warning|error) •'` → empty = clean. Detail → `docs/rules/git-ci-release.md`.
- **Stage explicit paths — never `git add -A` / `git add .`.** The tree carries many untracked scratch files (`*.png`/`*.jpg`/`*.yml` at the repo root, `e2e/node_modules`, `.playwright-*`); a blanket add stages junk.
- **Never commit `pubspec.lock` / `.flutter-plugins-dependencies`** unless the dep set actually changed — they regenerate on every `flutter pub get` / `flutter run` / `build_runner build` and commonly show `M`. Run `git checkout pubspec.lock .flutter-plugins-dependencies` before staging to keep PR diffs clean.
- **Route every displayed number through `StatFormatter`** (`lib/core/utils/stat_formatter.dart`) — `test.yml` greps `lib/features/*/presentation/` for `toStringAsFixed` and fails CI on ANY match. Detail → `docs/rules/statistics.md`.
- **Spec edits touch only the spec** — never code, unless explicitly asked.
- **After any UI refactor, update the test expectations in the same session** before committing.

### Rules Index — open the matching file before working in that area

| Before you touch… | Read first | ⚠️ Top tripwires |
|---|---|---|
| Cricket scoring / variants / labels | `docs/rules/cricket.md` | Variant labels live in **3 aligned places**; adding a variant = **4 edits incl. a registry test**; scoring × targetMode are orthogonal — **never hardcode `[15..20]`** |
| X01 scoring / strategy / turn_score | `docs/rules/x01.md` | Strategy values are lowercase (`'straight'`/`'double'`/`'master'`); `TurnEnded` must carry `turn_score` |
| Game events / config dispatch / rounds / payloads / RNG | `docs/rules/game-engine.md` | `GameConfig` dispatch uses `maybeMap`, **not** `maybeWhen`; `local_sequence` is **per-game** — sort by `(game_id, local_sequence)`; a "round" = full rotation (`totalRounds`); `DartCorrected` key is `original_event_id`; `endGame/endDrill` don't mutate `gameState.isComplete` |
| Stats / projections / formatters | `docs/rules/statistics.md` | All projection wiring lives in `PlayerStatsAssembler`; `GameStats.gameType` is load-bearing; snapshots are two-level |
| Drift schema / DB / test fixtures | `docs/rules/database.md` | **Completed games are read-only** — create incomplete → insert → `completeGame()`; after any schema change bump `databaseVersion` + `onUpgrade` + regen snapshots; FKs need explicit `.references()` |
| Auto-scorer / camera / capture | `docs/rules/auto-scorer.md` | Don't wrap `CameraPreview` in your own `AspectRatio`; **every capture write gates on `dataCollectionEnabledProvider`**; camera changes aren't widget-testable |
| UI / design tokens / navigation | `docs/rules/ui-design.md` | Always use DESIGN_SYSTEM tokens — never hardcode colors; **`context.go()` wipes the back stack** — use `push()` for poppable nav |
| Notifier / widget tests | `docs/rules/testing.md` | Use `ProviderContainer`/`ProviderScope` overrides — never instantiate notifiers directly |
| Releases / version / CI / build tooling | `docs/rules/git-ci-release.md` | Releases are **tag-driven** — never upload an APK manually; don't add manual Sentry handlers in `main.dart` |
| E2E / Playwright | `docs/rules/e2e.md` | Suite is tag-sliced + run manually — remind which `--grep @tag` slice after engine/projection/i18n/sink changes |

### Adding or changing a rule (keep this section lean)

- **New rule → the matching `docs/rules/*.md` file, not here.** Add to *Workflow essentials* only if it's truly cross-cutting (applies to every change) *and* short.
- **Add a ⚠️ tripwire only when the rule is surprising or destructive.** Routine rules get a home in the file, not a headline — over-adding headlines is what re-bloats this section.
- **Prune when gated.** Once a rule is enforced by a test/lint/CI gate, shrink it to a pointer at the gate (the gate is the source of truth).
- **Be specific, revise like code.** "Use X", not "prefer X when possible". If an agent gets something wrong twice, that's a missing or weak rule.
- **Keep the index in sync** — every `docs/rules/*.md` file has exactly one Rules Index row.

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
