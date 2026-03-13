import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/models/game_config.dart';
import 'package:my_darts/features/game/presentation/pages/variant_selection_page.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';
import 'package:my_darts/features/game/presentation/widgets/variant_card_widget.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakePlayerRepository implements PlayerRepository {
  @override
  Future<List<Player>> getAllPlayers() async => [];
  @override
  Future<Player?> getPlayer(String playerId) async => null;
  @override
  Future<void> createPlayer(Player player) async {}
  @override
  Future<void> updatePlayerName(String playerId, String name) async {}
  @override
  Future<void> touchPlayer(String playerId) async {}
  @override
  Future<void> deletePlayer(String playerId) async {}
  @override
  Stream<List<Player>> watchAllPlayers() => const Stream.empty();
}

/// Notifier override that starts in a fixed state (no init side-effects).
class _FixedGameSetupNotifier extends GameSetupNotifier {
  _FixedGameSetupNotifier(this._fixedState);
  final GameSetupState _fixedState;

  @override
  GameSetupState build() => _fixedState;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a testable app for [category] with optional [setupState].
/// Exposes [pushedRoutes] to verify navigation.
Widget _buildApp(
  String category, {
  GameSetupState? setupState,
  List<String>? pushedRoutes,
}) {
  final captured = pushedRoutes ?? [];
  final router = GoRouter(
    initialLocation: '/game/variant-selection/$category',
    routes: [
      GoRoute(
        path: '/game/variant-selection/:category',
        builder: (context, state) => VariantSelectionPage(
          category: state.pathParameters['category'] ?? category,
        ),
      ),
      GoRoute(
        path: '/game/player-selection',
        builder: (_, __) {
          captured.add('/game/player-selection');
          return const Scaffold(body: Text('player-selection'));
        },
      ),
    ],
  );

  final initialState = setupState ?? const GameSetupState.selectingType();

  return ProviderScope(
    overrides: [
      playerRepositoryProvider.overrideWithValue(_FakePlayerRepository()),
      gameSetupProvider.overrideWith(() => _FixedGameSetupNotifier(initialState)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VariantSelectionPage — X01', () {
    testWidgets('renders 4 enabled cards and 1 disabled Custom card',
        (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.text('501 — Double Out'), findsOneWidget);
      expect(find.text('301 — Double Out'), findsOneWidget);
      expect(find.text('701 — Double Out'), findsOneWidget);
      expect(find.text('901 — Double Out'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Custom card wrapped in Opacity(0.38)
      final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacityWidgets.any((o) => o.opacity == 0.38), isTrue);
    });

    testWidgets('each numeric card shows correct subtitle', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.text('Double Out · 1 Leg'), findsNWidgets(4));
    });

    testWidgets('Custom card has no subtitle', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      // Find the VariantCardWidget whose title is 'Custom'
      final customCard = find.byWidgetPredicate(
        (w) => w is VariantCardWidget && w.title == 'Custom',
      );
      expect(customCard, findsOneWidget);
      final widget = tester.widget<VariantCardWidget>(customCard);
      expect(widget.subtitle, isNull);
    });

    testWidgets('501 card shows selected styling when config matches',
        (tester) async {
      const selected = GameConfig.x01(
        startingScore: 501,
        inStrategy: 'straight',
        outStrategy: 'double',
        legsToWin: 1,
      );
      await tester.pumpWidget(_buildApp(
        'x01',
        setupState: const GameSetupState.configuringGame(
          gameType: GameType.x01,
          config: selected,
        ),
      ));
      await tester.pumpAndSettle();

      final card = tester.widget<VariantCardWidget>(
        find.byWidgetPredicate(
          (w) => w is VariantCardWidget && w.title == '501 — Double Out',
        ),
      );
      expect(card.isSelected, isTrue);
    });

    testWidgets('tapping 501 card navigates to /game/player-selection',
        (tester) async {
      final pushed = <String>[];
      await tester.pumpWidget(_buildApp('x01', pushedRoutes: pushed));
      await tester.pumpAndSettle();

      await tester.tap(find.text('501 — Double Out'));
      await tester.pumpAndSettle();

      expect(find.text('player-selection'), findsOneWidget);
    });

    testWidgets('Custom card shows Tooltip "Custom configuration coming soon"',
        (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      final tooltip = find.byWidgetPredicate(
        (w) => w is Tooltip && w.message == 'Custom configuration coming soon',
      );
      expect(tooltip, findsOneWidget);
    });

    testWidgets('disabled card has 38% opacity', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.where((o) => o.opacity == 0.38), hasLength(1));
    });

    testWidgets('tapping disabled Custom card does not navigate',
        (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('player-selection'), findsNothing);
    });

    testWidgets('AppBar title is "X01"', (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.text('X01'), findsOneWidget);
    });
  });

  group('VariantSelectionPage — Cricket', () {
    testWidgets('renders 4 enabled cards and 1 disabled Custom', (tester) async {
      await tester.pumpWidget(_buildApp('cricket'));
      await tester.pumpAndSettle();

      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('No Score'), findsOneWidget);
      expect(find.text('Cut Throat'), findsOneWidget);
      expect(find.text('Tactics'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('each card shows correct subtitle', (tester) async {
      await tester.pumpWidget(_buildApp('cricket'));
      await tester.pumpAndSettle();

      expect(find.text('Close 15–20 & Bull · Standard'), findsOneWidget);
      expect(find.text('Close only · No points'), findsOneWidget);
      expect(find.text('Cut-Throat · Score on opponent'), findsOneWidget);
      expect(find.text('Strategy variant · No points'), findsOneWidget);
    });

    testWidgets('AppBar title is "Cricket"', (tester) async {
      await tester.pumpWidget(_buildApp('cricket'));
      await tester.pumpAndSettle();

      expect(find.text('Cricket'), findsOneWidget);
    });
  });

  group('VariantSelectionPage — Practice', () {
    testWidgets('renders 5 enabled cards', (tester) async {
      await tester.pumpWidget(_buildApp('practice'));
      await tester.pumpAndSettle();

      expect(find.text('Around the Clock'), findsOneWidget);
      expect(find.text('Catch 40'), findsOneWidget);
      expect(find.text("Bob's 27"), findsOneWidget);
      expect(find.text('Shanghai'), findsOneWidget);
      expect(find.text('170 Checkout'), findsOneWidget);
    });

    testWidgets('practice cards have no subtitles', (tester) async {
      await tester.pumpWidget(_buildApp('practice'));
      await tester.pumpAndSettle();

      final cards =
          tester.widgetList<VariantCardWidget>(find.byType(VariantCardWidget));
      for (final card in cards) {
        expect(card.subtitle, isNull,
            reason: 'Practice card "${card.title}" should have no subtitle');
      }
    });

    testWidgets('no disabled cards in practice', (tester) async {
      await tester.pumpWidget(_buildApp('practice'));
      await tester.pumpAndSettle();

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.where((o) => o.opacity == 0.38), isEmpty);
    });

    testWidgets('AppBar title is "Practice"', (tester) async {
      await tester.pumpWidget(_buildApp('practice'));
      await tester.pumpAndSettle();

      expect(find.text('Practice'), findsOneWidget);
    });
  });

  group('VariantSelectionPage — Hint line', () {
    testWidgets('hint line is always rendered below the variant list',
        (tester) async {
      await tester.pumpWidget(_buildApp('x01'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Select a preset'), findsOneWidget);
    });

    testWidgets('hint line shown for cricket category too', (tester) async {
      await tester.pumpWidget(_buildApp('cricket'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Select a preset'), findsOneWidget);
    });
  });
}
