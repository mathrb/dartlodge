import 'dart:math' as math;

import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// Upper bound on a normalised dart radius before it is treated as detection
/// noise (#572). The double ring sits at `r = 1.0`; a genuine miss outside it
/// keeps a radius slightly above `1.0` (useful miss patterns), but anything
/// past this threshold is far enough off-board to be a spurious detection — its
/// position is discarded (the segment is still kept by the caller).
const double kDartNoiseRadius = 1.5;

/// Normalise a tracker dart's canonical [boardPosition] into the stable
/// heatmap frame: origin `(0,0)` at the board centre, radius `1.0` at the outer
/// edge of the double ring, "20 at top" — the same frame the scorer already
/// classifies in.
///
/// IMPORTANT (#572 /plan finding): [DartTracker] already normalises
/// `TrackedDart.boardPosition` to this exact frame before scoring — it applies
/// `(p - centre) / radius` when building candidates (so `scoreDartAt(..., 1.0)`
/// reads `rDouble = 1.0`). The design doc's `x = (pos.x - centre.x) / radius`
/// describes the normalisation the tracker has *already performed*; applying it
/// a second time would double-normalise. This function therefore takes the
/// already-canonical [boardPosition] verbatim and only applies the noise guard.
///
/// Returns the normalised `(x, y)`, or `null` when the dart's radius exceeds
/// [kDartNoiseRadius] (detection noise — caller keeps the segment, drops the
/// position). Pure Dart, domain layer.
({double x, double y})? normaliseDartPosition(BoardPoint boardPosition) {
  final r = math.sqrt(
      boardPosition.x * boardPosition.x + boardPosition.y * boardPosition.y);
  if (r > kDartNoiseRadius) return null;
  return (x: boardPosition.x, y: boardPosition.y);
}
