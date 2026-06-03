/// Stable identity of a capture within a game (#381).
///
/// Two kinds:
/// - **dart capture** — keyed by `(turn ordinal, dart-in-turn ordinal)`, e.g.
///   `t3-d2`. Keyed this way, **not** by the `DartThrown.eventId`, which churns
///   when per-dart correction rewinds-and-replays the tail (#376 §3.1).
/// - **manual capture** — a user-forced "capture this frame" (#382), keyed by a
///   per-session sequence within the turn, e.g. `t3-m1`. Used to grab frames the
///   model *missed* (no dart was emitted) — the highest-value training samples.
class CaptureHandle {
  /// 1-based turn (full-rotation) ordinal within the game.
  final int turnOrdinal;

  /// 1-based dart ordinal within the turn (1..3). Ignored for manual captures.
  final int dartInTurnOrdinal;

  /// Non-null ⇒ this is a manual force-capture (a per-session sequence number).
  final int? manualSequence;

  const CaptureHandle({
    required this.turnOrdinal,
    required this.dartInTurnOrdinal,
  }) : manualSequence = null;

  const CaptureHandle.manual({
    required this.turnOrdinal,
    required int sequence,
  })  : dartInTurnOrdinal = 0,
        manualSequence = sequence;

  /// Filesystem/JSON-safe key, e.g. `t3-d2` (dart) or `t3-m1` (manual).
  String get key => manualSequence == null
      ? 't$turnOrdinal-d$dartInTurnOrdinal'
      : 't$turnOrdinal-m$manualSequence';

  factory CaptureHandle.parse(String key) {
    final dart = RegExp(r'^t(\d+)-d(\d+)$').firstMatch(key);
    if (dart != null) {
      return CaptureHandle(
        turnOrdinal: int.parse(dart.group(1)!),
        dartInTurnOrdinal: int.parse(dart.group(2)!),
      );
    }
    final manual = RegExp(r'^t(\d+)-m(\d+)$').firstMatch(key);
    if (manual != null) {
      return CaptureHandle.manual(
        turnOrdinal: int.parse(manual.group(1)!),
        sequence: int.parse(manual.group(2)!),
      );
    }
    throw FormatException('Invalid capture handle key: $key');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptureHandle &&
          other.turnOrdinal == turnOrdinal &&
          other.dartInTurnOrdinal == dartInTurnOrdinal &&
          other.manualSequence == manualSequence);

  @override
  int get hashCode => Object.hash(turnOrdinal, dartInTurnOrdinal, manualSequence);

  @override
  String toString() => 'CaptureHandle($key)';
}
