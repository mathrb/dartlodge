import 'package:dart_lodge/core/widgets/post_game_stats_breakdown_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The breakdown fills the width when its columns fit, and only falls back to a
// horizontal scroll when the table would be too wide (#693, keeping #334/#309
// behaviour for genuinely wide tables).
void main() {
  PostGameStatsBreakdown breakdown(int players) => PostGameStatsBreakdown(
        categoryHeader: 'CATEGORY',
        columns: [
          for (var i = 0; i < players; i++)
            PostGameBreakdownColumn(name: 'P${i + 1}'),
        ],
        rows: [
          PostGameBreakdownRow(
            category: 'AVG',
            values: [for (var i = 0; i < players; i++) '10'],
            highlights: [for (var i = 0; i < players; i++) false],
          ),
        ],
      );

  Future<void> pumpAt(WidgetTester tester, double width, int players) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: breakdown(players)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Finder horizontalScroll() => find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal);

  testWidgets('fills the width (no horizontal scroll) on a phone with few '
      'players', (tester) async {
    await pumpAt(tester, 380, 1); // (1+1)*92 = 184 <= 380 → fill
    expect(horizontalScroll(), findsNothing);
  });

  testWidgets('still fills for 3 players when they fit', (tester) async {
    await pumpAt(tester, 380, 3); // (3+1)*92 = 368 <= 380 → fill
    expect(horizontalScroll(), findsNothing);
  });

  testWidgets('falls back to horizontal scroll when too wide (many players)',
      (tester) async {
    await pumpAt(tester, 380, 6); // (6+1)*92 = 644 > 380 → scroll
    expect(horizontalScroll(), findsOneWidget);
  });

  testWidgets('fills on a wide (desktop) viewport regardless of column count',
      (tester) async {
    await pumpAt(tester, 800, 6); // maxWidth >= 600 → fill
    expect(horizontalScroll(), findsNothing);
  });
}
