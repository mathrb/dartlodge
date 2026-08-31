// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pre_send_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the player has asked not to see the pre-send screen again (#744).
///
/// The screen explains what the export contains and how to get it to the
/// maintainer; a repeat sender already knows, so it is skippable — and once
/// skipped, export goes straight to the share sheet as it did before.

@ProviderFor(AutoScorerPreSendSkipped)
final autoScorerPreSendSkippedProvider = AutoScorerPreSendSkippedProvider._();

/// Whether the player has asked not to see the pre-send screen again (#744).
///
/// The screen explains what the export contains and how to get it to the
/// maintainer; a repeat sender already knows, so it is skippable — and once
/// skipped, export goes straight to the share sheet as it did before.
final class AutoScorerPreSendSkippedProvider
    extends $AsyncNotifierProvider<AutoScorerPreSendSkipped, bool> {
  /// Whether the player has asked not to see the pre-send screen again (#744).
  ///
  /// The screen explains what the export contains and how to get it to the
  /// maintainer; a repeat sender already knows, so it is skippable — and once
  /// skipped, export goes straight to the share sheet as it did before.
  AutoScorerPreSendSkippedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerPreSendSkippedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerPreSendSkippedHash();

  @$internal
  @override
  AutoScorerPreSendSkipped create() => AutoScorerPreSendSkipped();
}

String _$autoScorerPreSendSkippedHash() =>
    r'4e0956f876bfa63e07d8979c6cf076fc549023f6';

/// Whether the player has asked not to see the pre-send screen again (#744).
///
/// The screen explains what the export contains and how to get it to the
/// maintainer; a repeat sender already knows, so it is skippable — and once
/// skipped, export goes straight to the share sheet as it did before.

abstract class _$AutoScorerPreSendSkipped extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
