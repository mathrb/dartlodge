import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sound_settings_provider.g.dart';

const _kSoundEnabledKey = 'sound_enabled';

/// The global "Sounds" on/off preference, default **ON** — a discreet dart
/// thunk is expected. Lives in `core/` (not `features/sound/`) because it is
/// read across features: `SoundService` gates playback on it and the Settings
/// page toggles it — a cross-feature seam belongs in `core/` (mirrors
/// `AutoScoringEnabled`). The Settings "Sound" row drives [setEnabled].
@Riverpod(keepAlive: true)
class SoundEnabled extends _$SoundEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kSoundEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kSoundEnabledKey, enabled);
    state = AsyncData(enabled);
  }
}
