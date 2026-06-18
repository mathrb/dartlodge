import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port.dart';
import 'package:dart_lodge/core/sound/sound_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sound_player.dart';

/// Real [SoundPort] implementation: maps cues to assets, gates on the global
/// [soundEnabledProvider], and delegates playback to a [SoundPlayer]. Injected
/// at the composition root (`main.dart`) over the no-op `soundPortProvider`.
///
/// `dartThrown(segment)` (rather than `play(dartHit)`/`play(dartMiss)` at call
/// sites) keeps v2 additive: the segment caller, a dedicated T20 sound, and
/// cricket mark-ticks will all live here, keyed off `segment`, without touching
/// the boards.
class SoundService implements SoundPort {
  SoundService(this._ref, this._player);

  final Ref _ref;
  final SoundPlayer _player;

  /// Audioplayers-relative asset paths (resolve under `assets/`). File names
  /// match the assets on disk; `assets/sounds/` is declared in pubspec in #520.
  static const _assets = {
    SoundCue.dartHit: 'sounds/dartHit.mp3',
    SoundCue.dartMiss: 'sounds/dartMiss.wav',
    SoundCue.bust: 'sounds/bust.wav',
  };

  /// Every asset, for preloading at startup.
  static List<String> get allAssets => _assets.values.toList();

  @override
  void play(SoundCue cue) {
    // Global gate; defaults to ON while the preference is loading/absent.
    if (!(_ref.read(soundEnabledProvider).value ?? true)) return;
    // No-op (don't throw) for an unmapped cue — a future SoundCue without an
    // asset must not disrupt scoring (sound-never-disrupts-scoring invariant).
    final asset = _assets[cue];
    if (asset == null) return;
    _player.play(asset);
  }

  @override
  void dartThrown(String segment) =>
      play(segment == 'MISS' ? SoundCue.dartMiss : SoundCue.dartHit);
}
