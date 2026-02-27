# TICKET-010: Shared Contract Test Suite

**Status:** Done
**Epic:** EPIC-001 — Core Infrastructure

---

## Description

Build the shared test infrastructure that enforces identical behaviour across all SQLite and Drift repository implementations. Every repository has a contract suite function; both implementations must pass the same suite.

---

## Acceptance Criteria

- [x] `test/database_test_base.dart` defines `DatabaseTestBase` — abstract base providing `setUp`/`tearDown` with in-memory database lifecycle
- [x] `test/sqflite_test_base.dart` extends `DatabaseTestBase` for sqflite in-memory databases
- [x] `test/drift_test_base.dart` extends `DatabaseTestBase` for Drift in-memory databases
- [x] `test/hybrid_test_runner.dart` provides `runContractSuite()` that executes the same suite function against both backends in one test run
- [x] `test/hybrid_database_tests.dart` wires all 5 contract suites through `HybridTestRunner`
- [x] `test/contracts/player_repository_contract.dart` — contract suite for `PlayerRepository`
- [x] `test/contracts/game_repository_contract.dart` — contract suite for `GameRepository`
- [x] `test/contracts/dart_throw_repository_contract.dart` — contract suite for `DartThrowRepository`
- [x] `test/contracts/game_event_repository_contract.dart` — contract suite for `GameEventRepository`
- [x] `test/contracts/statistics_repository_contract.dart` — contract suite for `StatisticsRepository`
- [x] Additional focused Drift tests: `player_repository_drift_contract_test.dart`, `dart_throw_repository_drift_contract_test.dart`, `statistics_repository_drift_contract_test.dart`
- [x] All contract tests pass with `flutter test`

---

## Files

- `test/database_test_base.dart` — created
- `test/sqflite_test_base.dart` — created
- `test/drift_test_base.dart` — created
- `test/hybrid_test_runner.dart` — created
- `test/hybrid_database_tests.dart` — created
- `test/test_config.dart` — created
- `test/test_data.dart` — created (shared fixture factories)
- `test/contracts/player_repository_contract.dart` — created
- `test/contracts/game_repository_contract.dart` — created
- `test/contracts/dart_throw_repository_contract.dart` — created
- `test/contracts/game_event_repository_contract.dart` — created
- `test/contracts/statistics_repository_contract.dart` — created
- `test/contracts/player_repository_drift_contract_test.dart` — created
- `test/contracts/dart_throw_repository_drift_contract_test.dart` — created
- `test/contracts/statistics_repository_drift_contract_test.dart` — created

---

## Implementation Notes

- Contract suites are plain functions (`void runPlayerRepositoryContractSuite(PlayerRepository repo)`) — they are not test classes. The caller (`HybridTestRunner`) wraps them in `group()` blocks for each backend.
- `DatabaseTestBase.setUp` creates a fresh in-memory database for every test; `tearDown` closes it. This ensures test isolation without file-system side effects.
- `test/test_data.dart` provides canonical fixture factories (`makePlayer()`, `makeGame()`, etc.) used across all suites to avoid fixture drift.
- The hybrid runner pattern means adding a new repository only requires: (a) writing the contract suite function, (b) registering it in `hybrid_database_tests.dart`. Both backends are automatically tested.
- Web-specific Drift tests (`drift_web_test.dart`) exercise the IndexedDB executor path via `sqflite_common_ffi_web` in a headless environment.
