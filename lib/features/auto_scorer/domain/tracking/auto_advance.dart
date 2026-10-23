import 'dart_tracker.dart';
import 'tracker_status.dart';

/// Pure decision: should the auto-scorer advance the turn after this frame?
///
/// Fires on a board-clear ([TrackerPhase.rebaselined]) only when the camera
/// EMITTED at least one dart since the gate was last disarmed. Whether the
/// opt-in is on is the caller's check; game-completion / pending-modal guards
/// live in the board's `DartInputSink` implementation — the auto_scorer feature
/// can't read game state directly.
///
/// Why these exact rules (#805):
/// - **Armed by an emission, not by `dartsOnBoard`.** Darts left over from the
///   previous turn (NEXT tapped before pulling them) are still tracked on the
///   board; counting them armed the new turn before anyone threw.
/// - **Every board-clear disarms**, whether or not the game then advanced. A
///   sink can decline (the practice board skips a turn with 0 darts); the arming
///   used to survive that and fire later in the next player's turn — as soon as
///   a hand-added dart lifted the 0-dart guard.
/// - **A hand-added dart never arms it.** A camera that saw no dart this turn
///   can't see the darts being pulled either, so that turn waits for NEXT.
///
/// `rebaselined` also fires when the board sat empty at turn start (a pending
/// sighting alone counts as tracker state), which is why an unarmed clear must
/// never advance.
class AutoAdvanceGate {
  bool _armed = false;

  /// Feed the tracker's update for one frame; true when the turn should
  /// advance.
  bool onFrame(TrackerUpdate update) {
    if (update.newDarts.isNotEmpty) _armed = true;
    switch (update.status.phase) {
      case TrackerPhase.rebaselined:
        final fire = _armed;
        _armed = false;
        return fire;
      case TrackerPhase.cameraMoved:
        _armed = false;
        return false;
      default:
        return false;
    }
  }

  /// The turn advanced (manual NEXT or auto) or the player removed the darts.
  void reset() => _armed = false;
}
