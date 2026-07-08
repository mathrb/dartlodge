import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'simplified_input_provider.g.dart';

const kSimplifiedInputPrefKey = 'simplified_scoring_layout';

/// The "Simplified scoring keypad" preference, default **OFF** — the dense full
/// grid stays the default. When on, the X01 and Count-up board pages swap their
/// manual input to a larger keypad (numbers + armed Double/Triple). Lives in
/// `core/` (not `features/settings/`) because it is read across features: the
/// game board pages select the layout on it and the Settings page toggles it —
/// a cross-feature seam belongs in `core/` (mirrors `SoundEnabled`).
@Riverpod(keepAlive: true)
class SimplifiedInputEnabled extends _$SimplifiedInputEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(kSimplifiedInputPrefKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(kSimplifiedInputPrefKey, enabled);
    state = AsyncData(enabled);
  }
}
