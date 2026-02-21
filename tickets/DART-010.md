## DART-010 — `CreateGameUseCase` does not emit a `TurnStarted` event; first turn is never formally opened

**Type:** Bug  
**Component:** `lib/features/game/domain/usecases/create_game_use_case.dart`  
**Spec reference:** `GAME-EVENT-SPECIFICATIONS.md §4.2`, `x01_transitions.md — Table B`

### Description

`CreateGameUseCase` emits a `GameCreated` event and stops. Table B rejects any `DartThrown` event while `turn_active == false`. The first turn must be opened by a `TurnStarted` event after game creation.

As a consequence, even after DART-004 is fixed, the first dart of any game will be rejected by the engine's turn-inactive guard as soon as that guard is implemented.

### Required change

After appending `GameCreated`, the use case must also append a `TurnStarted` event for the first competitor:

```dart
final turnStarted = GameEvent(
  eventId: Uuid().v4(),
  gameId: game.gameId,
  eventType: 'TurnStarted',
  payload: {
    'competitor_id': competitors.first.competitorId,
    'turn_index': 0,
  },
  // ...
);
await _eventRepository.appendEvent(turnStarted);
```

### Acceptance criteria

- [ ] A newly created game has exactly two events: `GameCreated` followed by `TurnStarted`
- [ ] The `TurnStarted` payload identifies the first competitor
- [ ] Engine applies `TurnStarted` and sets `turnActive = true`
- [ ] First `DartThrown` is accepted without rejection

