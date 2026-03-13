import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_darts/core/persistence/database_provider.dart';
import 'package:my_darts/core/utils/app_colors.dart';
import 'package:my_darts/features/game/presentation/pages/home_page.dart';
import 'package:my_darts/features/game/presentation/providers/game_setup_provider.dart';
import 'package:my_darts/features/game/presentation/state/game_setup_state.dart';
import 'package:my_darts/features/players/domain/entities/player.dart';
import 'package:my_darts/features/players/domain/repositories/player_repository.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

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

class _FixedGameSetupNotifier extends GameSetupNotifier {
  @override
  GameSetupState build() => const GameSetupState.selectingType();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildApp({GoRouter? router}) {
  final r = router ??
      GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
        ],
      );

  return ProviderScope(
    overrides: [
      playerRepositoryProvider.overrideWithValue(_FakePlayerRepository()),
      gameSetupProvider.overrideWith(() => _FixedGameSetupNotifier()),
    ],
    child: MaterialApp.router(routerConfig: r),
  );
}

/// Builds an app whose router captures which page was navigated to.
GoRouter _navRouter(List<String> captured) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: '/game/variant-selection/:category',
          builder: (_, s) {
            final cat = s.pathParameters['category']!;
            captured.add('/game/variant-selection/$cat');
            return Scaffold(body: Text('variant-selection-$cat'));
          },
        ),
        GoRoute(
          path: '/history',
          builder: (_, __) {
            captured.add('/history');
            return const Scaffold(body: Text('history'));
          },
        ),
        GoRoute(
          path: '/players',
          builder: (_, __) {
            captured.add('/players');
            return const Scaffold(body: Text('players'));
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) {
            captured.add('/settings');
            return const Scaffold(body: Text('settings'));
          },
        ),
        GoRoute(
          path: '/stats',
          builder: (_, __) {
            captured.add('/stats');
            return const Scaffold(body: Text('stats'));
          },
        ),
      ],
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── Render tests ────────────────────────────────────────────────────────────

  group('HomePage — render', () {
    testWidgets('renders PLAY section label', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('renders all four PLAY rows', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('X01'), findsOneWidget);
      expect(find.text('Cricket'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('renders History and Local Players nav cards', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Local Players'), findsOneWidget);
    });

    testWidgets('renders coming-soon cards with 0.6 opacity', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Game Lobby'), findsOneWidget);
      expect(find.text('VS Friends'), findsOneWidget);

      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities.any((o) => o.opacity == 0.6), isTrue);
    });

    testWidgets('coming-soon cards have Tooltip with "Coming soon" message',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip));
      final comingSoonTooltips =
          tooltips.where((t) => t.message == 'Coming soon');
      expect(comingSoonTooltips.length, equals(2));
    });

    testWidgets('coming-soon cards use SystemMouseCursors.forbidden',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final regions =
          tester.widgetList<MouseRegion>(find.byType(MouseRegion));
      final forbidden =
          regions.where((r) => r.cursor == SystemMouseCursors.forbidden);
      expect(forbidden.length, equals(2));
    });

    testWidgets('AppBar displays gear icon with Settings tooltip',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Settings'), findsOneWidget);
    });
  });

  // ── Navigation tests ─────────────────────────────────────────────────────────

  group('HomePage — navigation', () {
    testWidgets('tapping X01 row navigates to /game/variant-selection/x01',
        (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('X01'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection-x01'), findsOneWidget);
    });

    testWidgets(
        'tapping Cricket row navigates to /game/variant-selection/cricket',
        (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cricket'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection-cricket'), findsOneWidget);
    });

    testWidgets(
        'tapping Practice row navigates to /game/variant-selection/practice',
        (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection-practice'), findsOneWidget);
    });

    testWidgets('tapping Statistics row navigates to /stats', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Statistics'));
      await tester.pumpAndSettle();

      expect(find.text('stats'), findsOneWidget);
    });

    testWidgets('tapping History card navigates to /history', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('history'), findsOneWidget);
    });

    testWidgets('tapping Local Players card navigates to /players',
        (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Local Players'));
      await tester.pumpAndSettle();

      expect(find.text('players'), findsOneWidget);
    });

    testWidgets('tapping gear icon navigates to /settings', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('settings'), findsOneWidget);
    });
  });

  // ── Interaction / disabled state tests ───────────────────────────────────────

  group('HomePage — interaction', () {
    testWidgets('tapping Game Lobby card does nothing', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Game Lobby'));
      await tester.pumpAndSettle();

      // Still on home page — none of the destination stubs rendered.
      expect(find.text('X01'), findsOneWidget);
      expect(captured, isEmpty);
    });

    testWidgets('tapping VS Friends card does nothing', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VS Friends'));
      await tester.pumpAndSettle();

      expect(find.text('X01'), findsOneWidget);
      expect(captured, isEmpty);
    });

    testWidgets('PLAY rows have minimum 64dp height', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final boxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      final playRowBoxes =
          boxes.where((b) => b.constraints.minHeight >= 64.0).toList();
      // At least 4 play rows + 2 nav cards = 6 ConstrainedBoxes with minHeight 64
      expect(playRowBoxes.length, greaterThanOrEqualTo(4));
    });

    testWidgets('History and Local Players cards have minimum 64dp height',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final boxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final tallBoxes =
          boxes.where((b) => b.constraints.minHeight >= 64.0).toList();
      // 4 play rows + 2 nav cards + 2 coming-soon cards = 8
      expect(tallBoxes.length, greaterThanOrEqualTo(6));
    });
  });

  // ── Accent bar tests ──────────────────────────────────────────────────────────

  group('HomePage — accent bars', () {
    testWidgets('X01 row accent bar uses colorPrimary (#C62828)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final primaryContainers = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == AppColors.primary,
        ),
      );
      expect(primaryContainers, isNotEmpty);
      expect(primaryContainers.first.color, equals(const Color(0xFFC62828)));
    });

    testWidgets('Cricket row accent bar uses colorSecondary (#1A237E)',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final secondaryContainers = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.color == AppColors.secondary,
        ),
      );
      // Cricket + Statistics both use secondary accent
      expect(secondaryContainers.length, greaterThanOrEqualTo(2));
      expect(secondaryContainers.first.color, equals(const Color(0xFF1A237E)));
    });

    testWidgets('Statistics row chevron color matches colorSecondary',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Find all chevron icons coloured with secondary
      final icons = tester.widgetList<Icon>(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.chevron_right && w.color == AppColors.secondary,
        ),
      );
      // Cricket + Statistics chevrons are both secondary
      expect(icons.length, greaterThanOrEqualTo(2));
    });
  });
}
