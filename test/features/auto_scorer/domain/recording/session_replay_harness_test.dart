import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_bundle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_correlation.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_replay_harness.dart';

/// An X01 501 bundle: three camera T20s (180) → score 321. The trace's emitted
/// darts mirror the camera DartThrown events 1:1.
SessionBundle x01Bundle() {
  SessionTrace trace() {
    TraceFrame t20(int i) => TraceFrame(
          frameIndex: i,
          calMinConfidence: 0.25,
          dartMinConfidence: 0.25,
          detections: const [],
          outcome: RecordedOutcome(
            newDarts: const [
              RecordedEmission(
                  handle: 0,
                  segment: 'T20',
                  baseNumber: 20,
                  multiplier: 3,
                  emitted: true)
            ],
            status: TrackerStatus(
                phase: TrackerPhase.tracking,
                dartsOnBoard: i + 1,
                dartsThisTurn: i + 1),
          ),
        );
    return SessionTrace(
      header: SessionTraceHeader(
          modelVersion: 'test',
          gameId: 'test-game-1',
          startedAt: DateTime.utc(2026, 6, 13)),
      lines: [
        const TrackerSegment(instance: 0, config: DartTrackerConfig()),
        t20(0),
        t20(1),
        t20(2),
      ],
    );
  }

  return SessionBundle(
    trace: trace(),
    events: [
      buildTurnStartedEvent(
        gameId: 'test-game-1',
        competitorId: 'competitor-1',
        playerId: 'p1',
        localSequence: 1,
        turnIndex: 0,
        legIndex: 0,
        startingScore: 501,
      ),
      for (var i = 0; i < 3; i++)
        buildDartThrownEvent(
          gameId: 'test-game-1',
          dartId: 'd$i',
          competitorId: 'competitor-1',
          actorId: 'competitor-1',
          playerId: 'p1',
          localSequence: 2 + i,
          segment: 20,
          multiplier: 3,
          score: 60,
          inputMethod: 'camera',
        ),
    ],
    // Straight-in / straight-out so plain T20s reduce the score (a double-in
    // game would keep it at 501 until a double opens it).
    game: Game(
      gameId: 'test-game-1',
      gameType: GameType.x01,
      config: const GameConfig.x01(
          startingScore: 501, inStrategy: 'straight', outStrategy: 'straight'),
      startTime: DateTime.utc(2026, 6, 13),
      isComplete: false,
    ),
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
}

void main() {
  test('correlation aligns the trace emissions with the camera events', () {
    final b = x01Bundle();
    final c = correlateCameraDarts(b.trace, b.events);
    expect(c.trackerEmittedCount, 3);
    expect(c.gameCameraCount, 3);
    expect(c.isAligned, isTrue);
  });

  test('engine replay recovers the X01 score (501 - 3×T20 = 321)', () {
    final state = replaySessionGameState(x01Bundle());
    expect(state.competitors.firstWhere((c) => c.competitorId == 'competitor-1').score, 321);
  });

  test('loadBundle replays the committed fixture identically', () {
    final b = loadBundle('x01_session_bundle');
    expect(correlateCameraDarts(b.trace, b.events).isAligned, isTrue);
    expect(replaySessionGameState(b).competitors.firstWhere((c) => c.competitorId == 'competitor-1').score, 321);
  });
}
