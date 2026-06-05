import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'detection_thresholds_provider.g.dart';

const _kCalConfidenceKey = 'auto_scorer_cal_confidence';
const _kDartConfidenceKey = 'auto_scorer_dart_confidence';

/// Default acceptance threshold (matches the plugin's historical predict
/// default). The point of making it configurable (#377 §3) is that the bundled
/// model's recall numbers are measured at a near-zero eval threshold, so a
/// lower operating threshold recovers borderline cal points / darts.
const double kDefaultConfidence = 0.25;

/// Minimum confidence for a **calibration point** to count (user-configurable).
/// All four cals must clear this each frame for `hasCalibration`.
@Riverpod(keepAlive: true)
class AutoScorerCalConfidence extends _$AutoScorerCalConfidence {
  @override
  Future<double> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getDouble(_kCalConfidenceKey) ?? kDefaultConfidence;
  }

  Future<void> set(double value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble(_kCalConfidenceKey, value);
    state = AsyncData(value);
  }
}

/// Minimum confidence for a **dart** detection to become a candidate
/// (user-configurable).
@Riverpod(keepAlive: true)
class AutoScorerDartConfidence extends _$AutoScorerDartConfidence {
  @override
  Future<double> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getDouble(_kDartConfidenceKey) ?? kDefaultConfidence;
  }

  Future<void> set(double value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setDouble(_kDartConfidenceKey, value);
    state = AsyncData(value);
  }
}
