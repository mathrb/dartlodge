# Database, drift & repository rules

> Loaded on demand. CLAUDE.md's Rules Index points here before touching the drift schema, DB, repositories, or test fixtures.

### Repository exceptions
All exceptions extend `RepositoryException` (`lib/core/error/repository_exception.dart`). Never throw raw `Exception` from a repository implementation.

### Contract tests
Every repository implementation must pass the shared contract tests in `test/contracts/`. Never skip or comment out tests to make CI pass.

### Database
drift on every platform (`NativeDatabase.createInBackground` on mobile/desktop, `WasmDatabase` over IndexedDB on web). Schema lives in `lib/core/persistence/drift/database.dart`; `databaseVersion = 2` (v1→v2 added `unlocked_achievements`, #522 — the first migration, applied via `MigrationStrategy.onUpgrade` `m.createTable`). `PRAGMA foreign_keys = ON` is set in `MigrationStrategy.beforeOpen`, which runs on every connection (including immediately after `onUpgrade`), so migrations don't need to toggle it themselves — and adding a brand-new table via `m.createTable` needs no FK-disable dance (CREATE TABLE never triggers FK checks). Completed games are read-only — enforced in application logic, not triggers. The canonical SQL DDL reference is `docs/DATABASE_DDL.md`. After editing drift table classes, run `dart run build_runner build`. **After any schema change, also bump `databaseVersion`, add an `onUpgrade` step, and regenerate the schema snapshots: `dart run drift_dev schema dump lib/core/persistence/drift/database.dart drift_schemas/` then `dart run drift_dev schema generate drift_schemas/ test/drift_schemas/` (committed; `test/core/persistence/drift/migration_test.dart` verifies upgrades with drift's `SchemaVerifier`).**

### Drift foreign keys
Plain `text()()` emits NO foreign key clause — you must call `.references(Type, #col, onDelete: KeyAction.{cascade|restrict|setNull})` explicitly. `PRAGMA foreign_keys = ON` is a no-op without `.references()`. When two columns in a table reference the same parent (e.g. `game_sessions.host_player_id` and `current_turn_player_id` both → `players`), add `@ReferenceName('xxx')` annotations to disambiguate manager-API helpers, or build_runner warns.

### Test database setup
Drift tests use `AppDatabase(NativeDatabase.memory())` directly — see `test/drift_test_base.dart`. With FK enforcement active, fixtures must respect FK order: insert players before competitors, games before competitors/dart_throws/game_events, and use `playerRepo.createPlayer()` to seed referenced player IDs before any `createGame` call.

### Test game setup ordering
Drift enforces read-only on completed games. In tests: create game with `isComplete: false` → insert darts/events → call `gameRepo.completeGame()`. Never set `isComplete: true` at creation if you need to insert data afterward.

### Watchable queries
drift's per-query reactivity is automatic — `select(...).watch()` re-fires whenever drift sees a write to one of the referenced tables. No notify-after-write protocol to remember.

### Repository contract tests
`runHybridTests` (`test/hybrid_test_runner.dart`) spins up a fresh in-memory `AppDatabase` per test against the shared `*_contract.dart` suites. The "hybrid" name is vestigial from the dual-backend era (issue #112) — there is now a single backend.
