import 'package:audioplayers/audioplayers.dart';

import '../domain/sound_player.dart';

/// `audioplayers`-backed [SoundPlayer]. Cross-platform (web + mobile) with no
/// special headers — no `dart.library.io` conditional needed.
///
/// Keeps one reusable [AudioPlayer] per asset (low-latency mode, source kept
/// resident via [ReleaseMode.stop]) and replays via `seek(0)` + `resume` so
/// sparse darts SFX fire without re-decoding. Every operation is wrapped in
/// `try/catch` that swallows errors: a failed or missing sound must never
/// disrupt scoring (same rule as the auto-scorer capture pipeline).
class AudioPlayersSoundPlayer implements SoundPlayer {
  final Map<String, AudioPlayer> _players = {};

  Future<AudioPlayer> _loadPlayer(String asset) async {
    final player = AudioPlayer();
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(asset));
    _players[asset] = player;
    return player;
  }

  @override
  Future<void> preload(Iterable<String> assets) async {
    for (final asset in assets) {
      try {
        await _loadPlayer(asset);
      } catch (_) {
        // Swallow — a sound that fails to preload simply won't play.
      }
    }
  }

  @override
  Future<void> play(String asset) async {
    try {
      // Lazily load (and cache) if preload hasn't run/finished yet, so the
      // player is reused and torn down by [dispose] — never leaked.
      final player = _players[asset] ?? await _loadPlayer(asset);
      await player.seek(Duration.zero);
      await player.resume();
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
