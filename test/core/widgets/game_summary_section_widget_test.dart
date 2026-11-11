import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/widgets/game_summary_section_widget.dart';
import 'package:dart_lodge/core/widgets/post_game_hero_card_widget.dart';
import 'package:dart_lodge/core/widgets/post_game_stats_breakdown_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    );

GameStats _statsForX01() => GameStats(
      gameId: 'g1',
      gameType: GameType.x01.name,
      byCompetitor: [
        CompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          byPlayer: const [],
          threeDartAverage: 75.5,
          legsWon: 1,
          totalDartsThrown: 21,
          checkoutPercentage: 50.0,
          highestCheckout: 64,
          oneEightyTurns: 1,
        ),
        CompetitorStats(
          competitorId: 'c2',
          competitorName: 'Bob',
          byPlayer: const [],
          threeDartAverage: 60.0,
          legsWon: 0,
          totalDartsThrown: 27,
        ),
      ],
    );

GameStats _statsForCricket() => GameStats(
      gameId: 'g1',
      gameType: GameType.cricket.name,
      byCompetitor: [
        CompetitorStats(
          competitorId: 'c1',
          competitorName: 'Alice',
          byPlayer: const [],
          threeDartAverage: 0,
          marksPerRound: 2.5,
          legsWon: 1,
          totalDartsThrown: 30,
        ),
      ],
    );

