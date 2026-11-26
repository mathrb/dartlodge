import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/domain/models/game_result.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/shanghai_summary_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
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

  group('ended early from the menu', () {
    Color onSurface() => AppTheme.light().colorScheme.onSurface;

    // A 9-9 tie in round 2 of 7: the first-listed leader is only ahead by
    // list order, not a winner.
    const fourPlayers = [
      ShanghaiCompetitorResult(
        competitorId: 'c1',
        competitorName: 'Ana',
        totalScore: 9,
        shanghaiBonuses: 0,
        bestRound: 6,
        roundsPlayed: 2,
      ),
      ShanghaiCompetitorResult(
        competitorId: 'c2',
        competitorName: 'Ben',
        totalScore: 9,
        shanghaiBonuses: 0,
        bestRound: 6,
        roundsPlayed: 2,
      ),
      ShanghaiCompetitorResult(
        competitorId: 'c3',
        competitorName: 'Cal',
        totalScore: 3,
        shanghaiBonuses: 0,
        bestRound: 3,
        roundsPlayed: 1,
      ),
      ShanghaiCompetitorResult(
        competitorId: 'c4',
        competitorName: 'Dee',
        totalScore: 2,
        shanghaiBonuses: 0,
        bestRound: 2,
        roundsPlayed: 1,
      ),
    ];

    testWidgets(
        'multi-player: badge + "No winner" hero, nobody headlined, '
        'breakdown keeps every player', (tester) async {
      await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
        result: ShanghaiResult(
          competitors: fourPlayers,
          winnerCompetitorId: null,
          totalRounds: 7,
          endedEarly: true,
        ),
      )));

      expect(find.text('ENDED EARLY'), findsOneWidget);
      expect(find.text('NO WINNER'), findsOneWidget);
      // The hero uppercases its headline; the breakdown keeps names as-is.
      expect(find.text('ANA'), findsNothing,
          reason: 'the first-listed leader must not headline the hero');
      expect(find.text('WINNER'), findsNothing);
      // No hero side stats: TOTAL SCORE appears only as the table row.
      expect(find.text('SHANGHAIS'), findsNothing);
      expect(find.text('TOTAL SCORE'), findsOneWidget);
      for (final name in ['Ana', 'Ben', 'Cal', 'Dee']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('solo: badge, player still named, score not emphasised',
        (tester) async {
      await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
        result: ShanghaiResult(
          competitors: [
            ShanghaiCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              totalScore: 14,
              shanghaiBonuses: 0,
              bestRound: 8,
              roundsPlayed: 3,
            ),
          ],
          winnerCompetitorId: null,
          totalRounds: 7,
          endedEarly: true,
        ),
      )));

      expect(find.text('ENDED EARLY'), findsOneWidget);
      expect(find.text('ALICE'), findsOneWidget);
      // Hero stat + table cell both read 14; neither may be accent-coloured.
      for (final t in tester.widgetList<Text>(find.text('14'))) {
        expect(t.style?.color, onSurface());
      }
    });

    testWidgets('a natural end keeps the emphasised hero and no badge',
        (tester) async {
      await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
        result: ShanghaiResult(
          competitors: [
            ShanghaiCompetitorResult(
              competitorId: 'c1',
              competitorName: 'Alice',
              totalScore: 248,
              shanghaiBonuses: 0,
              bestRound: 80,
              roundsPlayed: 7,
            ),
          ],
          winnerCompetitorId: null,
          totalRounds: 7,
        ),
      )));

      expect(find.text('ENDED EARLY'), findsNothing);
      final heroScore = tester.widgetList<Text>(find.text('248')).first;
      expect(heroScore.style?.color, isNot(onSurface()));
    });

    testWidgets('a multi-player win keeps the winner hero and no badge',
        (tester) async {
      await tester.pumpWidget(_wrap(const ShanghaiSummaryWidget(
        result: ShanghaiResult(
          competitors: fourPlayers,
          winnerCompetitorId: 'c2',
          totalRounds: 7,
        ),
      )));

      expect(find.text('ENDED EARLY'), findsNothing);
      expect(find.text('NO WINNER'), findsNothing);
      expect(find.text('BEN'), findsOneWidget);
      expect(find.text('WINNER'), findsOneWidget);
    });
  });
}
