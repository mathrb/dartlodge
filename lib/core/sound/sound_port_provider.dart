import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sound_cue.dart';
import 'sound_port.dart';

part 'sound_port_provider.g.dart';

/// Default no-op port. The composition root overrides this with the real
/// [SoundPort] impl. Under `flutter test` the no-op is used as-is, so nothing
/// plays. Mirrors the `boardOverlayBuilder` seam.
///
/// `keepAlive`: the real impl holds a preloaded audio player; without it the
/// provider would dispose (tearing down + re-preloading the player) whenever
/// the last board listener drops on navigation.
@Riverpod(keepAlive: true)
SoundPort soundPort(Ref ref) => const _NoopSoundPort();

class _NoopSoundPort implements SoundPort {
  const _NoopSoundPort();

  @override
  void play(SoundCue cue) {}

  @override
  void dartThrown(String segment) {}
}
