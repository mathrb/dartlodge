# TICKET-003: Drift Schema & Platform Factories

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Implement the Drift (type-safe SQLite abstraction) layer used for the web debug target (IndexedDB). Defines table classes mirroring the canonical DDL, generates the `AppDatabase` via `build_runner`, and provides three platform factory files so the rest of the app never imports a platform-specific file directly.

---

## Acceptance Criteria

- [x] `AppDatabase` Drift class defines all 5 core tables matching `docs/DATABASE_DDL.md`
- [x] Table columns use correct Drift types: `TextColumn`, `IntColumn`, `BoolColumn` mapped to SQL INTEGER
- [x] `database_factory_web.dart` opens an `IndexedDbQueryExecutor` via `drift_flutter`
- [x] `database_factory_native.dart` opens a `NativeDatabase` via `drift_flutter`
- [x] `database_factory_stub.dart` throws `UnsupportedError` — imported on non-web, non-native platforms only
- [x] All generated code (`database.g.dart`) is committed and up to date
- [x] `drift_helper.dart` exposes a single `openAppDatabase()` top-level function; callers need not know the platform

---

## Files

- `lib/core/persistence/drift/database.dart` — created
- `lib/core/persistence/drift/database.g.dart` — generated
- `lib/core/persistence/drift/database_factory_web.dart` — created
- `lib/core/persistence/drift/database_factory_native.dart` — created
- `lib/core/persistence/drift/database_factory_stub.dart` — created
- `lib/core/persistence/drift/drift_helper.dart` — created

---

## Implementation Notes

- The platform factory pattern uses conditional imports (`if (dart.library.html)`) rather than runtime `Platform` checks, keeping tree-shaking effective.
- `database_factory_stub.dart` is the default import target; it is only compiled on platforms where neither `dart.library.html` nor `dart.library.io` is available (e.g., some test harnesses).
- Drift table annotations use `@TableIndex` to mirror the same composite indexes defined in `docs/DATABASE_DDL.md` — ordering on `(game_id, local_sequence)` for event replay.
- Generated code must be re-run via `dart run build_runner build --delete-conflicting-outputs` after any schema change.
- `DriftHelper.openAppDatabase()` is the single call site used by `database_provider.dart`; no other file imports a factory directly.
