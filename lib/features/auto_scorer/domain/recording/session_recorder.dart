import 'package:dart_lodge/features/auto_scorer/domain/detection/raw_detection.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';

/// Accumulates one auto-scorer session into a [SessionTrace] (epic #488,
/// sub-issue #490). Pure domain, append-only, O(1) per frame and no I/O — the
/// device persists the built trace when the session ends, off the hot path.
///
/// Construction emits the initial [TrackerSegment] (instance 0) carrying the
/// tracker's config; each [recordFrame] appends a [TraceFrame] with the raw
/// detections + the thresholds applied to them + the tracker's resulting
/// outcome (emissions and status), which is the channel the replay asserts
/// against to prove it reproduced the device session.
class SessionRecorder {
  SessionRecorder({
    required SessionTraceHeader header,
    required DartTrackerConfig config,
  }) : _header = header {
    _lines.add(TrackerSegment(instance: 0, config: config));
  }

  final SessionTraceHeader _header;
  final List<SessionTraceLine> _lines = [];
  int _frameIndex = 0;

  /// Frames recorded so far (excludes the initial segment marker).
  int get frameCount => _frameIndex;

  /// Append one processed frame: the raw (pre-filter) [detections] fed to the
  /// tracker, the [calMinConfidence]/[dartMinConfidence] applied to them in
  /// `buildDetectionFrame`, and the tracker's [update].
  void recordFrame({
    required List<RawDetection> detections,
    required double calMinConfidence,
    required double dartMinConfidence,
    required TrackerUpdate update,
  }) {
    _lines.add(TraceFrame(
      frameIndex: _frameIndex++,
      calMinConfidence: calMinConfidence,
      dartMinConfidence: dartMinConfidence,
      // Defensive copy — the caller builds a fresh list per frame, but never
      // alias a buffer into the trace.
      detections: List<RawDetection>.of(detections),
      outcome: RecordedOutcome(
        newDarts: [
          for (final d in update.newDarts)
            RecordedEmission(
              handle: d.handle,
              segment: d.score.segment,
              baseNumber: d.score.baseNumber,
              multiplier: d.score.multiplier,
              emitted: d.emitted,
            ),
        ],
        status: update.status,
      ),
    ));
  }

  /// Snapshot the accumulated session as an immutable [SessionTrace].
  SessionTrace build() =>
      SessionTrace(header: _header, lines: List<SessionTraceLine>.of(_lines));
}
