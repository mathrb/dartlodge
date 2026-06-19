import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the `inputMethod` parameter added to [buildDartThrownEvent] for the
/// auto-scorer (#380, #377 §4): manual input stays the default, camera-scored
/// darts set `'camera'`. `input_method` is the CLAUDE.md-sanctioned payload key
/// for exactly this.
void main() {
  GameEvent build({String? inputMethod}) => buildDartThrownEvent(
        gameId: 'g1',
        dartId: 'd1',
        competitorId: 'c1',
        actorId: 'a1',
        localSequence: 1,
        segment: 20,
        multiplier: 3,
        inputMethod: inputMethod ?? 'manual',
      );

  test('defaults to manual input', () {
    expect(buildDartThrownEvent(
          gameId: 'g1',
          dartId: 'd1',
          competitorId: 'c1',
          actorId: 'a1',
          localSequence: 1,
          segment: 20,
          multiplier: 3,
        ).payload['input_method'],
        'manual');
  });

  test('records camera input when supplied', () {
    expect(build(inputMethod: 'camera').payload['input_method'], 'camera');
  });

  test('omits x/y from the payload when no position is supplied', () {
    final payload = buildDartThrownEvent(
      gameId: 'g1',
      dartId: 'd1',
      competitorId: 'c1',
      actorId: 'a1',
      localSequence: 1,
      segment: 20,
      multiplier: 3,
    ).payload;
    expect(payload.containsKey('x'), isFalse);
    expect(payload.containsKey('y'), isFalse);
  });

  test('includes the normalised impact position when supplied (#571)', () {
    final payload = buildDartThrownEvent(
      gameId: 'g1',
      dartId: 'd1',
      competitorId: 'c1',
      actorId: 'a1',
      localSequence: 1,
      segment: 20,
      multiplier: 3,
      x: 0.12,
      y: -0.34,
    ).payload;
    expect(payload['x'], 0.12);
    expect(payload['y'], -0.34);
  });

  test('payload key-set is exactly the sanctioned keys for an auto dart', () {
    final keys = buildDartThrownEvent(
      gameId: 'g1',
      dartId: 'd1',
      competitorId: 'c1',
      actorId: 'a1',
      localSequence: 1,
      segment: 20,
      multiplier: 3,
      score: 60,
      playerId: 'p1',
      inputMethod: 'camera',
      x: 0.5,
      y: 0.5,
    ).payload.keys;
    expect(
      keys,
      unorderedEquals([
        'competitor_id',
        'player_id',
        'segment',
        'multiplier',
        'score',
        'input_method',
        'x',
        'y',
      ]),
    );
  });
}
