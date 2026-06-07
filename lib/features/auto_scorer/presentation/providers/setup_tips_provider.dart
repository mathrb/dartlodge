import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'setup_tips_provider.g.dart';

const _kSetupTipsSeenKey = 'auto_scorer_setup_tips_seen';

/// Whether the user has dismissed the one-time auto-scorer setup tips (#393
/// setup flow). Default **false** so the tips show before the first aim; the
/// "don't show again" checkbox sets it true. The Settings page can reset it via
/// [setSeen] to re-show the tips. Mirrors [DataCollectionEnabled].
@Riverpod(keepAlive: true)
class AutoScorerSetupTipsSeen extends _$AutoScorerSetupTipsSeen {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kSetupTipsSeenKey) ?? false;
  }

  Future<void> setSeen(bool seen) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kSetupTipsSeenKey, seen);
    state = AsyncData(seen);
  }
}
