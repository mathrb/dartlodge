/// A recorded auto-scorer session — the per-frame **input** to the tracker plus
/// the **observed outcome** — serialised as JSONL so it can be replayed
/// deterministically in a plain `flutter test` (epic #488, sub-issue #489).
///
/// The whole `RawDetection → buildDetectionFrame → DartTracker → DartboardScorer`
/// chain is pure domain Dart with no time/random dependency, so feeding a
/// recorded [TraceFrame.detections] stream into a fresh tracker reproduces a
/// device session bit-for-bit. We record the **raw** detections (the model's
/// pre-filter output) rather than the post-filter `DetectionFrame`, so the
/// replay re-runs `buildDetectionFrame` with the recorded thresholds and a
/// too-aggressive confidence threshold (#402) stays reproducible.
///
/// This file owns the wire contract and **all** (de)serialisation — the reused
/// domain types ([RawDetection], [DartTrackerConfig], [TrackerStatus]) stay
/// untouched. Plain immutable classes with manual JSON (mirroring
/// `CaptureRecord`) — no freezed, no build_runner.
///
/// Wire layout (one JSON object per line):
/// - line 1: a `header` (schema version + session metadata),
/// - `tracker` markers: a tracker-instance boundary carrying the config in
///   force (the first is the initial instance; later ones mark a mid-session
///   re-creation so a single-fresh-tracker replay can re-align),
/// - `frame` records: the raw detections + observed tracker outcome.
///
/// Timestamps are **metadata only** — replay depends solely on frame
/// order/count, never on the clock.
library;

import 'dart:convert';

import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';

/// Current on-disk schema version. Bump on an incompatible wire change;
/// [SessionTrace.fromJsonl] rejects versions it does not understand.
const int kSessionTraceVersion = 1;

/// Stable wire strings for [TrackerPhase]. Kept explicit (not `enum.name`) so a
/// rename in the tracking layer can't silently corrupt recorded traces.
const Map<TrackerPhase, String> _phaseWire = {
  TrackerPhase.noCalibration: 'no_calibration',
  TrackerPhase.needsCalibration: 'needs_calibration',
  TrackerPhase.idle: 'idle',
  TrackerPhase.tracking: 'tracking',
  TrackerPhase.turnFull: 'turn_full',
  TrackerPhase.cameraMoved: 'camera_moved',
  TrackerPhase.rebaselined: 'rebaselined',
};

String _phaseToWire(TrackerPhase phase) => _phaseWire[phase]!;

TrackerPhase _phaseFromWire(String wire) {
  for (final entry in _phaseWire.entries) {
    if (entry.value == wire) return entry.key;
  }
  throw FormatException('Unknown tracker phase: $wire');
}

double _toDouble(Object? value) => (value as num).toDouble();

Map<String, dynamic> _rawDetectionToJson(RawDetection d) => {
      'class_index': d.classIndex,
      'x': d.x,
      'y': d.y,
      'conf': d.conf,
    };

RawDetection _rawDetectionFromJson(Map<String, dynamic> json) => RawDetection(
      classIndex: json['class_index'] as int,
      x: _toDouble(json['x']),
      y: _toDouble(json['y']),
      conf: _toDouble(json['conf']),
    );

/// Session-level header: schema version + the metadata needed to interpret a
/// trace (which model produced it, which game, when).
class SessionTraceHeader {
  final int traceVersion;
  final String modelVersion;
  final String gameId;

  /// When recording started — diagnostic metadata only; never load-bearing for
  /// replay.
  final DateTime startedAt;

  const SessionTraceHeader({
    required this.modelVersion,
    required this.gameId,
    required this.startedAt,
    this.traceVersion = kSessionTraceVersion,
  });

  Map<String, dynamic> toJson() => {
        'kind': 'header',
        'trace_version': traceVersion,
        'model_version': modelVersion,
        'game_id': gameId,
        'started_at': startedAt.toIso8601String(),
      };

  factory SessionTraceHeader.fromJson(Map<String, dynamic> json) =>
      SessionTraceHeader(
        traceVersion: json['trace_version'] as int,
        modelVersion: json['model_version'] as String,
        gameId: json['game_id'] as String,
        startedAt: DateTime.parse(json['started_at'] as String),
      );
}

