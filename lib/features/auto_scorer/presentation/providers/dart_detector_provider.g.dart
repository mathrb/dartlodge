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
/// The diagnostics "skip preprocessing" A/B (#377 §3) is a per-call argument to
/// [DartDetector.detect] (threaded from the session), NOT a property of the
/// detector — so toggling it never rebuilds this provider or churns the native
/// model; it takes effect on the next frame.

@ProviderFor(dartDetector)
final dartDetectorProvider = DartDetectorProvider._();

/// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
/// Consumers gate on [DartDetector.isSupported] before starting detection.
///
/// The diagnostics "skip preprocessing" A/B (#377 §3) is a per-call argument to
/// [DartDetector.detect] (threaded from the session), NOT a property of the
/// detector — so toggling it never rebuilds this provider or churns the native
/// model; it takes effect on the next frame.

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
  /// The diagnostics "skip preprocessing" A/B (#377 §3) is a per-call argument to
  /// [DartDetector.detect] (threaded from the session), NOT a property of the
  /// detector — so toggling it never rebuilds this provider or churns the native
  /// model; it takes effect on the next frame.
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

String _$dartDetectorHash() => r'20a5323be3bb3dd03da12ac48bf6bb1d30471661';
