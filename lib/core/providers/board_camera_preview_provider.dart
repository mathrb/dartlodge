import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'board_camera_preview_provider.g.dart';

/// Builds the camera-first body region for a board running in auto-scoring mode,
/// given the game id. It FILLS a flexible region — the board places it in an
/// `Expanded` and owns the surrounding scoreboard + the manual-entry modal.
/// Only the camera preview/controls cross this seam; the layout and the
/// segment-entry popup stay in the `game` feature.
typedef BoardCameraPreviewBuilder = Widget Function(
    BuildContext context, String gameId);

/// Cross-feature seam (CLAUDE.md: communicate via `core/`, not direct imports)
/// for the camera-first board layout (#427). Defaults to null; the composition
/// root (`main.dart`) overrides it with the auto-scorer's camera widget. It is
/// the only camera seam: the slim band variant it used to sit beside was never
/// adopted by a board and went with the single-view cleanup (#760).
@riverpod
BoardCameraPreviewBuilder? boardCameraPreviewBuilder(Ref ref) => null;
