import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/cricket_stats_detail_table_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

PlayerStats _stats({double? firstNineMpr, double? bestFirstNineMpr}) =>
    PlayerStats(
      playerId: 'p1',
      gameType: GameType.cricket,
      totalGames: 3,
      gamesWon: 2,
      winRate: 2 / 3,
      threeDartAverage: 0,
      highestTurnScore: 0,
      totalDartsThrown: 62,
      dartsPerLeg: 20,
      bustRate: 0,
      firstNineMpr: firstNineMpr,
      bestFirstNineMpr: bestFirstNineMpr,
    );

/// The texts of the First 9 MPR row, label first.
List<String> _first9Row(WidgetTester tester) {
  final label = find.text('First 9 MPR');
  expect(label, findsOneWidget);
  final row = find.ancestor(of: label, matching: find.byType(Row)).first;
  return tester
      .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
      .map((t) => t.data ?? '')
      .toList();
}

void main() {
  testWidgets('First 9 MPR row shows the best leg in the BEST column',
      (tester) async {
    await tester.pumpWidget(_wrap(CricketStatsDetailTableWidget(
      stats: _stats(firstNineMpr: 4.11, bestFirstNineMpr: 8.67),
    )));

    expect(_first9Row(tester), ['First 9 MPR', '4.11', '8.67']);
  });

  testWidgets('First 9 MPR BEST reads "—" only when there is no best yet',
      (tester) async {
    await tester.pumpWidget(_wrap(CricketStatsDetailTableWidget(
      stats: _stats(),
    )));

    expect(_first9Row(tester), ['First 9 MPR', '—', '—']);
  });
}
