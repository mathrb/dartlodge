import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/history/presentation/widgets/leg_breakdown_table_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

Game _game(GameType type) {
  final config = type == GameType.cricket
      ? const GameConfig.cricket(
          scoring: 'standard',
          numbers: ['15', '16', '17', '18', '19', '20', 'bull'],
        )
      : const GameConfig.x01(
          startingScore: 501,
          inStrategy: 'straight',
          outStrategy: 'double',
        );
  return Game(
    gameId: 'g',
    gameType: type,
    config: config,
    startTime: DateTime(2024),
  );
}

LegStatsBreakdown _leg({
  required int number,
  required String winnerId,
  required String winnerName,
  required int aliceDarts,
  required int bobDarts,
  double? aliceAvg,
  double? aliceCheckoutPct,
  int? aliceHighestCheckout,
  int aliceOneEighty = 0,
}) =>
    LegStatsBreakdown(
      legNumber: number,
      winnerCompetitorId: winnerId,
      winnerName: winnerName,
      byCompetitor: [
        LegCompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          dartsThrown: aliceDarts,
          threeDartAverage: aliceAvg,
          checkoutPercentage: aliceCheckoutPct,
          highestCheckout: aliceHighestCheckout,
          oneEightyTurns: aliceOneEighty,
        ),
        LegCompetitorStats(
          competitorId: 'c2',
          competitorName: 'Bob',
          dartsThrown: bobDarts,
        ),
      ],
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('renders total darts (sum across competitors) per leg',
      (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [
        _leg(
          number: 1,
          winnerId: 'c1',
          winnerName: 'Alice',
          aliceDarts: 3,
          bobDarts: 0,
          aliceAvg: 170.0,
        ),
        _leg(
          number: 2,
          winnerId: 'c2',
          winnerName: 'Bob',
          aliceDarts: 6,
          bobDarts: 9,
        ),
      ],
      game: _game(GameType.x01),
    )));

    // Leg 1: 3 + 0 = 3
    expect(find.text('3'), findsOneWidget);
    // Leg 2: 6 + 9 = 15
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('shows expand toggles when multiple legs; expanding shows stats rows',
      (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [
        _leg(
          number: 1,
          winnerId: 'c1',
          winnerName: 'Alice',
          aliceDarts: 3,
          bobDarts: 0,
          aliceAvg: 170.0,
          aliceCheckoutPct: 100.0,
          aliceHighestCheckout: 170,
        ),
        _leg(
          number: 2,
          winnerId: 'c2',
          winnerName: 'Bob',
          aliceDarts: 6,
          bobDarts: 9,
          aliceOneEighty: 1,
        ),
      ],
      game: _game(GameType.x01),
    )));

    final toggles = find.byIcon(Icons.expand_more);
    expect(toggles, findsNWidgets(2));

    await tester.tap(toggles.first);
    await tester.pumpAndSettle();

    expect(find.text('AVG PPR'), findsOneWidget);
    expect(find.text('CHECKOUT'), findsOneWidget);
    expect(find.text('BEST OUT'), findsOneWidget);
    expect(find.text('180S'), findsOneWidget);
    // '170' appears twice: AVG PPR (170.0 → "170") and BEST OUT (170).
    expect(find.text('170'), findsNWidgets(2));
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('hides expand toggle when only one leg', (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [
        _leg(
          number: 1,
          winnerId: 'c1',
          winnerName: 'Alice',
          aliceDarts: 15,
          bobDarts: 12,
        ),
      ],
      game: _game(GameType.cricket),
    )));
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byIcon(Icons.expand_less), findsNothing);
  });

  testWidgets('cricket expansion shows Avg MPR row', (tester) async {
    final leg = LegStatsBreakdown(
      legNumber: 1,
      winnerCompetitorId: 'c1',
      winnerName: 'Alice',
      byCompetitor: const [
        LegCompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          dartsThrown: 9,
          marksPerRound: 8.0,
          firstNineMarksPerRound: 8.0,
          nineMarkTurns: 2,
          sixMarkTurns: 1,
        ),
        LegCompetitorStats(
          competitorId: 'c2',
          competitorName: 'Bob',
          dartsThrown: 6,
          marksPerRound: 0.0,
        ),
      ],
    );
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: [leg, leg.copyWith(legNumber: 2)],
      game: _game(GameType.cricket),
    )));
    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    expect(find.text('AVG MPR'), findsOneWidget);
    expect(find.text('FIRST 9 MPR'), findsOneWidget);
    expect(find.text('9 MARKS'), findsOneWidget);
  });

  testWidgets('empty legs shows placeholder', (tester) async {
    await tester.pumpWidget(_wrap(LegBreakdownTableWidget(
      legs: const [],
      game: _game(GameType.x01),
    )));
    expect(find.text('No legs completed'), findsOneWidget);
  });
}
