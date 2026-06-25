import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/history/domain/turn_breakdown.dart';
import 'package:dart_lodge/features/history/presentation/widgets/turn_breakdown_table_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

LegTurnBreakdown _x01TwoPlayer() => const LegTurnBreakdown(turns: [
      TurnRow(
        round: 1,
        competitorId: 'c1',
        competitorName: 'Pia',
        darts: ['T20', 'T20', 'T20'],
        turnScore: 180,
        startingScore: 301,
        remainingScore: 121,
      ),
      TurnRow(
        round: 1,
        competitorId: 'c2',
        competitorName: 'Quinn',
        darts: ['T20', 'T20', 'T20'],
        turnScore: 180,
        startingScore: 301,
        remainingScore: 121,
      ),
      TurnRow(
        round: 2,
        competitorId: 'c1',
        competitorName: 'Pia',
        darts: ['T20', 'T11', 'D14'],
        turnScore: 121,
        startingScore: 121,
        remainingScore: 0,
        checkout: true,
      ),
    ]);

void main() {
  testWidgets(
      'turn breakdown fits the width with a Table — no horizontal scroll (fit, not scroll)',
      (tester) async {
    await tester.pumpWidget(_wrap(TurnBreakdownTableWidget(
      gameType: GameType.x01,
      breakdown: _x01TwoPlayer(),
    )));

    // The table renders as a width-bounded Table, never a horizontally
    // scrollable DataTable (the old layout scrolled off-screen at 412px).
    expect(find.byType(Table), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
    final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
    expect(
      scrollables.any((s) => s.axisDirection == AxisDirection.right ||
          s.axisDirection == AxisDirection.left),
      isFalse,
      reason: 'turn breakdown must not introduce a horizontal scroll',
    );
  });

  testWidgets('X01 turn cell shows the CHECKOUT flag', (tester) async {
    await tester.pumpWidget(_wrap(TurnBreakdownTableWidget(
      gameType: GameType.x01,
      breakdown: _x01TwoPlayer(),
    )));
    // Player column shown for multi-competitor; checkout flag rendered.
    expect(find.text('Pia'), findsNWidgets(2));
    expect(find.text('Quinn'), findsOneWidget);
    expect(find.text('CHECKOUT'), findsOneWidget);
  });
}
