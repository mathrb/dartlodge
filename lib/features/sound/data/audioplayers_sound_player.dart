import 'package:audioplayers/audioplayers.dart';

import '../domain/sound_player.dart';

/// `audioplayers`-backed [SoundPlayer]. Cross-platform (web + mobile) with no
/// special headers — no `dart.library.io` conditional needed.
///
/// Keeps one reusable [AudioPlayer] per asset and fires it with
/// `play(AssetSource)` — the canonical "play from the start" call that works
/// across every backend. (An earlier `seek(0)` + `resume()` replay was silent
/// on Android, whose low-latency SoundPool backend does not support `seek` — see
/// the `PlayerMode.lowLatency` docs — so the cue was dropped.) Default media-
/// player mode; the decode latency is negligible for sparse darts SFX. Every
/// operation is wrapped in `try/catch` that swallows errors: a failed or missing
/// sound must never disrupt scoring (same rule as the auto-scorer capture
/// pipeline).
class AudioPlayersSoundPlayer implements SoundPlayer {
  final Map<String, AudioPlayer> _players = {};

  // ReleaseMode.stop keeps the source resident after a clip finishes, so the
  // next play() reuses the prepared player instead of re-decoding from assets.
  AudioPlayer _playerFor(String asset) =>
      _players[asset] ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  @override
  Future<void> preload(Iterable<String> assets) async {
    for (final asset in assets) {
      try {
        // Warm the asset (decode + cache) so the first play is snappy.
        await _playerFor(asset).setSource(AssetSource(asset));
      } catch (_) {
        // Swallow — a sound that fails to preload simply won't play.
      }
    }
  }

  @override
  Future<void> play(String asset) async {
    try {
      await _playerFor(asset).play(AssetSource(asset));
    } catch (_) {
      // Swallow — sound never disrupts scoring.
    }
  }

  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {
        // Swallow.
      }
    }
    _players.clear();
  }
}
