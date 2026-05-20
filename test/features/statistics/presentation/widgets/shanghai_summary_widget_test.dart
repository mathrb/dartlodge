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
  testWidgets('ShanghaiSummaryWidget shows hero score + all four rows',
      (tester) async {
    await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
      result: ShanghaiResult(
        competitorName: 'Alice',
        totalScore: 248,
        shanghaiBonuses: 2,
        bestRound: 80,
        roundsPlayed: 7,
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
        competitorName: 'Bob',
        totalScore: 50,
        shanghaiBonuses: 0,
        bestRound: 20,
        roundsPlayed: 7,
      ),
    )));

    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('SHANGHAIS'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });
}
