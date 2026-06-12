import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/dartboard_scorer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/scoring/homography.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/detection_frame.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracked_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';

/// What changed after processing one frame: the darts newly confirmed *and
/// emitted* this frame (to be turned into `DartThrown` events by the emission
/// layer, attributed to the current manual turn owner — #382), plus the
/// current [TrackerStatus].
class TrackerUpdate {
  final List<TrackedDart> newDarts;
  final TrackerStatus status;

  const TrackerUpdate({required this.newDarts, required this.status});
}

/// Per-dart **arrival** tracker (#377 §3, #380) — the heart of auto-scoring.
///
/// Detection is per physical dart, not per-frame counting: a later dart can
/// occlude an earlier one (the earlier detection must persist), and an
/// off-board miss is never visible. The tracker keeps a set of confirmed
/// physical darts in **canonical** board space, matches each new detection to
/// it by proximity, and emits a dart only after it persists across
/// [DartTrackerConfig.confirmFrames] frames (confirm-before-emit). It **never**
/// advances the turn — that stays the manual next-turn button; the host calls
/// [onTurnAdvanced] when the user does.
///
/// Pure domain logic: no Flutter / drift / dio, no platform CV. Frames come
/// from the (platform) detector via [DetectionFrame]; turn ownership and event
/// emission live in the presentation layer.
///
/// **Known limitation — a sustained false positive is emitted as a real dart.**
/// By design a confirmed dart is NEVER retracted individually; the only way out
/// of [_confirmed] is a full re-baseline. This is the price of occlusion
/// tolerance (a real dart that a later dart hides for several frames must not be
/// dropped), so we cannot remove a dart just because it stops being detected.
/// The flip side: a model false positive that is *stable* rather than a
/// single-frame flash — a persistent reflection, a board blemish/hole, or a
/// background pattern the model reads as a tip — survives confirm-before-emit
/// and is emitted as a real dart (a wrong score, with no inline confirmation
/// step), then lingers in [_confirmed] (inflating the reported on-board count)
/// until the next clear. This is **inherent to the per-arrival,
/// occlusion-tolerant approach**, not a logic bug, and is mitigated by
/// confirm-before-emit + the configurable dart-confidence floor; assist mode
/// also assumes the user reviews and corrects misreads. The durable fix is
/// model quality (training), not a naive "drop a confirmed dart when it
/// disappears" rule — that would reintroduce the occlusion bug this design
/// exists to avoid. Reviewed and accepted as a won't-fix limitation; do not
/// re-flag without a design that distinguishes "occluded real dart" from
/// "persistent non-dart detection".
class DartTracker {
  DartTracker({DartTrackerConfig config = const DartTrackerConfig()})
      : _config = config;

  final DartTrackerConfig _config;

  /// Image→canonical transform, held stable while the board is occupied and
  /// re-derived only on the first occupied frame after a re-baseline (#377 §3.2
  /// homography stabilisation). Null means "derive from the next frame".
  CanonicalTransform? _transform;

  final List<TrackedDart> _confirmed = [];
  final List<_Pending> _pending = [];

  int _emptyFrames = 0;
  int _noCalFrames = 0;
  int _dartsThisTurn = 0;
  int _nextHandle = 0;
  List<BoardPoint>? _lastCals;

  /// Confirmed physical darts on the board (across turns, until a re-baseline),
  /// including any held back by the 3-dart cap.
  List<TrackedDart> get confirmedDarts => List.unmodifiable(_confirmed);

  /// Darts emitted in the current turn (resets on [onTurnAdvanced]).
  int get dartsThisTurn => _dartsThisTurn;

