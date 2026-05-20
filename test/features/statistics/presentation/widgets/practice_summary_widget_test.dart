import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/practice_summary_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

void main() {
  group('PracticeSummaryWidget', () {
    testWidgets('Around the Clock renders turns + darts', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.aroundTheClock(
          competitorName: 'Alice',
          turnsToComplete: 12,
          totalDarts: 35,
          doublesOnly: false,
        ),
      )));

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('Around the Clock'), findsOneWidget);
      expect(find.text('TURNS'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('DARTS'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      // No doubles-only tag when variant is standard.
      expect(find.text('DOUBLES ONLY'), findsNothing);
    });

    testWidgets('Around the Clock doubles-only shows tag', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.aroundTheClock(
          competitorName: 'Alice',
          turnsToComplete: 12,
          totalDarts: 35,
          doublesOnly: true,
        ),
      )));

      expect(find.text('DOUBLES ONLY'), findsOneWidget);
    });

    testWidgets('Catch 40 renders score/120 and targets/40', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.catch40(
          competitorName: 'Alice',
          score: 78,
          targetsCleared: 26,
        ),
      )));

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text('Catch 40'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('78 / 120'), findsOneWidget);
      expect(find.text('TARGETS'), findsOneWidget);
      expect(find.text('26 / 40'), findsOneWidget);
    });

    testWidgets("Bob's 27 (not busted) shows final score + round",
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.bobs27(
          competitorName: 'Alice',
          finalScore: 162,
          roundReached: 20,
          bustedToZero: false,
        ),
      )));

      expect(find.text('ALICE'), findsOneWidget);
      expect(find.text("Bob's 27"), findsOneWidget);
      expect(find.text('FINAL SCORE'), findsOneWidget);
      expect(find.text('162'), findsOneWidget);
      expect(find.text('ROUND'), findsOneWidget);
      expect(find.text('20 / 20'), findsOneWidget);
      expect(find.text('BUSTED'), findsNothing);
    });

    testWidgets("Bob's 27 busted shows BUSTED tag + muted style",
        (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.bobs27(
          competitorName: 'Alice',
          finalScore: 0,
          roundReached: 8,
          bustedToZero: true,
        ),
      )));

      expect(find.text('BUSTED'), findsOneWidget);
      expect(find.text("Bob's 27 — drill ended"), findsOneWidget);
    });

    testWidgets('170 Checkout success shows "Checked out!"', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          checkedOut: true,
          dartsThrown: 9,
          fromScore: 170,
          remainingScore: 0,
        ),
      )));

      expect(find.text('CHECKED OUT!'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('DARTS'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('FROM → REMAINING'), findsOneWidget);
      expect(find.text('170 → 0'), findsOneWidget);
    });

    testWidgets('170 Checkout failure shows "Not checked out"', (tester) async {
      await tester.pumpWidget(_wrap(const PracticeSummaryWidget(
        result: GameResult.checkoutPractice(
          competitorName: 'Alice',
          checkedOut: false,
          dartsThrown: 9,
          fromScore: 170,
          remainingScore: 32,
        ),
      )));

      expect(find.text('NOT CHECKED OUT'), findsOneWidget);
      expect(find.text('170 → 32'), findsOneWidget);
      expect(find.text('CHECKED OUT'), findsNothing);
    });
  });
}