/// Codec for [DartTrackerConfig] — the tracker's own knobs, genuinely constant
/// per tracker instance, so they live on the [TrackerSegment] marker. The
/// confidence thresholds applied in `buildDetectionFrame` are NOT here: they can
/// vary frame-to-frame (the live preview re-reads them from a provider), so they
/// live per-frame on [TraceFrame] instead.
Map<String, dynamic> _trackerConfigToJson(DartTrackerConfig c) => {
      'match_tolerance': c.matchTolerance,
      'confirm_frames': c.confirmFrames,
      'pending_miss_tolerance': c.pendingMissTolerance,
      'empty_frames_to_rebaseline': c.emptyFramesToRebaseline,
      'cal_shift_threshold': c.calShiftThreshold,
      'max_darts_per_turn': c.maxDartsPerTurn,
      'no_calibration_frames_to_warn': c.noCalibrationFramesToWarn,
    };

DartTrackerConfig _trackerConfigFromJson(Map<String, dynamic> json) =>
    DartTrackerConfig(
      matchTolerance: _toDouble(json['match_tolerance']),
      confirmFrames: json['confirm_frames'] as int,
      pendingMissTolerance: json['pending_miss_tolerance'] as int,
      emptyFramesToRebaseline: json['empty_frames_to_rebaseline'] as int,
      calShiftThreshold: _toDouble(json['cal_shift_threshold']),
      maxDartsPerTurn: json['max_darts_per_turn'] as int,
      noCalibrationFramesToWarn: json['no_calibration_frames_to_warn'] as int,
    );

/// One dart the tracker reported newly (a `TrackedDart` from `TrackerUpdate`).
/// `emitted` is false when the dart was confirmed but blocked by the 3-dart cap.
/// Canonical board position is omitted — it is derived by the replay; this is a
/// verification channel, not a second source of truth.
class RecordedEmission {
  final int handle;
  final String segment;
  final int baseNumber;
  final int multiplier;
  final bool emitted;

  const RecordedEmission({
    required this.handle,
    required this.segment,
    required this.baseNumber,
    required this.multiplier,
    required this.emitted,
  });

  Map<String, dynamic> toJson() => {
        'handle': handle,
        'segment': segment,
        'base_number': baseNumber,
        'multiplier': multiplier,
        'emitted': emitted,
      };

  factory RecordedEmission.fromJson(Map<String, dynamic> json) =>
      RecordedEmission(
        handle: json['handle'] as int,
        segment: json['segment'] as String,
        baseNumber: json['base_number'] as int,
        multiplier: json['multiplier'] as int,
        emitted: json['emitted'] as bool,
      );
}

/// The tracker's observed outcome for a frame: the newly reported darts plus
/// the [TrackerStatus] snapshot. Recorded so replay can assert it reproduces
/// the device output exactly (the fidelity proof).
class RecordedOutcome {
  final List<RecordedEmission> newDarts;
  final TrackerStatus status;

  const RecordedOutcome({required this.newDarts, required this.status});

  Map<String, dynamic> toJson() => {
        'new_darts': [for (final d in newDarts) d.toJson()],
        'phase': _phaseToWire(status.phase),
        'darts_on_board': status.dartsOnBoard,
        'darts_this_turn': status.dartsThisTurn,
      };

  factory RecordedOutcome.fromJson(Map<String, dynamic> json) => RecordedOutcome(
        newDarts: [
          for (final d in (json['new_darts'] as List))
            RecordedEmission.fromJson(d as Map<String, dynamic>)
        ],
        status: TrackerStatus(
          phase: _phaseFromWire(json['phase'] as String),
          dartsOnBoard: json['darts_on_board'] as int,
          dartsThisTurn: json['darts_this_turn'] as int,
        ),
      );
}

/// A tracker mutation that happens **outside** the frame stream: the turn
/// advanced (resets the per-turn dart cap) or the user removed the darts
/// (re-baseline). Recorded interleaved with frames so a replay reproduces the
/// cap / baseline behaviour across turns — without these, a multi-turn replay
/// diverges once the cap counter drifts (#491).
enum TrackerSignalKind {
  turnAdvanced('turn_advanced'),
  removeDarts('remove_darts');

  const TrackerSignalKind(this.wire);

  final String wire;

  static TrackerSignalKind fromWire(String value) =>
      values.firstWhere((k) => k.wire == value,
          orElse: () =>
              throw FormatException('Unknown tracker signal: $value'));
}

/// A single line in a session trace, after the header: a [TrackerSegment]
/// boundary, a [TraceFrame], or a [TrackerSignal].
sealed class SessionTraceLine {
  const SessionTraceLine();

  Map<String, dynamic> toJson();
}

/// An out-of-band tracker signal (turn advance / remove darts) recorded between
/// frames. See [TrackerSignalKind].
class TrackerSignal extends SessionTraceLine {
  final TrackerSignalKind kind;

