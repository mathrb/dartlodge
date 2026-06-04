import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'diagnostics_provider.g.dart';

const _kTimingHudKey = 'auto_scorer_timing_hud';
const _kSkipPreprocessKey = 'auto_scorer_skip_preprocess';

/// Developer diagnostics for the lag investigation (#377 §3), surfaced under a
/// "Diagnostics" section of the auto-scoring settings. The timing HUD defaults
/// **off**; the skip-preprocess toggle now defaults **on** (the native serve
/// path — see its own doc below).

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

/// Preprocess toggle (#377 §3): when on, pass raw camera bytes to the plugin
/// (native letterbox resize) instead of our Dart-side 800×800 letterbox.
/// Default **on** (raw-capture brief) — the plugin's native path detected
/// better *and* faster on-device than our double-resample/PNG-round-trip, and
/// it lets training capture store the raw frame with raw-space coords. The
/// Dart preprocess remains the A/B alternative behind this toggle + the timing
/// HUD. Threaded into `DartDetector.detect` per frame by the session, so it
/// takes effect on the next tick (no camera restart); the session captures the
/// frame in whichever space matches the detector's coords.
@Riverpod(keepAlive: true)
class AutoScorerSkipPreprocess extends _$AutoScorerSkipPreprocess {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kSkipPreprocessKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kSkipPreprocessKey, enabled);
    state = AsyncData(enabled);
  }
}
