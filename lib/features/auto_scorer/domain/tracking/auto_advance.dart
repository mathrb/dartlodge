import 'tracker_status.dart';

/// Pure decision: should the auto-scorer advance the turn after this frame?
///
/// True only on a board-clear ([TrackerPhase.rebaselined]) when at least one
/// dart was seen on the board this turn and the opt-in is on. The
/// `sawDartsThisTurn` guard is essential: `rebaselined` also fires when the
/// board sat empty at turn start (a calibration transform alone counts as
/// tracker state), so without it we'd skip players who haven't thrown yet.
///
/// Game-completion / pending-modal guards live in the board's [DartInputSink]
/// implementation — the auto_scorer feature can't read game state directly.
bool shouldAutoAdvance({
  required TrackerPhase phase,
  required bool sawDartsThisTurn,
  required bool enabled,
}) =>
    enabled && sawDartsThisTurn && phase == TrackerPhase.rebaselined;
