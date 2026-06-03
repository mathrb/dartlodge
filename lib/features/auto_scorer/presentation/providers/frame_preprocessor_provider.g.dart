// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame_preprocessor_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The frame preprocessor used to build the model's 800×800 input (#377 §2).
/// Wires the `data/` codec implementation behind the `domain/` interface, so
/// the session (presentation) injects it without importing `data/`.

@ProviderFor(framePreprocessor)
final framePreprocessorProvider = FramePreprocessorProvider._();

/// The frame preprocessor used to build the model's 800×800 input (#377 §2).
/// Wires the `data/` codec implementation behind the `domain/` interface, so
/// the session (presentation) injects it without importing `data/`.

final class FramePreprocessorProvider
    extends
        $FunctionalProvider<
          FramePreprocessor,
          FramePreprocessor,
          FramePreprocessor
        >
    with $Provider<FramePreprocessor> {
  /// The frame preprocessor used to build the model's 800×800 input (#377 §2).
  /// Wires the `data/` codec implementation behind the `domain/` interface, so
  /// the session (presentation) injects it without importing `data/`.
  FramePreprocessorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'framePreprocessorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$framePreprocessorHash();

  @$internal
  @override
  $ProviderElement<FramePreprocessor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FramePreprocessor create(Ref ref) {
    return framePreprocessor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FramePreprocessor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FramePreprocessor>(value),
    );
  }
}

String _$framePreprocessorHash() => r'86e1f7e47e3fa4b6dcfe87c9810ad19166555820';
