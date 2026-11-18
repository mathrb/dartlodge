// The player stats page leads with the numbers a player compares (average,
// checkout % / hit rate, legs won over played), keeps the "need 2 games"
// trend note to one line, shows a short empty state for a tab with no games,
// and has no placeholder tab. The empty Statistics page offers player
// creation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dart_lodge/app/app_router.dart';
import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/widgets/stats_table_widget.dart';
import 'package:dart_lodge/core/widgets/trend_chart_shell_widget.dart';
import 'package:dart_lodge/features/players/domain/entities/player.dart';
import 'package:dart_lodge/features/statistics/domain/entities/dart_position.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/player_stats_page.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/stats_tab_page.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/dart_heatmap_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/player_stats_page_provider.dart'
    show
        cricketLegHistoryProvider,
        filteredCricketStatsProvider,
        filteredPlayerStatsProvider,
        filteredPracticeStatsProvider,
        playerCricketVariantsProvider,
        playerLegHistoryProvider,
        playerX01StartingScoresProvider,
        practiceDrillHistoryProvider;
import 'package:dart_lodge/features/statistics/presentation/widgets/summary_cards_row_widget.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/time_range_selector_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

const _x01 = PlayerStats(
  playerId: 'p1',
  gameType: GameType.x01,
  totalGames: 5,
  gamesWon: 3,
  winRate: 0.6,
  threeDartAverage: 51.8,
  checkoutPercentage: 30.4,
  highestTurnScore: 140,
  totalDartsThrown: 600,
  dartsPerLeg: 30,
  bustRate: 0.1,
  legsPlayed: 14,
  legsWon: 7,
);

const _cricket = PlayerStats(
  playerId: 'p1',
  gameType: GameType.cricket,
  totalGames: 2,
  gamesWon: 1,
  winRate: 0.5,
  threeDartAverage: 0,
  highestTurnScore: 0,
  totalDartsThrown: 120,
  dartsPerLeg: 40,
  bustRate: 0,
  legsPlayed: 2,
  legsWon: 1,
  marksPerTurn: 3.14,
  hitRate: 0.595,
);

PlayerStats _empty(GameType type) => PlayerStats(
      playerId: 'p1',
      gameType: type,
      totalGames: 0,
      gamesWon: 0,
      winRate: 0,
      threeDartAverage: 0,
      highestTurnScore: 0,
      totalDartsThrown: 0,
      dartsPerLeg: 0,
      bustRate: 0,
    );

PlayerLegSnapshot _leg({double? mpt}) => PlayerLegSnapshot(
      gameId: 'g',
      legIndex: 0,
      gameDate: DateTime(2026, 11, 1),
      ppr: 50,
      mpt: mpt,
    );

