## DART-008 — `DartThrown` event payload uses canonical segment string instead of base number + multiplier

**Type:** Bug  
**Component:** `lib/features/game/domain/usecases/process_dart_use_case.dart`  
**Spec reference:** `GAME-EVENT-SPECIFICATIONS.md §4.3`

### Description

The spec defines the `DartThrown` payload as:
```
segment    Enum {1–20, bull}    ← base number only
multiplier Integer {1, 2, 3}
```

The implementation passes the canonical string instead:
```dart
payload: {
  'segment': dartThrow.segment,  // 'T20' — canonical string, not 20
  'multiplier': multiplier,       // 3
}
```

For a triple-20, `segment` should be `20` and `multiplier` should be `3`. The engine then reconstructs the canonical form for `Segment.parse()`, creating a dependency on the internal string format being stable and parseable. A regression in that format will silently corrupt the event log.

This also creates a latent double-prefix bug: if `dartThrow.segment` is already `'T20'` and the engine prepends `'T'` again, `Segment.parse('TT20')` will throw or produce a wrong value.

### Required change

In `ProcessDartUseCase`, parse the canonical string before constructing the payload:

```dart
final parsed = Segment.parse(dartThrow.segment);
final payload = {
  'competitor_id': dartThrow.competitorId,
  'segment': parsed.baseNumber,    // 20 (int)
  'multiplier': parsed.multiplier, // 3 (int)
  'input_method': 'manual',
};
```

### Acceptance criteria

- [ ] `DartThrown` payload `segment` field is always an integer
- [ ] `DartThrown` payload `multiplier` field is always an integer in {1, 2, 3}
- [ ] Engine reconstructs the canonical string from `segment × multiplier` correctly
- [ ] Bull: `segment = 25, multiplier = 1` (single bull) and `segment = 25, multiplier = 2` (double bull)
- [ ] Existing engine tests updated to use new payload shape

