import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sound_settings_provider.g.dart';

const _kSoundEnabledKey = 'sound_enabled';

/// The global "Sounds" on/off preference, default **ON** — a discreet dart
/// thunk is expected. [SoundService] reads this to gate playback. The Settings
/// UI row that toggles it is added in #519 (mirrors how [DataCollectionEnabled]
/// shipped its persisted state before its Settings row); this is the persisted
/// state + the gate the sound pipeline consults.
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
