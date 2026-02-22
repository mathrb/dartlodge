# DART-006.1 — Single Bull Segment Parsing Bug

**Type:** Bug  
**Component:** `lib/features/game/domain/engines/stateless_x01_engine.dart`  
**Related:** DART-006 (follow-up)  
**Priority:** Medium

### Description

During the review of DART-006, a pre-existing bug was discovered in the segment parsing logic. When a single bull (multiplier=1, segment='bull') is thrown, the engine incorrectly passes `'bull'` to `Segment.parse()`, but the parser expects `'SB'` (Single Bull) format.

**Current Buggy Logic:**
```dart
final parsedSegment = Segment.parse(multiplier == 1 ? segment : (multiplier == 2 ? (segment == 'bull' ? 'DB' : 'D$segment') : (segment == 'bull' ? 'TB' : 'T$segment')));
```

**Problem:** When `multiplier == 1` and `segment == 'bull'`, this becomes:
```dart
Segment.parse('bull')  // ❌ Throws FormatException - expects 'SB'
```

### Impact

- Single bull throws with multiplier=1 will fail to parse and throw `FormatException`
- This affects both in-strategy validation and normal scoring
- Double bull (`multiplier == 2`) and triple bull (`multiplier == 3`) work correctly

### Solution

Update the parsing logic to handle single bull correctly:

```dart
final parsedSegment = Segment.parse(
  multiplier == 1 
    ? (segment == 'bull' ? 'SB' : segment)  // ✅ Fix: 'bull' → 'SB'
    : (multiplier == 2 
      ? (segment == 'bull' ? 'DB' : 'D$segment')
      : (segment == 'bull' ? 'TB' : 'T$segment'))
);
```

### Acceptance Criteria

- [ ] Single bull throws (multiplier=1, segment='bull') parse correctly as `SingleBullSegment`
- [ ] Double bull throws (multiplier=2, segment='bull') continue to work as `DoubleBullSegment`
- [ ] Triple bull throws (multiplier=3, segment='bull') continue to work as expected
- [ ] All existing segment parsing continues to work (numbers 1-20 with multipliers 1-3)
- [ ] No regression in existing functionality
- [ ] Comprehensive tests added for bull segment parsing edge cases

### Test Cases Required

1. **Single Bull Parsing:**
   - Input: `segment='bull', multiplier=1`
   - Expected: `SingleBullSegment` with scoreValue=25

2. **Double Bull Parsing (existing, should still work):**
   - Input: `segment='bull', multiplier=2`
   - Expected: `DoubleBullSegment` with scoreValue=50

3. **Regular Number Parsing (should still work):**
   - Input: `segment='20', multiplier=1`
   - Expected: `SingleSegment(20)` with scoreValue=20

### Notes

- This is a follow-up to DART-006 but addresses a separate parsing issue
- The fix is minimal and localized to one line of code
- No database migrations required
- No breaking changes to existing functionality
- Should be tested with all game types that use bull segments (X01, Cricket, etc.)