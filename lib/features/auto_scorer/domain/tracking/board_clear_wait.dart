import 'dart_tracker_config.dart';

/// How long the board must read empty before an auto-advance (#800).
///
/// Each preset is a count of consecutive empty calibrated frames
/// ([DartTrackerConfig.emptyFramesToRebaseline]); at the production inference
/// rate (`kAutoScorerInferenceHz` = 3) that is ≈1.7 s / 2 s / 3 s. The floor is
/// [fast] = 5: the #499 recording (`single_dart_d11_flicker.json`) holds a
/// transient dart-detection dropout of up to 4 frames on a board whose dart was
/// never pulled, so anything shorter would bring back the premature advance.
/// Presets rather than a free slider so no value can go below that floor.
enum BoardClearWait {
  fast(5),
  normal(6),
  safe(9);

  const BoardClearWait(this.frames);

  /// Consecutive empty calibrated frames before the board counts as cleared.
  final int frames;
}

/// The tracker's board-clear window for a session.
///
/// The preset only applies when auto-advance is on — that's the one flow where
/// a shorter window buys anything. With auto-advance off a board-clear just
/// rebaselines the tracker, so it keeps the conservative default and takes on
/// none of the #499 double-count risk.
int emptyFramesToRebaselineFor({
  required bool autoAdvance,
  required BoardClearWait wait,
}) =>
    autoAdvance
        ? wait.frames
        : const DartTrackerConfig().emptyFramesToRebaseline;
