# EPIC-001: Core Infrastructure

## Goal
Provide a stable, tested persistence layer, error type hierarchy, and dependency injection foundation that all other features build on.

## Status
[x] Complete

## Scope — In
- Database schema: all DDL from `docs/DATABASE_DDL.md` (games, competitors, dart_throws, game_events, players, sync_queue tables)
- `PRAGMA foreign_keys = ON` enforced in `onOpen` on every connection
- Schema version 1 in `onCreate`; incremental migrations in `onUpgrade` (version 2 = optional backend tables)
- `RepositoryException` sealed class hierarchy in `lib/core/error/repository_exception.dart`
  - `EntityNotFoundException`, `DuplicateEntityException`, `DatabaseException`, `DuplicateDartException`, etc.
- Sqflite implementations for all 5 repositories:
  - `PlayerRepositoryImpl` (sqflite)
  - `GameRepositoryImpl` (sqflite)
  - `DartThrowRepositoryImpl` (sqflite)
  - `GameEventRepositoryImpl` (sqflite)
  - `StatisticsRepositoryImpl` (sqflite)
- Drift (IndexedDB/web) implementations for all 5 repositories
- `lib/core/persistence/database_provider.dart` — platform selection (sqflite vs drift) + Riverpod `keepAlive` providers
- Shared contract test framework in `test/contracts/` (`DatabaseTestBase`, hybrid runner that runs the same suite against both implementations)
- Code generation setup: `freezed`, `riverpod_generator`, `build_runner` configured and wired in `pubspec.yaml`
- All dependencies pinned in `pubspec.yaml`

## Scope — Out
- Any UI or widget code
- Game engine logic
- Statistics projections
- Backend sync tables (schema v2 is defined but not wired until EPIC-010)

## Key User Stories
- As a developer, the app persists game data to a local database so that data survives restarts.
- As a developer, I get typed, catchable exceptions from every repository method so that error handling is consistent.
- As a developer, running `flutter test` against both sqflite and drift implementations runs the same contract suite so that regressions are caught regardless of platform.

## Technical Components
- `pubspec.yaml` — all dependencies + dev dependencies
- `lib/core/error/repository_exception.dart` — sealed class + all subclasses
- `lib/core/persistence/database_provider.dart` — DB init + Riverpod providers
- `lib/features/players/data/repositories/player_repository_sqflite.dart`
- `lib/features/players/data/repositories/player_repository_drift.dart`
- `lib/features/game/data/repositories/game_repository_sqflite.dart`
- `lib/features/game/data/repositories/game_repository_drift.dart`
- `lib/features/game/data/repositories/dart_throw_repository_sqflite.dart`
- `lib/features/game/data/repositories/dart_throw_repository_drift.dart`
- `lib/features/game/data/repositories/game_event_repository_sqflite.dart`
- `lib/features/game/data/repositories/game_event_repository_drift.dart`
- `lib/features/statistics/data/repositories/statistics_repository_sqflite.dart`
- `lib/features/statistics/data/repositories/statistics_repository_drift.dart`
- `test/contracts/` — shared contract test suite for all 5 repositories

## Dependencies
None. This epic is the foundation for everything else.

## Spec References
- `docs/DATABASE_DDL.md` — authoritative CREATE TABLE statements
- `docs/REPOSITORY_INTERFACES.md` — method signatures, return types, exception types
