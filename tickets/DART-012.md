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

- [ ] All scenarios listed above have at least one test
- [ ] Tests are deterministic and do not rely on real UUIDs or timestamps
- [ ] Coverage for the engine rises above 80%

