// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technical_display_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The "Technical display" opt-in (#738 / design S1.3). When on, the YOLO plugin
/// paints its own detection boxes on the camera preview, labelled with the raw
/// class name and confidence (`cal1 82.4`, `dart 91.3`). That is debugging
/// output: a player aiming at their board reads machine-learning internals on
/// top of the picture, so the default is **off** and the plain preview is what
/// ships.
///
/// Accepted trade-off recorded in the design: with the boxes hidden the player
/// loses the information of *where* the camera sees the markers. The halo and
/// aim view's status banner (S1.1/S1.2) replace that signal in player
/// language.

@ProviderFor(AutoScorerTechnicalDisplay)
final autoScorerTechnicalDisplayProvider =
    AutoScorerTechnicalDisplayProvider._();

/// The "Technical display" opt-in (#738 / design S1.3). When on, the YOLO plugin
/// paints its own detection boxes on the camera preview, labelled with the raw
/// class name and confidence (`cal1 82.4`, `dart 91.3`). That is debugging
/// output: a player aiming at their board reads machine-learning internals on
/// top of the picture, so the default is **off** and the plain preview is what
/// ships.
///
/// Accepted trade-off recorded in the design: with the boxes hidden the player
/// loses the information of *where* the camera sees the markers. The halo and
/// aim view's status banner (S1.1/S1.2) replace that signal in player
/// language.
final class AutoScorerTechnicalDisplayProvider
    extends $AsyncNotifierProvider<AutoScorerTechnicalDisplay, bool> {
  /// The "Technical display" opt-in (#738 / design S1.3). When on, the YOLO plugin
  /// paints its own detection boxes on the camera preview, labelled with the raw
  /// class name and confidence (`cal1 82.4`, `dart 91.3`). That is debugging
  /// output: a player aiming at their board reads machine-learning internals on
  /// top of the picture, so the default is **off** and the plain preview is what
  /// ships.
  ///
  /// Accepted trade-off recorded in the design: with the boxes hidden the player
  /// loses the information of *where* the camera sees the markers. The halo and
  /// aim view's status banner (S1.1/S1.2) replace that signal in player
  /// language.
  AutoScorerTechnicalDisplayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoScorerTechnicalDisplayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoScorerTechnicalDisplayHash();

  @$internal
  @override
  AutoScorerTechnicalDisplay create() => AutoScorerTechnicalDisplay();
}

String _$autoScorerTechnicalDisplayHash() =>
    r'742b7ea07bc54a8ef98f2d26ac5b4f3d12e7f899';

/// The "Technical display" opt-in (#738 / design S1.3). When on, the YOLO plugin
/// paints its own detection boxes on the camera preview, labelled with the raw
/// class name and confidence (`cal1 82.4`, `dart 91.3`). That is debugging
/// output: a player aiming at their board reads machine-learning internals on
/// top of the picture, so the default is **off** and the plain preview is what
/// ships.
///
/// Accepted trade-off recorded in the design: with the boxes hidden the player
/// loses the information of *where* the camera sees the markers. The halo and
/// aim view's status banner (S1.1/S1.2) replace that signal in player
/// language.

abstract class _$AutoScorerTechnicalDisplay extends $AsyncNotifier<bool> {
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
