import 'package:dart_lodge/features/auto_scorer/domain/recording/session_correlation.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/usecases/game_use_case_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

RecordedEmission _emit(int handle, String seg, int base, int mult,
        {bool emitted = true}) =>
    RecordedEmission(
        handle: handle,
        segment: seg,
        baseNumber: base,
        multiplier: mult,
        emitted: emitted);

/// A trace whose frames carry the given per-frame emissions.
SessionTrace _traceWith(List<List<RecordedEmission>> perFrame) => SessionTrace(
      header: SessionTraceHeader(
          modelVersion: 'm', gameId: 'g', startedAt: DateTime.utc(2026)),
      lines: [
        const TrackerSegment(instance: 0, config: DartTrackerConfig()),
        for (var i = 0; i < perFrame.length; i++)
          TraceFrame(
            frameIndex: i,
            calMinConfidence: 0.25,
            dartMinConfidence: 0.25,
            detections: const [],
            outcome: RecordedOutcome(
              newDarts: perFrame[i],
              status: const TrackerStatus(
                  phase: TrackerPhase.tracking,
                  dartsOnBoard: 1,
                  dartsThisTurn: 1),
            ),
          ),
      ],
    );

GameEvent _cameraDart(int seq, int base, int mult,
        {String method = 'camera'}) =>
    buildDartThrownEvent(
      gameId: 'g',
      dartId: 'd$seq',
      competitorId: 'c1',
      actorId: 'c1',
      localSequence: seq,
      segment: base,
      multiplier: mult,
      inputMethod: method,
    );

void main() {
  test('aligns matching tracker emissions with camera DartThrowns', () {
    final trace = _traceWith([
      [_emit(0, 'T20', 20, 3)],
      [_emit(1, 'SB', 25, 1)],
    ]);
    final events = [
      _cameraDart(1, 20, 3),
      _cameraDart(2, 25, 1),
    ];

    final c = correlateCameraDarts(trace, events);
    expect(c.trackerEmittedCount, 2);
    expect(c.gameCameraCount, 2);
    expect(c.isAligned, isTrue);
    expect(c.mismatches, isEmpty);
  });

  test('excludes cap-blocked (emitted:false) darts from the tracker side', () {
    final trace = _traceWith([
      [_emit(0, 'T20', 20, 3)],
      [_emit(1, 'D10', 10, 2, emitted: false)], // cap-blocked → not submitted
    ]);
    final events = [_cameraDart(1, 20, 3)]; // only the emitted one reached the game

    final c = correlateCameraDarts(trace, events);
    expect(c.trackerEmittedCount, 1);
    expect(c.gameCameraCount, 1);
    expect(c.isAligned, isTrue);
  });

  test('ignores manual (non-camera) DartThrowns on the game side', () {
    final trace = _traceWith([
      [_emit(0, 'T20', 20, 3)],
    ]);
    final events = [
      _cameraDart(1, 20, 3),
      _cameraDart(2, 5, 1, method: 'manual'), // not camera → ignored
    ];

    final c = correlateCameraDarts(trace, events);
    expect(c.gameCameraCount, 1);
    expect(c.isAligned, isTrue);
  });

  test('flags a segment mismatch (game recorded a different dart)', () {
    final trace = _traceWith([
      [_emit(0, 'T20', 20, 3)],
    ]);
    final events = [_cameraDart(1, 19, 3)]; // T19, not T20

    final c = correlateCameraDarts(trace, events);
    expect(c.isAligned, isFalse);
    expect(c.mismatches, hasLength(1));
    expect(c.mismatches.single.trackerSegment, 'T20');
    expect(c.mismatches.single.gameBaseNumber, 19);
  });

  test('flags a count mismatch (a dart was dropped)', () {
    final trace = _traceWith([
      [_emit(0, 'T20', 20, 3)],
      [_emit(1, 'T19', 19, 3)],
    ]);
    final events = [_cameraDart(1, 20, 3)]; // only one reached the game

    final c = correlateCameraDarts(trace, events);
    expect(c.trackerEmittedCount, 2);
    expect(c.gameCameraCount, 1);
    expect(c.isAligned, isFalse); // count differs even though the pair matches
    expect(c.darts, hasLength(1));
    expect(c.darts.single.matches, isTrue);
  });
}
