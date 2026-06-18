import 'sound_cue.dart';

/// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
/// that lets the game — and a future achievements epic — request a sound without
/// importing the `sound` feature. The composition root (`main.dart`) overrides
/// [soundPortProvider] with the real service; the default is a no-op.
abstract interface class SoundPort {
  /// Generic cues (e.g. bust; future achievementUnlock).
  void play(SoundCue cue);

  /// Reports a thrown dart by segment (e.g. 'T20', 'MISS'); the service maps
  /// it to hit/miss (and, in v2, to the segment caller / dedicated sounds).
  void dartThrown(String segment);
}
