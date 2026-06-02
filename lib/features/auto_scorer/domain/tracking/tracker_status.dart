/// The tracker's current situation, surfaced to the presentation layer (#382)
/// which renders it as a status chip ("2 darts detected", "camera moved",
/// "turn full"). The tracker emits no UI strings — only this typed state.
enum TrackerPhase {
  /// No calibration this frame — the board is occluded or out of view.
  noCalibration,

  /// Board is empty / no darts tracked yet.
  idle,

  /// Darts are on the board and being tracked normally.
  tracking,

  /// A new dart was detected but the turn already holds the cap — not emitted;
  /// prompt the user to advance (#377 §3.6).
  turnFull,

  /// A large calibration shift was detected → re-baselined, "camera moved".
  cameraMoved,

  /// The board was observed empty long enough to clear the baseline.
  rebaselined,
}

/// Immutable snapshot of tracker state returned with every [TrackerUpdate].
class TrackerStatus {
  final TrackerPhase phase;

  /// Physical darts currently tracked on the board (across turns until a
  /// re-baseline), including any not emitted due to the cap.
  final int dartsOnBoard;

  /// Darts emitted in the current turn (resets on `onTurnAdvanced`).
  final int dartsThisTurn;

  const TrackerStatus({
    required this.phase,
    required this.dartsOnBoard,
    required this.dartsThisTurn,
  });

  @override
  String toString() =>
      'TrackerStatus($phase, onBoard=$dartsOnBoard, thisTurn=$dartsThisTurn)';
}
