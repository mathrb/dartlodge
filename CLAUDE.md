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
dart run build_runner build --delete-conflicting-outputs  # after any @freezed or @riverpod change
flutter run -d chrome
flutter test
flutter test -r failures-only  # errors only
```

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
| Statistics definitions and projections | `docs/statistics/x01.projections.md`, `docs/statistics/statistics.architecture.md` |
| Riverpod providers, state patterns | `docs/STATE_MANAGEMENT.md` |
| Navigation flows and screen index | `docs/UI_SCREEN_FLOWS_V3_FINAL.md` |
| Design tokens, colors, typography, spacing | `docs/design/DESIGN_SYSTEM.md` |
| Data entities and field names | `docs/DATA.md` |
| Backend REST endpoints (optional) | `docs/API_CONTRACT.md` |

---

## Architecture Constraints

These are hard constraints. Breaking them requires explicit human approval.

### 1. Feature-First Clean Architecture

```
lib/features/<feature>/
  domain/       ← pure Dart only — NO Flutter, NO drift, NO http
  data/         ← implements domain interfaces; contains drift/sqflite code
  presentation/ ← Flutter widgets and Riverpod providers
```

- `domain/` has zero imports of `package:flutter`, `package:drift`, `package:sqflite`, or `package:dio`.
- No feature imports another feature directly. Cross-feature communication via `core/` providers or shared domain entities only.
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

Platform selection (native SQLite vs WASM) happens once in the Drift factory. Everywhere else sees only the repository interface.

---

## Riverpod Conventions

Follow `docs/STATE_MANAGEMENT.md` exactly. Two rules that are easiest to violate:
- Use `ref.watch()` inside `build()`. Use `ref.read()` only in event handlers and notifier methods.
- Handle all three `AsyncValue` states in every widget: `data`, `loading`, `error`. Never use `.value!` without fallbacks.

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

**Repository exceptions:** All exceptions extend `RepositoryException` (`lib/core/error/repository_exception.dart`). Never throw raw `Exception` from a repository implementation.

**Contract tests:** Every repository implementation must pass the shared contract tests in `test/contracts/`. Never skip or comment out tests to make CI pass.

**Database:** `PRAGMA foreign_keys = ON` must be set in `onOpen`. Schema migrations applied incrementally in `onUpgrade`. Completed games are read-only — enforced in application logic, not triggers.

**Statistics scope resets:** Turn resets on `TurnStarted`, Leg resets on `LegCompleted`, Match resets on `GameCompleted`. No other reset points.

**Notifier tests:** Use `ProviderContainer` with `overrides`. Never instantiate notifiers directly. Use `ProviderScope` with `overrides` for widget tests.

**Colors:** Always use themed color tokens from `docs/design/DESIGN_SYSTEM.md`. Never hardcode color values directly in widgets.

**Round semantics:** A "round" is one full rotation where ALL competitors throw. `totalRounds` is the correct field name. Do not use `maxRounds` or count per-competitor turns or individual dart throws as rounds.

**Spec edits:** When asked to update a spec or document, only edit that document — do not modify code files unless explicitly asked.

**UI refactors:** After any widget redesign or UI refactor, update the corresponding test expectations in the same session before committing.

---

## Things You Must Not Do

- Store statistics (averages, ratios, percentages) as pre-calculated values in the database
- Import `drift`, `sqflite`, `flutter`, or `dio` in any `domain/` layer file
- Import one feature's code from another feature's folder
- Call `ref.read()` inside a widget's `build()` method
- Catch exceptions inside `AsyncValue.guard()`
- Use `!` on `AsyncValue.value` in user-facing UI without loading and error handling
- Mutate `GameState` in place — always `copyWith`
- Skip or comment out contract tests to make CI pass
- Add database triggers — immutability of completed games is application logic only
- Add packages without checking whether the existing stack already covers the need

---

## When Uncertain

1. **Check the spec docs first.** Most questions are answered in `docs/`.
2. **Check the game rules.** `docs/games/` has formal transition tables.
3. **Do not invent architecture.** If a pattern isn't in `docs/STATE_MANAGEMENT.md` or `docs/ARCHITECTURE_COMPLETE.md`, raise it before implementing.
4. **Do not change repository interface signatures** unilaterally — they are shared contracts.
5. **Raise ambiguities explicitly.** If a transition table doesn't cover a case, say so.
