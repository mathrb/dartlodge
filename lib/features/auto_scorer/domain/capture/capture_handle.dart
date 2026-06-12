/// Stable identity of a capture within a game (#381).
///
/// Three kinds:
/// - **dart capture** — keyed by `(turn ordinal, dart-in-turn ordinal)`, e.g.
///   `t3-d2`. Keyed this way, **not** by the `DartThrown.eventId`, which churns
///   when per-dart correction rewinds-and-replays the tail (#376 §3.1).
/// - **manual capture** — a user-forced "capture this frame" (#382), keyed by a
///   per-session sequence within the turn, e.g. `t3-m1`. Used to grab frames the
///   model *missed* (no dart was emitted) — the highest-value training samples.
/// - **corrected capture** — a capture-at-correction in partial mode (#457),
///   keyed by a per-session sequence, e.g. `t3-c1`. A monotonic sequence (not
///   `(turn, dart)`) because the overlay's turn proxy doesn't track the game's
///   internal turn advances, so `(turn, dart)` collides and `save` would
///   overwrite — every correction must yield its own frame (#468 follow-up).
class CaptureHandle {
  /// 1-based turn (full-rotation) ordinal within the game.
  final int turnOrdinal;

  /// 1-based dart ordinal within the turn (1..3). Ignored for manual/corrected
  /// captures.
  final int dartInTurnOrdinal;

  /// Non-null ⇒ this is a manual force-capture (a per-session sequence number).
  final int? manualSequence;

  /// Non-null ⇒ this is a capture-at-correction (a per-session sequence number).
  final int? correctedSequence;

  const CaptureHandle({
    required this.turnOrdinal,
    required this.dartInTurnOrdinal,
  })  : manualSequence = null,
        correctedSequence = null;

  const CaptureHandle.manual({
    required this.turnOrdinal,
    required int sequence,
  })  : dartInTurnOrdinal = 0,
        manualSequence = sequence,
        correctedSequence = null;

  const CaptureHandle.corrected({
    required this.turnOrdinal,
    required int sequence,
  })  : dartInTurnOrdinal = 0,
        manualSequence = null,
        correctedSequence = sequence;

  /// Filesystem/JSON-safe key, e.g. `t3-d2` (dart), `t3-m1` (manual), or
  /// `t3-c1` (corrected).
  String get key {
    if (manualSequence != null) return 't$turnOrdinal-m$manualSequence';
    if (correctedSequence != null) return 't$turnOrdinal-c$correctedSequence';
    return 't$turnOrdinal-d$dartInTurnOrdinal';
  }

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
    final corrected = RegExp(r'^t(\d+)-c(\d+)$').firstMatch(key);
    if (corrected != null) {
      return CaptureHandle.corrected(
        turnOrdinal: int.parse(corrected.group(1)!),
        sequence: int.parse(corrected.group(2)!),
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
          other.manualSequence == manualSequence &&
          other.correctedSequence == correctedSequence);

  @override
  int get hashCode =>
      Object.hash(turnOrdinal, dartInTurnOrdinal, manualSequence, correctedSequence);

  @override
  String toString() => 'CaptureHandle($key)';
}