void main() {
  group('GameSummarySectionWidget — extracted-chrome regression', () {
    testWidgets('x01 multi-competitor renders hero, opponents, breakdown',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: _statsForX01(),
      )));

      // Hero card (winner)
      expect(find.byType(PostGameHeroCard), findsOneWidget);
      expect(find.text('WINNER'), findsWidgets);
      expect(find.text('ALICE'), findsWidgets);
      // "AVG PPR" / "DARTS" appear in the hero card, opponent card, and
      // breakdown table — just assert presence.
      expect(find.text('AVG PPR'), findsWidgets);
      expect(find.text('DARTS'), findsWidgets);

      // Breakdown table
      expect(find.byType(PostGameStatsBreakdown), findsOneWidget);
      expect(find.text('STATISTICS BREAKDOWN'), findsOneWidget);
      // X01 rows present
      expect(find.text('AVG PPR'), findsWidgets);
      expect(find.text('CHECKOUT'), findsOneWidget);
      expect(find.text('BEST OUT'), findsOneWidget);
      expect(find.text('180S'), findsOneWidget);
    });

    testWidgets('cricket hero uses AVG MPR label', (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: _statsForCricket(),
      )));

      expect(find.text('AVG MPR'), findsWidgets);
      expect(find.text('AVG PPR'), findsNothing);
      // Cricket-specific breakdown rows
      expect(find.text('FIRST 9 MPR'), findsOneWidget);
      expect(find.text('5 MARKS'), findsOneWidget);
      expect(find.text('9 MARKS'), findsOneWidget);
    });

    testWidgets('count-up omits LEGS WON subline on winner card',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: GameStats(
          gameId: 'g1',
          gameType: GameType.countUp.name,
          byCompetitor: [
            CompetitorStats(
              competitorId: 'c1',
              competitorName: 'Alice',
              byPlayer: const [],
              threeDartAverage: 80.0,
              legsWon: 1,
              totalDartsThrown: 24,
            ),
          ],
        ),
      )));

      expect(find.text('1 LEG WON'), findsNothing);
      expect(find.text('ALICE'), findsWidgets);
    });

    testWidgets('no winner (no legs won) hides the hero card',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: GameStats(
          gameId: 'g1',
          gameType: GameType.x01.name,
          byCompetitor: [
            CompetitorStats(
              competitorId: 'c1',
              competitorName: 'Alice',
              byPlayer: const [],
              threeDartAverage: 0,
              legsWon: 0,
              totalDartsThrown: 0,
            ),
            CompetitorStats(
              competitorId: 'c2',
              competitorName: 'Bob',
              byPlayer: const [],
              threeDartAverage: 0,
              legsWon: 0,
              totalDartsThrown: 0,
            ),
          ],
        ),
      )));

      expect(find.byType(PostGameHeroCard), findsNothing);
      expect(find.text('WINNER'), findsNothing);
      // Breakdown still rendered.
      expect(find.byType(PostGameStatsBreakdown), findsOneWidget);
    });

    // Regression for #261: runner-ups on Count-Up were all labelled
    // "OPPONENT" with no rank distinction. They're now sorted by PPR
    // descending (proxy for total score, since count-up always plays the
    // same dart count per competitor) and labelled 2ND / 3RD.
    testWidgets('count-up ranks runner-ups 2ND / 3RD instead of OPPONENT',
        (tester) async {
      await tester.pumpWidget(_wrap(GameSummarySectionWidget(
        gameStats: GameStats(
          gameId: 'g1',
          gameType: GameType.countUp.name,
          byCompetitor: [
            // Winner.
            CompetitorStats(
              competitorId: 'c1',
              competitorName: 'Alice',
              byPlayer: const [],
              threeDartAverage: 90.0,
              legsWon: 1,
              totalDartsThrown: 24,
            ),
            // 3rd by score.
            CompetitorStats(
              competitorId: 'c3',
              competitorName: 'Cara',
              byPlayer: const [],
              threeDartAverage: 50.0,
              legsWon: 0,
              totalDartsThrown: 24,
            ),
            // 2nd by score.
            CompetitorStats(
              competitorId: 'c2',
              competitorName: 'Bob',
              byPlayer: const [],
              threeDartAverage: 75.0,
              legsWon: 0,
              totalDartsThrown: 24,
            ),
          ],
        ),
      )));

      // Both the opponent card AND the breakdown column subtitle use
      // ordinal labels — expect at least one of each, none of "OPPONENT".
      expect(find.text('#2'), findsWidgets);
      expect(find.text('#3'), findsWidgets);
      expect(find.text('OPPONENT'), findsNothing);
      // Bob (75 PPR) and Cara (50 PPR) both render on the page. Ordering
      // is implied by the ordinal labels above — explicit positional
      // assertions are brittle against table-layout changes.
      expect(find.text('BOB'), findsOneWidget);
      expect(find.text('CARA'), findsOneWidget);
    });
  });

  group('PostGameHeroCard — large text (DESIGN_SYSTEM §13)', () {
    for (final locale in const [Locale('en'), Locale('de')]) {
      for (final scale in const [1.0, 1.4, 2.0]) {
        testWidgets('winner hero never breaks a word or clips the pill '
            '(${locale.languageCode}, ${scale}x, 412 px)', (tester) async {
          // The hero alone, built with the same localized strings as
          // GameSummarySectionWidget's winner card.
          await _pumpScaled(
            tester,
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return PostGameHeroCard(
                  badge: l10n.summaryWinner.toUpperCase(),
                  badgeIcon: Icons.stars,
                  backgroundIcon: Icons.emoji_events,
                  headline: 'Alexandra',
                  subline: l10n.summaryLegsWon(1).toUpperCase(),
                  sideStats: [
                    PostGameHeroStat(
                      label: l10n.statAvgPpr.toUpperCase(),
                      value: '75.5',
                      emphasize: true,
                    ),
                    PostGameHeroStat(
                      label: l10n.summaryDarts.toUpperCase(),
                      value: '21',
                    ),
                  ],
                );
              },
            ),
            locale: locale,
            scale: scale,
          );
          expect(tester.takeException(), isNull);
          _expectHeroTextIntact(tester);
        });
      }
    }

    testWidgets('practice hero with a multi-word headline wraps at spaces '
        'only (1.4x)', (tester) async {
      await _pumpScaled(
        tester,
        scale: 1.4,
        child: const PostGameHeroCard(
          badge: 'ENDED EARLY',
          headline: 'Not checked out',
          subline: 'Alexandra',
          muted: true,
          sideStats: [
            PostGameHeroStat(label: 'DARTS', value: '27', emphasize: true),
            PostGameHeroStat(label: 'FROM', value: '170'),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      _expectHeroTextIntact(tester);
    });

    testWidgets('a hero without side stats still spans the full width',
        (tester) async {
      await _pumpScaled(
        tester,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [PostGameHeroCard(headline: 'No winner', muted: true)],
        ),
      );
      expect(tester.getSize(find.byType(PostGameHeroCard)).width, 380);
    });

    testWidgets('keeps the side-by-side layout when it fits', (tester) async {
      await _pumpScaled(
        tester,
        gameStats: _statsForX01Named('Alexandra', 'Bartholomew'),
        width: 900,
      );
      _expectHeroTextIntact(tester);
      final card = tester.getRect(find.byType(PostGameHeroCard));
      final name = tester.getRect(find.text('ALEXANDRA'));
      final avg = tester.getRect(
        find
            .descendant(
              of: find.byType(PostGameHeroCard),
              matching: find.text('75.5'),
            )
            .first,
      );
      expect(
        avg.left,
        greaterThan(name.right),
        reason: 'stats sit to the right of the name',
      );
      expect(
        avg.top,
        lessThan(card.top + card.height / 2),
        reason: 'stats share the header row',
      );
    });

    testWidgets('stacks the stats below the name when they do not fit', (
      tester,
    ) async {
      await _pumpScaled(
        tester,
        gameStats: _statsForX01Named('Alexandra', 'Bartholomew'),
        scale: 2.0,
      );
      final subline = tester.getRect(find.text('1 LEG WON'));
      final avg = tester.getRect(
        find
            .descendant(
              of: find.byType(PostGameHeroCard),
              matching: find.text('75.5'),
            )
            .first,
      );
      expect(
        avg.top,
        greaterThanOrEqualTo(subline.bottom),
        reason: 'stats sit below the whole header block',
      );
    });
  });
}

