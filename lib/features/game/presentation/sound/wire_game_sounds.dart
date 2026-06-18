import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `ProviderListenable` (the type accepted by `ref.listen`) lives in misc.dart,
// not the main flutter_riverpod barrel.
import 'package:flutter_riverpod/misc.dart';

import '../../domain/models/game_state.dart';
import '../../domain/sound/dart_sound_signal.dart';

/// Wires sound effects to a game board by listening to its active-game provider:
/// fires `dartThrown(segment)` on each new dart and `play(SoundCue.bust)` on a
/// bust. Generic over the board's state type [T] so all four typed providers
/// (X01 / Cricket / Practice / Count-up) reuse it.
///
/// Call from the board's `build()` (Riverpod dedupes `ref.listen` across
/// rebuilds). The real `SoundPort` is injected at the composition root; under
/// tests the default no-op port is used, so boards stay silent unless a spy is
/// overridden. Sound is gated downstream by `SoundService` on the global
/// "Sounds" preference.
///
/// [gameStateOf] extracts the [GameState] from the board's state; [bustOf]
/// extracts its `showBust` flag (omit for boards without a bust mechanic —
/// Cricket, Count-up). Bust takes precedence: a busting dart plays only the
/// bust sound (the turn's earlier darts already sounded).
void wireGameSounds<T>(
  WidgetRef ref,
  ProviderListenable<AsyncValue<T?>> provider, {
  required GameState? Function(T?) gameStateOf,
  bool Function(T?)? bustOf,
}) {
  ref.listen(provider, (prev, next) {
    final sound = ref.read(soundPortProvider);
    final prevBust = bustOf?.call(prev?.value) ?? false;
    final nextBust = bustOf?.call(next.value) ?? false;
    if (!prevBust && nextBust) {
      sound.play(SoundCue.bust);
      return;
    }
    final segment =
        newestDartSegment(gameStateOf(prev?.value), gameStateOf(next.value));
    if (segment != null) sound.dartThrown(segment);
  });
}
