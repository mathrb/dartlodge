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
}
