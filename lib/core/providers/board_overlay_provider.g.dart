// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board_overlay_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
/// that lets the auto-scorer render a status-chip/controls overlay on the game
/// board without the `game` feature importing `auto_scorer`. Defaults to null
/// (no overlay); the composition root (`main.dart`) overrides it with the
/// auto-scorer's builder. Mirrors the `DartInputSink` / `activeDartInputSink`
/// bridge used for emission.

@ProviderFor(boardOverlayBuilder)
final boardOverlayBuilderProvider = BoardOverlayBuilderProvider._();

/// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
/// that lets the auto-scorer render a status-chip/controls overlay on the game
/// board without the `game` feature importing `auto_scorer`. Defaults to null
/// (no overlay); the composition root (`main.dart`) overrides it with the
/// auto-scorer's builder. Mirrors the `DartInputSink` / `activeDartInputSink`
/// bridge used for emission.

final class BoardOverlayBuilderProvider
    extends
        $FunctionalProvider<
          BoardOverlayBuilder?,
          BoardOverlayBuilder?,
          BoardOverlayBuilder?
        >
    with $Provider<BoardOverlayBuilder?> {
  /// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
  /// that lets the auto-scorer render a status-chip/controls overlay on the game
  /// board without the `game` feature importing `auto_scorer`. Defaults to null
  /// (no overlay); the composition root (`main.dart`) overrides it with the
  /// auto-scorer's builder. Mirrors the `DartInputSink` / `activeDartInputSink`
  /// bridge used for emission.
  BoardOverlayBuilderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'boardOverlayBuilderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$boardOverlayBuilderHash();

  @$internal
  @override
  $ProviderElement<BoardOverlayBuilder?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BoardOverlayBuilder? create(Ref ref) {
    return boardOverlayBuilder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BoardOverlayBuilder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BoardOverlayBuilder?>(value),
    );
  }
}

String _$boardOverlayBuilderHash() =>
    r'afa74e64a499183ce15eb92631c667bbbfdbdfac';
