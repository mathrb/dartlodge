/// Low-level audio playback abstraction, decoupling [SoundService] from the
/// concrete audio package. The real impl ([AudioPlayersSoundPlayer]) wraps
/// `audioplayers`; tests substitute a fake. Pure Dart — no Flutter, no plugin.
abstract interface class SoundPlayer {
  /// Pre-loads the given assets so the first [play] has no decode latency.
  /// `assets` are audioplayers-relative paths (e.g. `'sounds/dartHit.mp3'`).
  Future<void> preload(Iterable<String> assets);

  /// Plays a single asset (audioplayers-relative path). A missing asset or
  /// playback failure must be swallowed — sound never disrupts scoring.
  Future<void> play(String asset);

  /// Releases all underlying audio resources.
  Future<void> dispose();
}
