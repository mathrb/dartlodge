import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sound_cue.dart';
import 'sound_port.dart';

part 'sound_port_provider.g.dart';

/// Default no-op port. The composition root overrides this with the real
/// [SoundPort] impl (SI-2). Under `flutter test` the no-op is used as-is, so
/// nothing plays. Mirrors the `boardOverlayBuilder` seam.
@riverpod
SoundPort soundPort(Ref ref) => const _NoopSoundPort();

class _NoopSoundPort implements SoundPort {
  const _NoopSoundPort();

  @override
  void play(SoundCue cue) {}

  @override
  void dartThrown(String segment) {}
}
