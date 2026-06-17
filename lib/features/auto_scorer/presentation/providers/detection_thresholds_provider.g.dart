// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection_thresholds_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Minimum confidence for a **calibration point** to count (user-configurable).
/// All four cals must clear this each frame for `hasCalibration`.

@ProviderFor(AutoScorerCalConfidence)
final autoScorerCalConfidenceProvider = AutoScorerCalConfidenceProvider._();

/// Minimum confidence for a **calibration point** to count (user-configurable).
/// All four cals must clear this each frame for `hasCalibration`.
final class AutoScorerCalConfidenceProvider
    extends $AsyncNotifierProvider<AutoScorerCalConfidence, double> {
  /// Minimum confidence for a **calibration point** to count (user-configurable).
  /// All four cals must clear this each frame for `hasCalibration`.
  AutoScorerCalConfidenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerCalConfidenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerCalConfidenceHash();

  @$internal
  @override
  AutoScorerCalConfidence create() => AutoScorerCalConfidence();
}

String _$autoScorerCalConfidenceHash() =>
    r'9bb79ed002f7cd8841edf01fde24961f2cc1f986';

/// Minimum confidence for a **calibration point** to count (user-configurable).
/// All four cals must clear this each frame for `hasCalibration`.

abstract class _$AutoScorerCalConfidence extends $AsyncNotifier<double> {
  FutureOr<double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<double>, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<double>, double>,
              AsyncValue<double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Minimum confidence for a **dart** detection to become a candidate
/// (user-configurable).

@ProviderFor(AutoScorerDartConfidence)
final autoScorerDartConfidenceProvider = AutoScorerDartConfidenceProvider._();

/// Minimum confidence for a **dart** detection to become a candidate
/// (user-configurable).
final class AutoScorerDartConfidenceProvider
    extends $AsyncNotifierProvider<AutoScorerDartConfidence, double> {
  /// Minimum confidence for a **dart** detection to become a candidate
  /// (user-configurable).
  AutoScorerDartConfidenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerDartConfidenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerDartConfidenceHash();

  @$internal
  @override
  AutoScorerDartConfidence create() => AutoScorerDartConfidence();
}

String _$autoScorerDartConfidenceHash() =>
    r'6538bece3044c3b45af90b4adebdce5a1a5ca56e';

/// Minimum confidence for a **dart** detection to become a candidate
/// (user-configurable).

abstract class _$AutoScorerDartConfidence extends $AsyncNotifier<double> {
  FutureOr<double> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<double>, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<double>, double>,
              AsyncValue<double>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