  const TrackerSignal(this.kind);

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'signal',
        'signal': kind.wire,
      };

  factory TrackerSignal.fromJson(Map<String, dynamic> json) =>
      TrackerSignal(TrackerSignalKind.fromWire(json['signal'] as String));
}

/// A tracker-instance boundary (the epic's "reset marker"). The first marks the
/// initial instance; subsequent ones mark a mid-session re-creation, carrying
/// the [DartTrackerConfig] in force from that point. Replay starts a fresh
/// `DartTracker` at each marker. Confidence thresholds are NOT here — they live
/// per-frame on [TraceFrame].
class TrackerSegment extends SessionTraceLine {
  /// 0-based, increments each time the live tracker is (re)created.
  final int instance;
  final DartTrackerConfig config;

  const TrackerSegment({required this.instance, required this.config});

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'tracker',
        'instance': instance,
        'config': _trackerConfigToJson(config),
      };

  factory TrackerSegment.fromJson(Map<String, dynamic> json) => TrackerSegment(
        instance: json['instance'] as int,
        config: _trackerConfigFromJson(json['config'] as Map<String, dynamic>),
      );
}

/// One recorded frame: the raw (pre-filter) detections fed to the tracker, the
/// confidence thresholds applied to them in `buildDetectionFrame` (recorded
/// per-frame because the live preview can change them mid-session), and the
/// observed outcome. [frameIndex] is monotonic within the session.
class TraceFrame extends SessionTraceLine {
  final int frameIndex;
  final double calMinConfidence;
  final double dartMinConfidence;
  final List<RawDetection> detections;
  final RecordedOutcome outcome;

  const TraceFrame({
    required this.frameIndex,
    required this.calMinConfidence,
    required this.dartMinConfidence,
    required this.detections,
    required this.outcome,
  });

  @override
  Map<String, dynamic> toJson() => {
        'kind': 'frame',
        'frame_index': frameIndex,
        'cal_min_confidence': calMinConfidence,
        'dart_min_confidence': dartMinConfidence,
        'detections': [for (final d in detections) _rawDetectionToJson(d)],
        'outcome': outcome.toJson(),
      };

  factory TraceFrame.fromJson(Map<String, dynamic> json) => TraceFrame(
        frameIndex: json['frame_index'] as int,
        calMinConfidence: _toDouble(json['cal_min_confidence']),
        dartMinConfidence: _toDouble(json['dart_min_confidence']),
        detections: [
          for (final d in (json['detections'] as List))
            _rawDetectionFromJson(d as Map<String, dynamic>)
        ],
        outcome: RecordedOutcome.fromJson(json['outcome'] as Map<String, dynamic>),
      );
}

/// A recorded auto-scorer session: a [SessionTraceHeader] plus ordered
/// [SessionTraceLine]s (tracker markers + frames).
class SessionTrace {
  final SessionTraceHeader header;
  final List<SessionTraceLine> lines;

  const SessionTrace({required this.header, required this.lines});

  /// Serialise to JSONL — one JSON object per line, header first.
  String toJsonl() {
    final buffer = StringBuffer();
    buffer.writeln(jsonEncode(header.toJson()));
    for (final line in lines) {
      buffer.writeln(jsonEncode(line.toJson()));
    }
    return buffer.toString();
  }

  /// Parse a JSONL trace. Blank lines are tolerated. Throws [FormatException]
  /// if the first non-blank line is not a `header`, or the schema version is
  /// not understood. Unknown line kinds are skipped (forward-compatibility).
  factory SessionTrace.fromJsonl(String jsonl) {
    final rawLines = const LineSplitter()
        .convert(jsonl)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (rawLines.isEmpty) {
      throw const FormatException('Empty session trace (no header line).');
    }

    final first = jsonDecode(rawLines.first) as Map<String, dynamic>;
    if (first['kind'] != 'header') {
      throw const FormatException(
          'Session trace must start with a header line.');
    }
    final header = SessionTraceHeader.fromJson(first);
    if (header.traceVersion != kSessionTraceVersion) {
      throw FormatException(
        'Unsupported session-trace version ${header.traceVersion} '
        '(expected $kSessionTraceVersion).',
      );
    }

    final lines = <SessionTraceLine>[];
    for (final raw in rawLines.skip(1)) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      switch (json['kind']) {
        case 'tracker':
          lines.add(TrackerSegment.fromJson(json));
        case 'signal':
          lines.add(TrackerSignal.fromJson(json));
        case 'frame':
          lines.add(TraceFrame.fromJson(json));
        default:
          // Forward-compatibility: silently skip unknown line kinds.
          break;
      }
    }
    return SessionTrace(header: header, lines: lines);
  }
}
