/// Feature-agnostic sound cues requested via [SoundPort].
///
/// `cricketSingleMark`/`cricketTripleMark` are the cricket per-mark ticks: the
/// cricket board picks them from the marks a dart actually scored (see
/// `cricketDartOutcome`), rather than via the generic `dartThrown` mapping.
enum SoundCue {
  dartHit,
  dartMiss,
  bust,
  cricketSingleMark,
  cricketTripleMark,
  achievementUnlock,
}
