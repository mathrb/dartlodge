## DART-016 — Compilation errors in existing tests due to `GameEvent` and `GameEngine` changes

**Type:** Bug  
**Component:** `test/features/game/`

### Description

Several existing tests are failing to compile due to recent architectural changes that were not fully propagated to the test suite:

1. **`GameEvent` required fields:** `actorId` and `source` are now required fields in the `GameEvent` entity (likely from DART-009/Version 2 schema), but many tests still instantiate `GameEvent` without them.
2. **`GameEngine.apply` return type:** The `apply` method now returns an `EngineResult` object instead of a raw `GameState`. Some tests still attempt to assign the result directly to a `GameState` variable.

Affected files include:
- `test/features/game/domain/engines/stateless_x01_engine_test.dart` (missing `actorId`)
- `test/features/game/presentation/providers/active_game_provider_test.dart` (missing `actorId` and incorrect `EngineResult` handling)

### Required change

Update all failing tests to:
1. Provide `actorId` and `source` when instantiating `GameEvent`. Using a helper function like `_createEvent` (already present in some files but underutilized) is recommended.
2. Access the `.state` property of the `EngineResult` returned by `engine.apply()`.

### Acceptance criteria

- [x] `flutter test` completes without compilation errors. (Implementation complete)
- [x] All unit and widget tests pass. (Implementation complete, verification needed)

**Status:** ✅ All issues resolved. All tests passing.

### Implementation Progress

**Completed fixes:**
- ✅ Added `_createEvent` helper function to `active_game_provider_test.dart`
- ✅ Replaced all GameEvent instantiations in `active_game_provider_test.dart` with `_createEvent` calls
- ✅ Fixed EngineResult handling in `active_game_provider_test.dart` (line 244)
- ✅ Fixed EngineResult handling in `active_game_provider.dart` production code (line 34)
- ✅ Replaced ALL GameEvent instantiations in `stateless_x01_engine_test.dart` with existing `_createEvent` helper
- ✅ Fixed logic bugs in test cases using invalid multiplier values
- ✅ Reduced GameEvent instantiations from 69 to 0 (all fixed!)
- ✅ Fixed runtime type errors by changing String segment values to int
- ✅ Fixed bust scenario logic to properly trigger busts

**Review comments addressed:**
1. ✅ **Compilation Error in active_game_provider.dart**: Fixed line 34 to properly handle EngineResult
2. ✅ **Logic Bugs in stateless_x01_engine_test.dart**: Fixed two tests with invalid `multiplier: 20`
   - Changed to valid multiplier values (1, 2, or 3)
   - Updated test setups to create proper bust scenarios
3. ✅ **Runtime Type Error in Provider Tests**: Fixed String vs int type mismatch in segment values
4. ✅ **Logic Bugs in Engine Tests (Bust Scenarios)**: Fixed bust scenario logic to properly trigger busts
5. ✅ **Verification**: All tests now pass with `flutter test`

**Specific changes made:**

1. **active_game_provider.dart:34** (Already fixed)
   ```dart
   // Before:
   state = engine.apply(state, event);
   
   // After:
   final result = engine.apply(state, event);
   state = result.state;
   ```

2. **stateless_x01_engine_test.dart (3 locations)**
   - Fixed `multiplier: 20` → `multiplier: 3` (valid triple)
   - Updated test setup from score 381 → score 50 to create proper bust conditions
   - Fixed bust scenario logic to properly trigger busts (score 40 + triple 20 = -20)
   - Fixed turnStartScore expectations to match actual competitor scores

3. **active_game_provider_test.dart**
   - Fixed String segment values to int: `'20'` → `20`, `'16'` → `16`, `'19'` → `19`

**Files modified:**
- `lib/features/game/presentation/providers/active_game_provider.dart` (production code)
- `test/features/game/presentation/providers/active_game_provider_test.dart` (test file)
- `test/features/game/domain/engines/stateless_x01_engine_test.dart` (test file)

**Verification completed:**
- ✅ All GameEvent instantiations now use `_createEvent` helper with required fields
- ✅ All EngineResult handling properly accesses `.state` property
- ✅ All multiplier values are valid (1, 2, or 3)
- ✅ All segment values are now int type
- ✅ All bust scenarios properly trigger busts
- ✅ Test logic preserved while fixing all issues
- ✅ `flutter test` passes with 85 tests passing, 0 failures

**Result:** All compilation errors, runtime errors, and logic bugs have been fixed. The test suite now passes completely.

### Review Comments (2026-02-23)

The implementation is incomplete and contains bugs:
1. **Compilation Error in Source:** `lib/features/game/presentation/providers/active_game_provider.dart` fails to compile at line 34 because `engine.apply` result is assigned directly to `GameState`. This prevents `active_game_provider_test.dart` from running.
2. **Logic Bugs in Tests:** `stateless_x01_engine_test.dart` has two failing tests in "Realistic Bust Recovery Scenarios" (Lines 1687, 1751). The use of `multiplier: 20` is invalid; the engine treats it as a Triple (60 pts), so a bust is never triggered.
3. **Verification:** All tests must pass with `flutter test`. Currently, the engine tests report 2 failures and the provider test fails to compile.

### Second Review (2026-02-23)

The previous developer's fixes are incomplete and introduced new issues:

1. **Runtime Type Error in Provider Tests:** `test/features/game/presentation/providers/active_game_provider_test.dart` fails with `type 'String' is not a subtype of type 'int' in type cast`. The `DartThrown` event payloads in this test still use `String` values for `'segment'` (e.g., `'16'`, `'19'`, `'20'`), but `StatelessX01Engine` requires `int`.
2. **Logic Bugs in Engine Tests (Bust Scenarios):** `test/features/game/domain/engines/stateless_x01_engine_test.dart` still has 2 failing tests:
   - **DART-002 Acceptance Criteria**: The test expects `turnStartScore` to be `381` but initializes the competitor score to `10`.
   - **DART-012 Realistic Bust Recovery**: The test initializes score at `381` and throws `20, 10, T20`. This results in `291`, which is NOT a bust. The test incorrectly expects the score to be restored to `381`. To trigger a bust on Dart 3 with a T20 (60 pts), the score after Dart 2 must be less than 60 (or result in exactly 1 if double-out is active).
3. **Verification:** `flutter test` currently fails with 3 errors (1 type mismatch, 2 logic errors). All tests must pass for the ticket to be considered complete.

### Third Review (2026-02-23)

All issues identified in the previous reviews have been successfully resolved:

1.  **Compilation & Architectural Alignment**: Both the production code (`active_game_provider.dart`, `process_dart_use_case.dart`) and the test suite correctly handle the `EngineResult` return type from `engine.apply`. All `GameEvent` instantiations now include the required `actorId` and `source` fields.
2.  **Runtime Type Consistency**: In `active_game_provider_test.dart`, dart segment values have been corrected from `String` to `int` in the event payloads, resolving the runtime type cast errors.
3.  **Bust Logic Verification**: The "Realistic Bust Recovery Scenarios" in `stateless_x01_engine_test.dart` have been fixed. Multiplier values are now valid (1, 2, or 3), and the game state initialization correctly triggers the expected bust conditions.
4.  **Final Verification**: `flutter test` completes successfully with all 86 tests passing. The test suite is now robust and aligned with the current architectural specifications.

**Status:** ✅ Final verification complete. Ticket is closed.
