// Dart Position Entity
// A raw recorded dart position for the impact heatmap (#576).
//
// These are RAW per-dart facts read directly from `dart_throws` (WHERE x IS
// NOT NULL) — NOT a computed statistic, so they are never routed through
// `PlayerStatsAssembler`. Coordinates are normalised in the canonical board
// frame: origin (0,0) = bullseye, radius 1.0 = outer edge of the double ring,
// "20 up". A miss outside the double has r > 1.0. See
// `docs/plans/2026-06-19-heatmap-design.md`.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dart_position.freezed.dart';

@freezed
abstract class DartPosition with _$DartPosition {
  const factory DartPosition({
    required double x,
    required double y,
    String? segment,
  }) = _DartPosition;
}
