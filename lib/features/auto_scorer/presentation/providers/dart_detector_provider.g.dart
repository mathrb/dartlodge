// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dart_detector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
/// Consumers gate on [DartDetector.isSupported] before starting detection.
/// Inference runs on the raw camera frame (the plugin letterboxes natively),
/// so there is no per-frame preprocessing to configure here (#377 §3).

@ProviderFor(dartDetector)
final dartDetectorProvider = DartDetectorProvider._();

/// The on-device dart detector (ultralytics_yolo on mobile, no-op on web).
/// Consumers gate on [DartDetector.isSupported] before starting detection.
/// Inference runs on the raw camera frame (the plugin letterboxes natively),
/// so there is no per-frame preprocessing to configure here (#377 §3).

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
  /// Inference runs on the raw camera frame (the plugin letterboxes natively),
  /// so there is no per-frame preprocessing to configure here (#377 §3).
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
