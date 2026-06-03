// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dart_detector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
/// Consumers gate on [DartDetector.isSupported] before starting detection.
///
/// Watches the [autoScorerSkipPreprocessProvider] diagnostics A/B (#377 §3):
/// toggling it rebuilds the detector so the next session runs raw-bytes
/// inference. The flag is off in normal use, so this is a no-op rebuild.

@ProviderFor(dartDetector)
final dartDetectorProvider = DartDetectorProvider._();

/// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
/// Consumers gate on [DartDetector.isSupported] before starting detection.
///
/// Watches the [autoScorerSkipPreprocessProvider] diagnostics A/B (#377 §3):
/// toggling it rebuilds the detector so the next session runs raw-bytes
/// inference. The flag is off in normal use, so this is a no-op rebuild.

final class DartDetectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<DartDetector>,
          DartDetector,
          FutureOr<DartDetector>
        >
    with $FutureModifier<DartDetector>, $FutureProvider<DartDetector> {
  /// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
  /// Consumers gate on [DartDetector.isSupported] before starting detection.
  ///
  /// Watches the [autoScorerSkipPreprocessProvider] diagnostics A/B (#377 §3):
  /// toggling it rebuilds the detector so the next session runs raw-bytes
  /// inference. The flag is off in normal use, so this is a no-op rebuild.
  DartDetectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dartDetectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dartDetectorHash();

  @$internal
  @override
  $FutureProviderElement<DartDetector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DartDetector> create(Ref ref) {
    return dartDetector(ref);
  }
}

String _$dartDetectorHash() => r'a93fe84b8bcf085dc58114b6c5cba6ce17b43f89';
