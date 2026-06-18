// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_port_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default no-op port. The composition root overrides this with the real
/// [SoundPort] impl. Under `flutter test` the no-op is used as-is, so nothing
/// plays. Mirrors the `boardOverlayBuilder` seam.
///
/// `keepAlive`: the real impl holds a preloaded audio player; without it the
/// provider would dispose (tearing down + re-preloading the player) whenever
/// the last board listener drops on navigation.

@ProviderFor(soundPort)
final soundPortProvider = SoundPortProvider._();

/// Default no-op port. The composition root overrides this with the real
/// [SoundPort] impl. Under `flutter test` the no-op is used as-is, so nothing
/// plays. Mirrors the `boardOverlayBuilder` seam.
///
/// `keepAlive`: the real impl holds a preloaded audio player; without it the
/// provider would dispose (tearing down + re-preloading the player) whenever
/// the last board listener drops on navigation.

final class SoundPortProvider
    extends $FunctionalProvider<SoundPort, SoundPort, SoundPort>
    with $Provider<SoundPort> {
  /// Default no-op port. The composition root overrides this with the real
  /// [SoundPort] impl. Under `flutter test` the no-op is used as-is, so nothing
  /// plays. Mirrors the `boardOverlayBuilder` seam.
  ///
  /// `keepAlive`: the real impl holds a preloaded audio player; without it the
  /// provider would dispose (tearing down + re-preloading the player) whenever
  /// the last board listener drops on navigation.
  SoundPortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soundPortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$soundPortHash();

  @$internal
  @override
  $ProviderElement<SoundPort> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SoundPort create(Ref ref) {
    return soundPort(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SoundPort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SoundPort>(value),
    );
  }
}

String _$soundPortHash() => r'1cf9fae41d04ee5918fd43ff289fd4d2b0e9d56b';
