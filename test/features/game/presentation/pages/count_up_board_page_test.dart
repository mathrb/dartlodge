import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/providers/board_camera_preview_provider.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/pages/count_up_board_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/active_count_up_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/active_count_up_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/hero_metric_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

/// Fake notifier that returns a fixed state so the board renders without a DB.
class _FakeActiveCountUpNotifier extends ActiveCountUpNotifier {
  _FakeActiveCountUpNotifier(this._state);
  final ActiveCountUpState? _state;

  @override
  Future<ActiveCountUpState?> build(String gameId) async => _state;
}

/// Forces auto-scoring on without touching SharedPreferences.
class _FakeAutoScoringEnabled extends AutoScoringEnabled {
  @override
  Future<bool> build() async => true;
}

GameState _countUpState(
        {List<CompetitorState>? competitors, int dartsThrownInTurn = 1}) =>
    GameState(
      gameId: 'game-1',
      gameType: GameType.countUp,
      competitors: competitors ??
          const [
            CompetitorState(
              competitorId: 'c1',
              name: 'Alice',
              playerIds: [],
              score: 0,
            ),
          ],
      currentTurnIndex: 0,
      dartsThrownInTurn: dartsThrownInTurn,
      isComplete: false,
      turnActive: true,
      countUpTotalRounds: 8,
    );

Widget _buildApp(_FakeActiveCountUpNotifier notifier,
    {Locale? locale, bool cameraFirst = false}) {
  final router = GoRouter(
    initialLocation: '/game/active/count-up/game-1',
    routes: [
      GoRoute(
        path: '/game/active/count-up/:gameId',
        builder: (_, s) => CountUpBoardPage(gameId: s.pathParameters['gameId']!),
      ),
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('home'))),
    ],
  );
  return ProviderScope(
    overrides: [
      activeCountUpProvider.overrideWith(() => notifier),
      if (cameraFirst) ...[
        autoScoringEnabledProvider.overrideWith(() => _FakeAutoScoringEnabled()),
        boardCameraPreviewBuilderProvider.overrideWithValue(
          (ctx, id) => const SizedBox(key: ValueKey('camera-stub')),
        ),
      ],
    ],
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
    ),
  );
}

void main() {
  group('CountUpBoardPage localization (#596 / F-006)', () {
    testWidgets('solo board uses localized NEXT ROUND (fr)', (tester) async {
      await tester.pumpWidget(_buildApp(
        _FakeActiveCountUpNotifier(ActiveCountUpState(gameState: _countUpState())),
        locale: const Locale('fr'),
      ));
      await tester.pumpAndSettle();

      // The hardcoded 'NEXT ROUND' must be gone; the French label is shown.
      expect(find.text('TOUR SUIVANT'), findsOneWidget);
      expect(find.text('NEXT ROUND'), findsNothing);
    });

    testWidgets('multiplayer board uses localized NEXT PLAYER (fr)',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        _FakeActiveCountUpNotifier(ActiveCountUpState(
          gameState: _countUpState(competitors: const [
            CompetitorState(
                competitorId: 'c1', name: 'Alice', playerIds: [], score: 0),
            CompetitorState(
                competitorId: 'c2', name: 'Bob', playerIds: [], score: 0),
          ]),
        )),
        locale: const Locale('fr'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('JOUEUR SUIVANT'), findsOneWidget);
      expect(find.text('NEXT PLAYER'), findsNothing);
    });

    testWidgets('camera-first layout shows the hero score + camera, not the grid (#601)',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        _FakeActiveCountUpNotifier(ActiveCountUpState(
          gameState: _countUpState(competitors: const [
            CompetitorState(
                competitorId: 'c1', name: 'Alice', playerIds: [], score: 140),
          ]),
        )),
        cameraFirst: true,
      ));
      await tester.pumpAndSettle();

      // Camera-first chrome: hero score + the stub camera preview, no grid.
      expect(find.byType(HeroMetricWidget), findsOneWidget);
      expect(find.text('140'), findsOneWidget);
      expect(find.byKey(const ValueKey('camera-stub')), findsOneWidget);
      expect(find.byType(DartInputGridWidget), findsNothing);
    });

    testWidgets('overflow menu shows localized End Game / Settings (fr)',
        (tester) async {
      await tester.pumpWidget(_buildApp(
        _FakeActiveCountUpNotifier(ActiveCountUpState(gameState: _countUpState())),
        locale: const Locale('fr'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Terminer la partie'), findsOneWidget);
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.text('End Game'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('NEXT ROUND disabled with 0 darts (mis-tap guard, #627)',
        (tester) async {
      await tester.pumpWidget(_buildApp(_FakeActiveCountUpNotifier(
        ActiveCountUpState(gameState: _countUpState(dartsThrownInTurn: 0)),
      )));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('NEXT ROUND'),
          matching: find.byType(FilledButton),
        ).first,
      );
      expect(button.onPressed, isNull,
          reason: '0-dart NEXT is gated to prevent accidental forfeit (#627)');
    });

    testWidgets('NEXT ROUND enabled with 1 dart (silent MISS-fill, #627)',
        (tester) async {
      await tester.pumpWidget(_buildApp(_FakeActiveCountUpNotifier(
        ActiveCountUpState(gameState: _countUpState(dartsThrownInTurn: 1)),
      )));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('NEXT ROUND'),
          matching: find.byType(FilledButton),
        ).first,
      );
      expect(button.onPressed, isNotNull);
    });
  });
}
