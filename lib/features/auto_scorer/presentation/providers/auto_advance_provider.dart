import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_advance_provider.g.dart';

const _kAutoAdvanceOnClearKey = 'auto_scorer_auto_advance_on_clear';

/// The "Auto-advance turn when board is cleared" opt-in. When on, the auto-scorer
/// advances to the next turn/player as soon as it detects all darts have been
/// removed from the board (board-clear → `TrackerPhase.rebaselined`), so the
/// player doesn't press NEXT. Default **off**: changing the game flow
/// automatically is opt-in, like the other auto-scorer switches. Only consulted
/// on the YOLOView live-game path (X01 + Cricket).
@Riverpod(keepAlive: true)
class AutoAdvanceOnClearEnabled extends _$AutoAdvanceOnClearEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kAutoAdvanceOnClearKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kAutoAdvanceOnClearKey, enabled);
    state = AsyncData(enabled);
  }
}
