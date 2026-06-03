import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diagnostics_provider.g.dart';

const _kTimingHudKey = 'auto_scorer_timing_hud';

/// Developer diagnostics for the lag investigation (#377 §3). Both default
/// **off** and are surfaced only under a "Diagnostics" section of the
/// auto-scoring settings — they never affect a normal scoring session.

/// Shows the per-frame timing HUD (capture / detect / track) over the board so
/// we can attribute perceived slowness to a stage rather than guess.
@Riverpod(keepAlive: true)
class AutoScorerTimingHudEnabled extends _$AutoScorerTimingHudEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kTimingHudKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kTimingHudKey, enabled);
    state = AsyncData(enabled);
  }
}
