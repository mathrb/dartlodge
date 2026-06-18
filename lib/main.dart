// Main entry point for the Darts App
// This file initializes the application and sets up the provider scope.
//
// Crash-reporting handlers (FlutterError.onError + PlatformDispatcher.instance.
// onError) are auto-installed by SentryFlutter.init via FlutterErrorIntegration
// and OnErrorIntegration respectively (sentry_flutter >= ~7.x; current pin is
// 9.19.0). Do NOT add manual handlers here — they would override Sentry's and
// silence the crash pipeline.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app/app.dart';
import 'core/debug/auto_scorer_sim_bridge.dart';
import 'core/providers/board_camera_preview_provider.dart';
import 'core/providers/board_overlay_provider.dart';
import 'core/sound/sound_port_provider.dart';
import 'features/auto_scorer/presentation/widgets/auto_scorer_board_overlay.dart';
import 'features/sound/data/audioplayers_sound_player.dart';
import 'features/sound/presentation/providers/sound_service.dart';

/// Opt-in (web E2E only) Playwright sim bridge — `--dart-define=AUTOSCORER_SIM=true`.
/// Off in the public build, so `window.dartlodgeSim` never ships to prod.
const _kAutoScorerSim = bool.fromEnvironment('AUTOSCORER_SIM');

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.environment = const String.fromEnvironment(
        'SENTRY_ENVIRONMENT',
        defaultValue: 'development',
      );
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [
          // Composition root wires the auto-scorer's board overlay into the
          // core seam, so the game feature renders it without importing
          // auto_scorer (CLAUDE.md cross-feature rule).
          boardOverlayBuilderProvider.overrideWithValue(
            (context, gameId) => AutoScorerBoardOverlay(gameId: gameId),
          ),
          // Camera-first variant (#427): the same overlay laid out to fill a
          // flexible region (big preview) instead of the slim band. Boards that
          // adopt the camera-first layout render this in an Expanded.
          boardCameraPreviewBuilderProvider.overrideWithValue(
            (context, gameId) =>
                AutoScorerBoardOverlay(gameId: gameId, expand: true),
          ),
          // Composition root wires the real audio impl into the core sound
          // seam, so the game feature plays sounds without importing the sound
          // feature. Prod-only: `flutter test` keeps the default no-op port.
          soundPortProvider.overrideWith((ref) {
            final player = AudioPlayersSoundPlayer()
              ..preload(SoundService.allAssets);
            ref.onDispose(player.dispose);
            return SoundService(ref, player);
          }),
        ],
        child: _kAutoScorerSim
            ? const AutoScorerSimBridge(child: DartsApp())
            : const DartsApp(),
      ),
    ),
  );
}