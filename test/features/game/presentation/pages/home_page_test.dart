import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:dart_lodge/features/game/presentation/pages/home_page.dart';
import 'package:dart_lodge/features/game/presentation/providers/game_setup_provider.dart';
import 'package:dart_lodge/features/game/presentation/state/game_setup_state.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/players/domain/repositories/player_repository.dart';

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

Widget _buildApp({GoRouter? router, Locale? locale}) {
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
    child: MaterialApp.router(
      routerConfig: r,
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
    ),
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
    testWidgets('renders DARTLODGE app title in header', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('DARTLODGE'), findsOneWidget);
    });

    testWidgets('renders all four game cards', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('X01'), findsOneWidget);
      expect(find.text('CRICKET'), findsOneWidget);
      expect(find.text('CASUAL'), findsOneWidget);
      expect(find.text('PRACTICE'), findsOneWidget);
    });

    testWidgets('renders flat nav rows for Statistics, History, Players',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('STATISTICS'), findsOneWidget);
      expect(find.text('HISTORY'), findsOneWidget);
      expect(find.text('PLAYERS'), findsOneWidget);
    });

    testWidgets('renders descriptor labels for flat nav rows', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('ANALYZE DATA'), findsOneWidget);
      expect(find.text('SESSIONS'), findsOneWidget);
      expect(find.text('ROSTER'), findsOneWidget);
    });

    testWidgets('AppBar displays gear icon with Settings tooltip',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.byTooltip('Settings'), findsOneWidget);
    });

    testWidgets('subtitles/descriptors + Settings are localized (fr) — #612',
        (tester) async {
      await tester.pumpWidget(_buildApp(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      // Subtitles/descriptors render the French values (upper-cased), and the
      // English literals are gone.
      expect(find.text('JEU STRATÉGIQUE'), findsOneWidget); // Cricket subtitle
      expect(find.text('ANALYSER LES DONNÉES'), findsOneWidget); // Statistics
      expect(find.text('EFFECTIF'), findsOneWidget); // Players "Roster"
      expect(find.text('STRATEGIC PLAY'), findsNothing);
      expect(find.text('ROSTER'), findsNothing);
      expect(find.byTooltip('Paramètres'), findsOneWidget);
    });

    testWidgets('each game card renders its icon', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.adjust), findsOneWidget);
      expect(find.byIcon(Icons.sports_cricket), findsOneWidget);
      expect(find.byIcon(Icons.casino), findsOneWidget);
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
    });

    testWidgets('game cards render 80dp height SizedBoxes', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final boxes = tester.widgetList<SizedBox>(
        find.byWidgetPredicate((w) => w is SizedBox && w.height == 80),
      );
      expect(boxes.length, greaterThanOrEqualTo(4));
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

      await tester.tap(find.text('CRICKET'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection-cricket'), findsOneWidget);
    });

    testWidgets(
        'tapping Casual row navigates to /game/variant-selection/casual',
        (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CASUAL'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection-casual'), findsOneWidget);
    });

    testWidgets(
        'tapping Practice row navigates to /game/variant-selection/practice',
        (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PRACTICE'));
      await tester.pumpAndSettle();

      expect(find.text('variant-selection-practice'), findsOneWidget);
    });

    testWidgets('tapping Statistics row navigates to /stats', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('STATISTICS'));
      await tester.pumpAndSettle();

      expect(find.text('stats'), findsOneWidget);
    });

    testWidgets('tapping History row navigates to /history', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('HISTORY'));
      await tester.pumpAndSettle();

      expect(find.text('history'), findsOneWidget);
    });

    testWidgets('tapping Players row navigates to /players', (tester) async {
      final captured = <String>[];
      await tester.pumpWidget(_buildApp(router: _navRouter(captured)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('PLAYERS'));
      await tester.tap(find.text('PLAYERS'));
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

  // ── Chevron tests ──────────────────────────────────────────────────────────

  group('HomePage — chevrons', () {
    testWidgets('game cards each have a chevron_right icon', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final chevrons = tester.widgetList<Icon>(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.chevron_right,
        ),
      );
      // Four game cards each have a chevron.
      expect(chevrons.length, greaterThanOrEqualTo(4));
    });
  });
}
