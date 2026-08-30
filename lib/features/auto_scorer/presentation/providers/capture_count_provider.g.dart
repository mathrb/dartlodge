// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Total training frames stored on this device (#742).
///
/// This is the settings-side view of the contribution counter: the in-game one
/// counts what the running session persisted (cheap, in memory), while the
/// settings tile wants the real total across sessions — the one number that
/// answers "how much have I contributed?".
///
/// Listing the store is a directory read, so it is deliberately NOT used on the
/// capture path; the settings page invalidates this provider after clearing.
/// Zero on web, where the capture store is a stub.

@ProviderFor(captureCount)
final captureCountProvider = CaptureCountProvider._();

/// Total training frames stored on this device (#742).
///
/// This is the settings-side view of the contribution counter: the in-game one
/// counts what the running session persisted (cheap, in memory), while the
/// settings tile wants the real total across sessions — the one number that
/// answers "how much have I contributed?".
///
/// Listing the store is a directory read, so it is deliberately NOT used on the
/// capture path; the settings page invalidates this provider after clearing.
/// Zero on web, where the capture store is a stub.

final class CaptureCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Total training frames stored on this device (#742).
  ///
  /// This is the settings-side view of the contribution counter: the in-game one
  /// counts what the running session persisted (cheap, in memory), while the
  /// settings tile wants the real total across sessions — the one number that
  /// answers "how much have I contributed?".
  ///
  /// Listing the store is a directory read, so it is deliberately NOT used on the
  /// capture path; the settings page invalidates this provider after clearing.
  /// Zero on web, where the capture store is a stub.
  CaptureCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return captureCount(ref);
  }
}

String _$captureCountHash() => r'7b2fd027b2b8d0835a9729d98d014923ec59ed6e';
