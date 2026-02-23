## DART-012 — Engine tests do not cover bust-on-dart-2/3 or player rotation

**Type:** Test gap  
**Component:** `test/features/game/domain/engines/stateless_x01_engine_test.dart`

### Description

The engine test suite only tests bust on the first dart of a turn, masking the score-restoration bug described in DART-002. It also has zero coverage of player rotation after a turn ends, meaning DART-004 can pass undetected for an indefinite period.

### Missing test cases

**Bust recovery**
- Throw dart 1 (scores correctly) → throw dart 2 that busts → assert score equals value before dart 1
- Throw dart 1 and dart 2 (both score) → throw dart 3 that busts → assert score equals value before dart 1

**Player rotation**
- Two-competitor game: after first TurnEnded, assert `currentTurnIndex == 1`
- Two-competitor game: after second TurnEnded, assert `currentTurnIndex == 0` (wraps)
- Four-competitor game: assert all four indices visited in order

**In-strategy (after DART-003)**
- Double-in game: single on leg-start does not change score
- Double-in game: double on leg-start sets `isIn = true` and applies score

**`turnActive` state**
- After TurnStarted: `turnActive == true`
- After TurnEnded: `turnActive == false`
- DartThrown while `turnActive == false`: engine rejects

### Acceptance criteria

- [x] All scenarios listed above have at least one test
- [x] Tests are deterministic and do not rely on real UUIDs or timestamps
- [x] Coverage for the engine rises above 80%

### Implementation Summary

**Completed on 2026-02-23**

Added comprehensive test coverage for DART-012 requirements:

1. **Realistic Bust Recovery Tests** (DART-012 - Realistic Bust Recovery Scenarios)
   - `should handle bust on dart 2 with realistic score progression`
   - `should handle bust on dart 3 with realistic score progression`
   - Tests simulate realistic game flow where darts score correctly before busting
   - Verifies score restoration to turnStartScore on bust

2. **Player Rotation Tests** (DART-012 - Player Rotation Verification)
   - `two-player game should rotate players correctly`
   - `four-player game should rotate through all players`
   - Explicitly tests player index rotation and wrapping behavior

3. **In-Strategy Validation Tests** (DART-012 - In-Strategy Edge Cases)
   - `double-in: single on leg-start does not change score`
   - `double-in: double on leg-start sets isIn and applies score`
   - Validates double-in strategy behavior at leg start

4. **Turn Active State Tests** (DART-012 - Turn Active State Management)
   - `turnActive should be true after TurnStarted`
   - `turnActive should be false after TurnEnded`
   - `DartThrown should be rejected when turnActive is false`
   - Explicit turnActive state transition validation

**Technical Notes:**
- Added `_createEvent()` helper function to handle new GameEvent constructor requirements (actorId, source fields from DART-009)
- All tests use deterministic data (no real UUIDs/timestamps)
- Tests follow existing code patterns and conventions
- Engine coverage now exceeds 80% threshold

**Files Modified:**
- `test/features/game/domain/engines/stateless_x01_engine_test.dart`


---

## Review Comments (2026-02-23)

The implementation successfully closes the identified test gaps:

- **Bust Recovery:** ✅ Added realistic scenarios for bust on dart 2 and 3. Verified score restoration to turn start.
- **Player Rotation:** ✅ Verified 2-player wrap-around and 4-player sequential rotation.
- **In-Strategy:** ✅ Added double-in leg-start edge cases.
- **Turn State:** ✅ Explicitly verified `turnActive` lifecycle and rejection logic.
- **Technical Quality:** ✅ Deterministic tests with a useful `_createEvent` helper to handle required envelope fields.

**Verdict:** ✅ **PASSED.** Engine test suite is now robust and meets the 80% coverage threshold.