  /// Process one inference result; returns the darts to emit and the status.
  TrackerUpdate processFrame(DetectionFrame frame) {
    if (!frame.hasCalibration) {
      // Board out of view / occluded: can't map. Keep state untouched. Only a
      // sustained loss with no darts visible (an arm holding a single dart
      // would still surface tips) escalates to the sticky needsCalibration
      // alert; a frame that drops a cal dot but still sees darts is treated as
      // transient occlusion and resets the counter (#377 §5.2).
      if (frame.isEmpty) {
        _noCalFrames++;
      } else {
        _noCalFrames = 0;
      }
      return _statusOnly(_noCalFrames >= _config.noCalibrationFramesToWarn
          ? TrackerPhase.needsCalibration
          : TrackerPhase.noCalibration);
    }
    _noCalFrames = 0;

    // Phone-bump recovery: a large cal-point shift ⇒ desync → re-baseline.
    if (_lastCals != null &&
        _meanShift(_lastCals!, frame.calPoints) > _config.calShiftThreshold) {
      _rebaseline();
      _lastCals = frame.calPoints;
      return _statusOnly(TrackerPhase.cameraMoved);
    }
    _lastCals = frame.calPoints;

    // Empty board: count consecutive empties; clear only after K of them.
    if (frame.isEmpty) {
      _emptyFrames++;
      final hasState =
          _confirmed.isNotEmpty || _pending.isNotEmpty || _transform != null;
      if (_emptyFrames >= _config.emptyFramesToRebaseline && hasState) {
        _rebaseline();
        return _statusOnly(TrackerPhase.rebaselined);
      }
      // Below the threshold this is occlusion, not a clear — keep darts.
      return _statusOnly(
          _confirmed.isEmpty ? TrackerPhase.idle : TrackerPhase.tracking);
    }
    _emptyFrames = 0;

    // Hold the existing homography; derive one only if we don't have it yet.
    _transform ??= canonicalTransform(frame.calPoints);
    final t = _transform!;

    final candidates = [
      for (final c in frame.dartCandidates)
        _normalise(t.homography.apply(c), t.centre, t.radius),
    ];

    // Pass 1: each confirmed dart claims its NEAREST candidate as a re-detection
    // (one-to-one). Driving the match from the confirmed darts — not from the
    // candidates — keeps it independent of the detector's candidate ordering: a
    // confirmed dart always recognises its own re-detection (distance ≈ 0)
    // rather than letting a nearby new dart steal its slot. A confirmed dart
    // absorbs only ONE detection per frame, so a second box landing within
    // matchTolerance of it (a dart thrown into the same bed) is NOT silently
    // swallowed — it falls through to pending below and confirms as its own
    // dart (#454). Without the one-to-one claim a single confirmed dart soaks up
    // every nearby detection and the grouping is under-counted.
    final claimedCandidates = <int>{};
    for (final confirmed in _confirmed) {
      int? nearest;
      var best = double.infinity;
      for (var i = 0; i < candidates.length; i++) {
        if (claimedCandidates.contains(i)) continue;
        final d = _dist(confirmed.boardPosition, candidates[i]);
        if (d <= _config.matchTolerance && d < best) {
          best = d;
          nearest = i;
        }
      }
      if (nearest != null) claimedCandidates.add(nearest); // same dart
    }

    // Pass 2: every candidate not claimed by a confirmed dart is a new or
    // pending dart — match the nearest not-yet-claimed pending candidate.
    final seenPending = <int>{};
    for (var c = 0; c < candidates.length; c++) {
      if (claimedCandidates.contains(c)) continue;
      final cand = candidates[c];
      int? nearest;
      var best = double.infinity;
      for (var i = 0; i < _pending.length; i++) {
        if (seenPending.contains(i)) continue;
        final d = _dist(_pending[i].position, cand);
        if (d <= _config.matchTolerance && d < best) {
          best = d;
          nearest = i;
        }
      }
      if (nearest != null) {
        _pending[nearest]
          ..position = cand
          ..seenCount += 1
          ..missCount = 0;
        seenPending.add(nearest);
      } else {
        _pending.add(_Pending(cand));
        seenPending.add(_pending.length - 1);
      }
    }

    // Age pendings that weren't seen this frame; drop stale ones.
    for (var i = 0; i < _pending.length; i++) {
      if (!seenPending.contains(i)) _pending[i].missCount += 1;
    }
    _pending.removeWhere((p) => p.missCount > _config.pendingMissTolerance);

    // Confirm pendings that have persisted long enough.
    final newDarts = <TrackedDart>[];
    for (final p in _pending.where((p) => p.seenCount >= _config.confirmFrames)) {
      final score = scoreDartAt(p.position.x, p.position.y, 1.0);
      final canEmit = _dartsThisTurn < _config.maxDartsPerTurn;
      final dart = TrackedDart(
        handle: _nextHandle++,
        boardPosition: p.position,
        score: score,
        emitted: canEmit,
      );
      _confirmed.add(dart);
      if (canEmit) {
        _dartsThisTurn++;
        newDarts.add(dart);
      }
    }
    _pending.removeWhere((p) => p.seenCount >= _config.confirmFrames);

    return TrackerUpdate(newDarts: newDarts, status: _status(_occupiedPhase()));
  }

  /// Manual "remove darts" button: clear the baseline and re-derive the
  /// homography on the next occupied frame (#377 §3). Does not advance the turn.
  TrackerUpdate removeDarts() {
    _rebaseline();
    return _statusOnly(TrackerPhase.rebaselined);
  }

  /// Called when the user presses the manual next-turn button. Resets only the
  /// per-turn cap counter; physical darts on the board are untouched (they stay
  /// tracked until pulled / re-baselined).
  void onTurnAdvanced() => _dartsThisTurn = 0;

  void _rebaseline() {
    _confirmed.clear();
    _pending.clear();
    _transform = null;
    _emptyFrames = 0;
  }

  TrackerUpdate _statusOnly(TrackerPhase phase) =>
      TrackerUpdate(newDarts: const [], status: _status(phase));

  /// Phase for an occupied board: `turnFull` for as long as an over-cap dart is
  /// physically present (a confirmed dart held back by the 3-dart cap), so the
  /// "turn full — advance?" prompt persists until the board is re-baselined —
  /// not just the single frame the 4th dart confirmed (#377 §3.6).
  TrackerPhase _occupiedPhase() {
    if (_confirmed.any((d) => !d.emitted)) return TrackerPhase.turnFull;
    return _confirmed.isEmpty ? TrackerPhase.idle : TrackerPhase.tracking;
  }

  TrackerStatus _status(TrackerPhase phase) => TrackerStatus(
        phase: phase,
        dartsOnBoard: _confirmed.length,
        dartsThisTurn: _dartsThisTurn,
      );

  /// Normalise a canonical point to board-radius units relative to [centre], so
  /// tolerances read as fractions of the board radius and scoring uses
  /// `rDouble = 1.0`.
  BoardPoint _normalise(BoardPoint p, BoardPoint centre, double radius) =>
      (x: (p.x - centre.x) / radius, y: (p.y - centre.y) / radius);

  double _dist(BoardPoint a, BoardPoint b) =>
      math.sqrt(_sq(a.x - b.x) + _sq(a.y - b.y));

  double _meanShift(List<BoardPoint> a, List<BoardPoint> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += math.sqrt(_sq(a[i].x - b[i].x) + _sq(a[i].y - b[i].y));
    }
    return sum / a.length;
  }

  static double _sq(double v) => v * v;
}

/// A candidate dart seen but not yet confirmed: its latest canonical position,
/// how many frames it has been sighted, and how many it has gone unseen.
class _Pending {
  _Pending(this.position);

  BoardPoint position;
  int seenCount = 1;
  int missCount = 0;
}
