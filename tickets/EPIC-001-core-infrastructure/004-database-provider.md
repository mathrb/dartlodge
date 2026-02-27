# TICKET-004: Riverpod Database Provider

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Wire both database backends (SQLite via `DatabaseHelper`, Drift via `DriftHelper`) into the Riverpod dependency graph. A single platform-check (`kIsWeb`) selects the correct backend at startup; all downstream repository providers receive the appropriate database handle through provider overrides.

---

## Acceptance Criteria

- [x] `databaseProvider` is a `keepAlive: true` Riverpod provider that returns the active database handle
- [x] On web (`kIsWeb == true`) the provider opens the Drift `AppDatabase`; on native it opens the sqflite `Database`
- [x] All 5 repository providers (`playerRepositoryProvider`, `gameRepositoryProvider`, `dartThrowRepositoryProvider`, `gameEventRepositoryProvider`, `statisticsRepositoryProvider`) are `keepAlive: true`
- [x] Each repository provider instantiates the correct implementation (Drift on web, sqflite on native) by reading `databaseProvider`
- [x] Provider file lives in `lib/core/persistence/database_provider.dart`
- [x] Generated code (`database_provider.g.dart`) is committed and up to date

---

## Files

- `lib/core/persistence/database_provider.dart` — created
- `lib/core/persistence/database_provider.g.dart` — generated
- `lib/core/persistence/persistence.dart` — barrel export created

---

## Implementation Notes

- `keepAlive: true` is critical for repository providers — they must not be disposed and recreated between route navigations.
- `kIsWeb` is imported from `package:flutter/foundation.dart`; this is the only Flutter import permitted in `core/persistence/`.
- The provider file uses `@riverpod` annotations with `keepAlive: true` on each provider function.
- Downstream features import only the repository interface (from `domain/`) and the provider from `core/persistence/`; they never import sqflite or drift directly.
- `persistence.dart` barrel re-exports all public provider symbols so features have a single import point.
