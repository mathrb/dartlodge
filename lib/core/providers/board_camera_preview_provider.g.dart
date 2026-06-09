// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_camera_preview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
/// for the camera-first board layout (#427). Defaults to null; the composition
/// root (`main.dart`) overrides it with the auto-scorer's camera widget. Sibling
/// to [boardOverlayBuilder] — that one is the band variant (still used elsewhere
/// until every board adopts the camera-first layout).

@ProviderFor(boardCameraPreviewBuilder)
final boardCameraPreviewBuilderProvider = BoardCameraPreviewBuilderProvider._();

/// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
/// for the camera-first board layout (#427). Defaults to null; the composition
/// root (`main.dart`) overrides it with the auto-scorer's camera widget. Sibling
/// to [boardOverlayBuilder] — that one is the band variant (still used elsewhere
/// until every board adopts the camera-first layout).

final class BoardCameraPreviewBuilderProvider
    extends
        $FunctionalProvider<
          BoardCameraPreviewBuilder?,
          BoardCameraPreviewBuilder?,
          BoardCameraPreviewBuilder?
        >
    with $Provider<BoardCameraPreviewBuilder?> {
  /// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
  /// for the camera-first board layout (#427). Defaults to null; the composition
  /// root (`main.dart`) overrides it with the auto-scorer's camera widget. Sibling
  /// to [boardOverlayBuilder] — that one is the band variant (still used elsewhere
  /// until every board adopts the camera-first layout).
  BoardCameraPreviewBuilderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boardCameraPreviewBuilderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boardCameraPreviewBuilderHash();

  @$internal
  @override
  $ProviderElement<BoardCameraPreviewBuilder?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BoardCameraPreviewBuilder? create(Ref ref) {
    return boardCameraPreviewBuilder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BoardCameraPreviewBuilder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BoardCameraPreviewBuilder?>(value),
    );
  }
}

String _$boardCameraPreviewBuilderHash() =>
    r'5334519bc7e449b1a59432c7aa5fcb73992f1169';
