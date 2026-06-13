import 'dart:convert';

import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// A frame exercising one [TrackerPhase], with optional darts.
TraceFrame _frame(
  int index,
  TrackerPhase phase, {
  List<RawDetection> detections = const [],
  List<RecordedEmission> newDarts = const [],
  int dartsOnBoard = 0,
  int dartsThisTurn = 0,
}) =>
    TraceFrame(
      frameIndex: index,
      detections: detections,
      outcome: RecordedOutcome(
        newDarts: newDarts,
        status: TrackerStatus(
          phase: phase,
          dartsOnBoard: dartsOnBoard,
          dartsThisTurn: dartsThisTurn,
        ),
      ),
    );

const _config = RecordedTrackerConfig(
  tracker: DartTrackerConfig(),
  calMinConfidence: 0.25,
  dartMinConfidence: 0.3,
);

/// A trace covering every [TrackerPhase], emitted + capped (unemitted) darts,
/// raw detections, and a mid-session tracker reset (a second [TrackerSegment]).
SessionTrace _sample() => SessionTrace(
      header: SessionTraceHeader(
        modelVersion: 'dart_round21b_withcal',
        gameId: 'game-1',
        startedAt: DateTime.utc(2026, 6, 13, 12, 0, 0),
      ),
      lines: [
        const TrackerSegment(instance: 0, config: _config),
        _frame(0, TrackerPhase.idle),
        _frame(
          1,
          TrackerPhase.noCalibration,
          detections: const [
            RawDetection(classIndex: 0, x: 0.51, y: 0.48, conf: 0.83),
          ],
        ),
        _frame(2, TrackerPhase.needsCalibration),
        _frame(
          3,
          TrackerPhase.tracking,
          detections: const [
            RawDetection(classIndex: 0, x: 0.5, y: 0.5, conf: 0.9),
            RawDetection(classIndex: 1, x: 0.1, y: 0.1, conf: 0.7),
          ],
          newDarts: const [
            RecordedEmission(
              handle: 7,
              segment: 'T20',
              baseNumber: 20,
              multiplier: 3,
              emitted: true,
            ),
          ],
          dartsOnBoard: 1,
          dartsThisTurn: 1,
        ),
        _frame(
          4,
          TrackerPhase.turnFull,
          newDarts: const [
            RecordedEmission(
              handle: 8,
              segment: 'SB',
              baseNumber: 25,
              multiplier: 1,
              emitted: false, // blocked by the 3-dart cap
            ),
          ],
          dartsOnBoard: 4,
          dartsThisTurn: 3,
        ),
        _frame(5, TrackerPhase.cameraMoved),
        // Mid-session tracker re-creation: a fresh instance + (changed) config.
        const TrackerSegment(
          instance: 1,
          config: RecordedTrackerConfig(
            tracker: DartTrackerConfig(confirmFrames: 3, maxDartsPerTurn: 9),
            calMinConfidence: 0.4,
            dartMinConfidence: 0.4,
          ),
        ),
        _frame(6, TrackerPhase.rebaselined),
      ],
    );

