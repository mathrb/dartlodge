import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/shanghai_summary_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  testWidgets('ShanghaiSummaryWidget (solo) shows hero score + all four rows',
      (tester) async {
    await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
      result: ShanghaiResult(
        competitors: [
          ShanghaiCompetitorResult(
            competitorId: 'c1',
            competitorName: 'Alice',
            totalScore: 248,
            shanghaiBonuses: 2,
            bestRound: 80,
            roundsPlayed: 7,
          ),
        ],
        winnerCompetitorId: null,
        totalRounds: 7,
      ),
    )));

    // Hero card
    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('Shanghai'), findsOneWidget);
    // Hero label "TOTAL SCORE" + table row "TOTAL SCORE" (uppercased category).
    expect(find.text('TOTAL SCORE'), findsNWidgets(2));
    expect(find.text('SHANGHAIS'), findsOneWidget);
    expect(find.text('SHANGHAI BONUSES'), findsOneWidget);
    expect(find.text('BEST ROUND'), findsOneWidget);
    expect(find.text('ROUNDS PLAYED'), findsOneWidget);

    // Values appear at least once (hero or table).
    expect(find.text('248'), findsWidgets);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('ShanghaiSummaryWidget with zero bonuses still renders',
      (tester) async {
    await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
      result: ShanghaiResult(
        competitors: [
          ShanghaiCompetitorResult(
            competitorId: 'c1',
            competitorName: 'Bob',
            totalScore: 50,
            shanghaiBonuses: 0,
            bestRound: 20,
            roundsPlayed: 7,
          ),
        ],
        winnerCompetitorId: null,
        totalRounds: 7,
      ),
    )));

    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('SHANGHAIS'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets(
      'ShanghaiSummaryWidget multi-player shows winner hero + per-player breakdown',
      (tester) async {
    await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
      result: ShanghaiResult(
        competitors: [
          ShanghaiCompetitorResult(
            competitorId: 'c1',
            competitorName: 'Alice',
            totalScore: 110,
            shanghaiBonuses: 1,
            bestRound: 60,
            roundsPlayed: 7,
          ),
          ShanghaiCompetitorResult(
            competitorId: 'c2',
            competitorName: 'Bob',
            totalScore: 65,
            shanghaiBonuses: 0,
            bestRound: 30,
            roundsPlayed: 7,
          ),
        ],
        winnerCompetitorId: 'c1',
        totalRounds: 7,
      ),
    )));

    // Hero shows the winner.
    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('WINNER'), findsOneWidget);
    // Bob is surfaced as a column too — not hidden because he didn't win.
    expect(find.text('Bob'), findsOneWidget);
    // Per-player score row visible.
    expect(find.text('30'), findsOneWidget);
  });
}