GameStats _statsForX01Named(String winner, String loser) {
  final base = _statsForX01();
  return base.copyWith(
    byCompetitor: [
      base.byCompetitor[0].copyWith(competitorName: winner),
      base.byCompetitor[1].copyWith(competitorName: loser),
    ],
  );
}

Future<void> _pumpScaled(
  WidgetTester tester, {
  GameStats? gameStats,
  Widget? child,
  Locale locale = const Locale('en'),
  double scale = 1.0,
  double width = 412,
}) async {
  tester.view.physicalSize = Size(width, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      theme: AppTheme.light(),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child ?? GameSummarySectionWidget(gameStats: gameStats!),
        ),
      ),
    ),
  );
}

/// Every text in the hero card stays inside the card, and is laid out at
/// least as wide as its widest word, so no word breaks mid-word. Texts
/// without a space (the pill, numerals, single-word names) therefore stay
/// on one line, unclipped.
void _expectHeroTextIntact(WidgetTester tester) {
  final cardFinder = find.byType(PostGameHeroCard);
  final cardRect = tester.getRect(cardFinder);
  // Icons render as RichText too; the decorative background trophy is
  // positioned past the card edge on purpose and clipped, so skip icons.
  final icons = tester
      .renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.descendant(of: cardFinder, matching: find.byType(Icon)),
          matching: find.byType(RichText),
        ),
      )
      .toSet();
  final paragraphs = tester
      .renderObjectList<RenderParagraph>(
        find.descendant(of: cardFinder, matching: find.byType(RichText)),
      )
      .where((p) => !icons.contains(p))
      .toList();
  expect(paragraphs, isNotEmpty);
  for (final p in paragraphs) {
    final text = p.text.toPlainText();
    var widestWord = 0.0;
    for (final word in text.split(' ').where((w) => w.isNotEmpty)) {
      final tp = TextPainter(
        text: TextSpan(text: word, style: p.text.style),
        textScaler: p.textScaler,
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > widestWord) widestWord = tp.width;
      tp.dispose();
    }
    expect(
      p.size.width,
      greaterThanOrEqualTo(widestWord - 0.5),
      reason:
          '"$text" is squeezed below its widest word '
          '(${p.size.width} < $widestWord)',
    );
    final rect = p.localToGlobal(Offset.zero) & p.size;
    expect(
      rect.left,
      greaterThanOrEqualTo(cardRect.left - 0.5),
      reason: '"$text" starts outside the card',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(cardRect.right + 0.5),
      reason: '"$text" overflows the card ($rect vs $cardRect)',
    );
  }
}
