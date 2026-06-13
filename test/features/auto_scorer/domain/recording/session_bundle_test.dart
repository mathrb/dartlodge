import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_bundle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../test_data.dart';

SessionTrace _trace() => SessionTrace(
      header: SessionTraceHeader(
          modelVersion: 'm', gameId: 'test-game-1', startedAt: DateTime.utc(2026)),
      lines: [
        const TrackerSegment(instance: 0, config: DartTrackerConfig()),
        TraceFrame(
          frameIndex: 0,
          calMinConfidence: 0.25,
          dartMinConfidence: 0.25,
          detections: const [],
          outcome: const RecordedOutcome(
            newDarts: [
              RecordedEmission(
                  handle: 0,
                  segment: 'T20',
                  baseNumber: 20,
                  multiplier: 3,
                  emitted: true)
            ],
            status: TrackerStatus(
                phase: TrackerPhase.tracking, dartsOnBoard: 1, dartsThisTurn: 1),
          ),
        ),
      ],
    );

void main() {
  test('SessionBundle round-trips through its JSON string form', () {
    final bundle = SessionBundle(
      trace: _trace(),
      events: [
        buildDartThrownEvent(
          gameId: 'test-game-1',
          dartId: 'd1',
          competitorId: 'competitor-1',
          actorId: 'competitor-1',
          localSequence: 1,
          segment: 20,
          multiplier: 3,
          inputMethod: 'camera',
        ),
      ],
      game: TestData.createTestGame(),
      competitors: const [
        Competitor(
          competitorId: 'competitor-1',
          gameId: 'test-game-1',
          type: CompetitorType.solo,
          name: 'Alice',
          players: [CompetitorPlayer(playerId: 'p1', rotationPosition: 0)],
        ),
      ],
    );

    final restored = SessionBundle.fromJsonString(bundle.toJsonString());

    // Canonical re-serialization is identical → every field survived.
    expect(restored.toJsonString(), bundle.toJsonString());
    // Spot-check the cross-feature pieces decoded back to typed objects.
    expect(restored.trace.header.gameId, 'test-game-1');
    expect(restored.trace.lines.whereType<TraceFrame>().single.outcome.newDarts
        .single.segment, 'T20');
    expect(restored.events.single.eventType, 'DartThrown');
    expect(restored.events.single.payload['input_method'], 'camera');
    expect(restored.game.gameId, 'test-game-1');
    expect(restored.competitors.single.name, 'Alice');
  });
}