Future<void> _pumpPage(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  PlayerStats x01 = _x01,
  PlayerStats cricket = _cricket,
  PlayerStats? practice,
  List<PlayerLegSnapshot> cricketHistory = const [],
}) async {
  tester.view.physicalSize = const Size(412, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerProvider('p1').overrideWith((ref) async => null),
        filteredPlayerStatsProvider('p1').overrideWith((ref) async => x01),
        filteredCricketStatsProvider('p1')
            .overrideWith((ref) async => cricket),
        filteredPracticeStatsProvider('p1').overrideWith(
          (ref) async => practice ?? _empty(GameType.aroundTheClock),
        ),
        playerX01StartingScoresProvider('p1')
            .overrideWith((ref) async => const <int>[]),
        playerCricketVariantsProvider('p1')
            .overrideWith((ref) async => const <String>[]),
        playerLegHistoryProvider('p1')
            .overrideWith((ref) async => const <PlayerLegSnapshot>[]),
        cricketLegHistoryProvider('p1')
            .overrideWith((ref) async => cricketHistory),
        practiceDrillHistoryProvider('p1')
            .overrideWith((ref) async => const <PlayerLegSnapshot>[]),
        dartHeatmapProvider.overrideWith(
          (ref, filter) => const <DartPosition>[],
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        theme: AppTheme.light(),
        home: const PlayerStatsPage(playerId: 'p1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(TabBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

/// The texts of the [StatsTableWidget] row whose label is [label].
List<String> _rowTexts(WidgetTester tester, String label) {
  final row = find
      .ancestor(of: find.text(label), matching: find.byType(Row))
      .first;
  return tester
      .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
      .map((t) => t.data ?? '')
      .toList();
}

void main() {
  group('PlayerStatsPage headline row', () {
    testWidgets('X01 leads with PPR, checkout % and legs won / played',
        (tester) async {
      await _pumpPage(tester);
      final headline = find.byType(SummaryCardsRowWidget);
      for (final text in ['PPR', '51.8', 'Checkout %', '30.4%',
          'Legs won 7/14 · 5 games']) {
        expect(find.descendant(of: headline, matching: find.text(text)),
            findsOneWidget, reason: text);
      }
      expect(find.text('Legs Played'), findsNothing);
      expect(find.text('Games Played'), findsNothing);
      // The average sits above the trend note.
      expect(
        tester.getRect(find.text('51.8').first).bottom,
        lessThan(tester.getRect(find.byType(TrendChartShellWidget)).top),
      );
    });

    testWidgets('Cricket leads with MPR, hit rate and legs won / played',
        (tester) async {
      await _pumpPage(tester);
      await _openTab(tester, 'Cricket');
      final headline = find.byType(SummaryCardsRowWidget);
      for (final text in ['MPR', '3.14', 'Hit Rate', '59.5%',
          'Legs won 1/2 · 2 games']) {
        expect(find.descendant(of: headline, matching: find.text(text)),
            findsOneWidget, reason: text);
      }
    });

    testWidgets('the legs line reads in the app locale (fr)', (tester) async {
      await _pumpPage(tester, locale: const Locale('fr'));
      expect(find.text('Legs gagnés 7/14 · 5 parties'), findsOneWidget);
    });

    testWidgets('one game reads in the singular', (tester) async {
      await _pumpPage(
        tester,
        x01: _x01.copyWith(totalGames: 1, legsPlayed: 1, legsWon: 1),
      );
      expect(find.text('Legs won 1/1 · 1 game'), findsOneWidget);
    });
  });

  group('PlayerStatsPage trend note', () {
    testWidgets('under 2 games the trend is one line, not a 200 px box',
        (tester) async {
      await _pumpPage(tester);
      expect(find.text('Need ≥2 games for a trend'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TrendChartShellWidget)).height,
        lessThan(60),
      );
    });

    testWidgets('Cricket legs without an MPR value collapse the same way',
        (tester) async {
      await _pumpPage(
        tester,
        cricketHistory: [_leg(), _leg(), _leg(mpt: 2.0)],
      );
      await _openTab(tester, 'Cricket');
      expect(find.text('Need ≥2 games for a trend'), findsOneWidget);
      expect(
        tester.getSize(find.byType(TrendChartShellWidget)).height,
        lessThan(60),
      );
    });
  });

  group('PlayerStatsPage Win %', () {
    testWidgets('has no BEST value', (tester) async {
      await _pumpPage(tester);
      expect(_rowTexts(tester, 'Win %'), ['Win %', '60%']);
    });
  });

  group('PlayerStatsPage tab with no games', () {
    testWidgets('Cricket shows a short empty state, no table of dashes or 0%',
        (tester) async {
      await _pumpPage(tester, cricket: _empty(GameType.cricket));
      await _openTab(tester, 'Cricket');
      expect(find.text('No Cricket games to show'), findsOneWidget);
      expect(find.byType(SummaryCardsRowWidget), findsNothing);
      expect(find.byType(StatsTableWidget), findsNothing);
      expect(find.byType(TrendChartShellWidget), findsNothing);
      expect(find.text('0%'), findsNothing);
      // The filters stay, so a narrowed selection can be widened again.
      expect(find.byType(TimeRangeSelectorWidget), findsOneWidget);
    });

    testWidgets('X01 shows the empty state in the app locale (fr)',
        (tester) async {
      await _pumpPage(
        tester,
        locale: const Locale('fr'),
        x01: _empty(GameType.x01),
      );
      expect(find.text('Aucune partie de X01 à afficher'), findsOneWidget);
      expect(find.byType(StatsTableWidget), findsNothing);
    });

    testWidgets('Practice names the selected drill', (tester) async {
      await _pumpPage(tester);
      await _openTab(tester, 'Practice');
      expect(find.text('No Around the Clock games to show'), findsOneWidget);
    });
  });

  group('PlayerStatsPage tabs', () {
    testWidgets('has no placeholder tab', (tester) async {
      await _pumpPage(tester);
      expect(
        find.descendant(of: find.byType(TabBar), matching: find.byType(Tab)),
        findsNWidgets(3),
      );
      expect(find.text('Others'), findsNothing);
    });

    testWidgets('fits "Entraînement" without scrolling at fr 1.0x',
        (tester) async {
      await _pumpPage(tester, locale: const Locale('fr'));
      expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isFalse);
      expect(find.text('Entraînement'), findsOneWidget);
    });
  });

  group('StatsTabPage with no players', () {
    testWidgets('offers player creation', (tester) async {
      final router = GoRouter(
        initialLocation: GameRoutes.stats,
        routes: [
          GoRoute(
            path: GameRoutes.stats,
            builder: (_, _) => const StatsTabPage(),
          ),
          GoRoute(
            path: GameRoutes.addPlayer,
            builder: (_, _) => const Scaffold(body: Text('create player')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allPlayersProvider.overrideWith(_NoPlayers.new),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: kSupportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add your first player'));
      await tester.pumpAndSettle();
      expect(find.text('create player'), findsOneWidget);
      // Pushed, so Back returns to the Statistics page.
      expect(router.canPop(), isTrue);
    });
  });
}

class _NoPlayers extends AllPlayers {
  @override
  Stream<List<Player>> build() => Stream.value(const <Player>[]);
}
