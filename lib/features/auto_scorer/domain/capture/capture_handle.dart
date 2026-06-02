/// Stable identity of a capture within a game: the `(turn ordinal, dart-in-turn
/// ordinal)` pair (#381).
///
/// Frames key on this — **not** on the `DartThrown.eventId`, which churns when
/// per-dart correction rewinds-and-replays the tail (#376 §3.1). A correction
/// therefore still finds its captured frame by handle even after the event id
/// it originally emitted has been superseded.
class CaptureHandle {
  /// 1-based turn (full-rotation) ordinal within the game.
  final int turnOrdinal;

  /// 1-based dart ordinal within the turn (1..3).
  final int dartInTurnOrdinal;

  const CaptureHandle({
    required this.turnOrdinal,
    required this.dartInTurnOrdinal,
  });

  /// Filesystem/JSON-safe key, e.g. `t3-d2`.
  String get key => 't$turnOrdinal-d$dartInTurnOrdinal';

  factory CaptureHandle.parse(String key) {
    final match = RegExp(r'^t(\d+)-d(\d+)$').firstMatch(key);
    if (match == null) {
      throw FormatException('Invalid capture handle key: $key');
    }
    return CaptureHandle(
      turnOrdinal: int.parse(match.group(1)!),
      dartInTurnOrdinal: int.parse(match.group(2)!),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptureHandle &&
          other.turnOrdinal == turnOrdinal &&
          other.dartInTurnOrdinal == dartInTurnOrdinal);

  @override
  int get hashCode => Object.hash(turnOrdinal, dartInTurnOrdinal);

  @override
  String toString() => 'CaptureHandle($key)';
}
