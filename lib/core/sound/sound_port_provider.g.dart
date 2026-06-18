// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sound_port_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Default no-op port. The composition root overrides this with the real
/// [SoundPort] impl (SI-2). Under `flutter test` the no-op is used as-is, so
/// nothing plays. Mirrors the `boardOverlayBuilder` seam.

@ProviderFor(soundPort)
final soundPortProvider = SoundPortProvider._();

/// Default no-op port. The composition root overrides this with the real
/// [SoundPort] impl (SI-2). Under `flutter test` the no-op is used as-is, so
/// nothing plays. Mirrors the `boardOverlayBuilder` seam.

final class SoundPortProvider
    extends $FunctionalProvider<SoundPort, SoundPort, SoundPort>
    with $Provider<SoundPort> {
  /// Default no-op port. The composition root overrides this with the real
  /// [SoundPort] impl (SI-2). Under `flutter test` the no-op is used as-is, so
  /// nothing plays. Mirrors the `boardOverlayBuilder` seam.
  SoundPortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'soundPortProvider',
        isAutoDispose: true,
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

String _$soundPortHash() => r'1833611619fe799c74cafc02763b21b83eef3413';
