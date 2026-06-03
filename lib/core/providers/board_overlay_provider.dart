import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'board_overlay_provider.g.dart';

/// Builds an overlay widget stacked on the active X01/Cricket board, given the
/// game id. Self-positioned (the board just drops it into a `Stack`).
typedef BoardOverlayBuilder = Widget Function(
    BuildContext context, String gameId);

/// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
/// that lets the auto-scorer render a status-chip/controls overlay on the game
/// board without the `game` feature importing `auto_scorer`. Defaults to null
/// (no overlay); the composition root (`main.dart`) overrides it with the
/// auto-scorer's builder. Mirrors the `DartInputSink` / `activeDartInputSink`
/// bridge used for emission.
@riverpod
BoardOverlayBuilder? boardOverlayBuilder(Ref ref) => null;