void main() {
  group('SessionTrace serialization', () {
    test('round-trips through JSONL (canonical re-serialization is identical)',
        () {
      final trace = _sample();
      final jsonl = trace.toJsonl();

      final restored = SessionTrace.fromJsonl(jsonl);

      // Re-encoding the decoded trace yields byte-identical JSONL — the
      // contract is canonical, so this proves every field survives the trip.
      expect(restored.toJsonl(), jsonl);
    });

    test('decodes header and line structure', () {
      final restored = SessionTrace.fromJsonl(_sample().toJsonl());

      expect(restored.header.traceVersion, kSessionTraceVersion);
      expect(restored.header.modelVersion, 'dart_round21b_withcal');
      expect(restored.header.gameId, 'game-1');
      expect(restored.header.startedAt, DateTime.utc(2026, 6, 13, 12, 0, 0));

      expect(restored.lines.whereType<TrackerSegment>(), hasLength(2));
      expect(restored.lines.whereType<TraceFrame>(), hasLength(7));
    });

    test('preserves raw detections, config, phases and emissions', () {
      final restored = SessionTrace.fromJsonl(_sample().toJsonl());

      final segment = restored.lines.whereType<TrackerSegment>().first;
      expect(segment.instance, 0);
      expect(segment.config.tracker.confirmFrames, 2);
      expect(segment.config.calMinConfidence, 0.25);
      expect(segment.config.dartMinConfidence, 0.3);

      final tracking = restored.lines
          .whereType<TraceFrame>()
          .firstWhere((f) => f.frameIndex == 3);
      expect(tracking.detections, hasLength(2));
      expect(tracking.detections.first.classIndex, 0);
      expect(tracking.detections.first.conf, 0.9);
      expect(tracking.outcome.status.phase, TrackerPhase.tracking);
      expect(tracking.outcome.newDarts.single.segment, 'T20');
      expect(tracking.outcome.newDarts.single.emitted, isTrue);

      final capped = restored.lines
          .whereType<TraceFrame>()
          .firstWhere((f) => f.frameIndex == 4);
      expect(capped.outcome.status.phase, TrackerPhase.turnFull);
      expect(capped.outcome.newDarts.single.emitted, isFalse);

      final reset = restored.lines.whereType<TrackerSegment>().last;
      expect(reset.instance, 1);
      expect(reset.config.tracker.confirmFrames, 3);
      expect(reset.config.tracker.maxDartsPerTurn, 9);
    });

    test('every TrackerPhase round-trips', () {
      for (final phase in TrackerPhase.values) {
        final trace = SessionTrace(
          header: SessionTraceHeader(
            modelVersion: 'm',
            gameId: 'g',
            startedAt: DateTime.utc(2026),
          ),
          lines: [
            const TrackerSegment(instance: 0, config: _config),
            _frame(0, phase),
          ],
        );
        final restored = SessionTrace.fromJsonl(trace.toJsonl());
        final frame = restored.lines.whereType<TraceFrame>().single;
        expect(frame.outcome.status.phase, phase, reason: 'phase $phase');
      }
    });
  });

  group('JSON key sets (freeze the wire contract)', () {
    test('header keys', () {
      final keys = SessionTraceHeader(
        modelVersion: 'm',
        gameId: 'g',
        startedAt: DateTime.utc(2026),
      ).toJson().keys;
      expect(
        keys,
        unorderedEquals(
            ['kind', 'trace_version', 'model_version', 'game_id', 'started_at']),
      );
    });

    test('tracker-segment + config keys', () {
      final segment =
          const TrackerSegment(instance: 0, config: _config).toJson();
      expect(segment.keys, unorderedEquals(['kind', 'instance', 'config']));
      expect(
        (segment['config'] as Map).keys,
        unorderedEquals([
          'match_tolerance',
          'confirm_frames',
          'pending_miss_tolerance',
          'empty_frames_to_rebaseline',
          'cal_shift_threshold',
          'max_darts_per_turn',
          'no_calibration_frames_to_warn',
          'cal_min_confidence',
          'dart_min_confidence',
        ]),
      );
    });

    test('frame + detection + outcome + emission keys', () {
      final frame = _frame(
        0,
        TrackerPhase.tracking,
        detections: const [RawDetection(classIndex: 0, x: 0, y: 0, conf: 1)],
        newDarts: const [
          RecordedEmission(
            handle: 1,
            segment: '20',
            baseNumber: 20,
            multiplier: 1,
            emitted: true,
          ),
        ],
      ).toJson();

      expect(frame.keys,
          unorderedEquals(['kind', 'frame_index', 'detections', 'outcome']));
      expect(
        ((frame['detections'] as List).first as Map).keys,
        unorderedEquals(['class_index', 'x', 'y', 'conf']),
      );
      final outcome = frame['outcome'] as Map;
      expect(
        outcome.keys,
        unorderedEquals(
            ['new_darts', 'phase', 'darts_on_board', 'darts_this_turn']),
      );
      expect(
        ((outcome['new_darts'] as List).first as Map).keys,
        unorderedEquals(
            ['handle', 'segment', 'base_number', 'multiplier', 'emitted']),
      );
    });
  });

  group('fromJsonl validation', () {
    SessionTraceHeader header() => SessionTraceHeader(
          modelVersion: 'm',
          gameId: 'g',
          startedAt: DateTime.utc(2026),
        );

    test('tolerates blank lines', () {
      final jsonl = _sample().toJsonl();
      final withBlanks = '\n${jsonl.replaceAll('\n', '\n\n')}\n';
      expect(SessionTrace.fromJsonl(withBlanks).toJsonl(), jsonl);
    });

    test('throws when empty', () {
      expect(() => SessionTrace.fromJsonl('   \n\n'),
          throwsA(isA<FormatException>()));
    });

    test('throws when the first line is not a header', () {
      final notHeader = jsonEncode(
          const TrackerSegment(instance: 0, config: _config).toJson());
      expect(() => SessionTrace.fromJsonl('$notHeader\n'),
          throwsA(isA<FormatException>()));
    });

    test('throws on an unsupported trace version', () {
      final bad = Map<String, dynamic>.from(header().toJson())
        ..['trace_version'] = kSessionTraceVersion + 1;
      expect(() => SessionTrace.fromJsonl('${jsonEncode(bad)}\n'),
          throwsA(isA<FormatException>()));
    });

    test('skips unknown line kinds (forward-compatibility)', () {
      final jsonl = '${jsonEncode(header().toJson())}\n'
          '${jsonEncode({'kind': 'future_thing', 'whatever': 1})}\n'
          '${jsonEncode(const TrackerSegment(instance: 0, config: _config).toJson())}\n';
      final restored = SessionTrace.fromJsonl(jsonl);
      expect(restored.lines, hasLength(1));
      expect(restored.lines.single, isA<TrackerSegment>());
    });
  });
}
