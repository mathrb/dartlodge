// The player stats page at large system text sizes (DESIGN_SYSTEM §13):
// the tab labels, the summary cards, the time-range segments and the
// detail-table headers must stay whole (no clipped tab, no word broken
// mid-word, no header pair running together) at 412 px in the longer
// locales. The shared header's back button is announced in the app locale.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/providers/players_providers.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/widgets/app_header.dart';
import 'package:dart_lodge/core/widgets/stats_table_widget.dart';
import 'package:dart_lodge/features/statistics/domain/entities/dart_position.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_leg_snapshot.dart';
import 'package:dart_lodge/features/statistics/domain/entities/player_stats.dart';
import 'package:dart_lodge/features/statistics/presentation/pages/player_stats_page.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/dart_heatmap_provider.dart';
import 'package:dart_lodge/features/statistics/presentation/providers/player_stats_page_provider.dart'
    show
        filteredPlayerStatsProvider,
        playerLegHistoryProvider,
        playerX01StartingScoresProvider;
import 'package:dart_lodge/features/statistics/presentation/widgets/stats_card_row_widget.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/stats_card_widget.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/summary_cards_row_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

const _stats = PlayerStats(
  playerId: 'p1',
  gameType: GameType.x01,
  totalGames: 12,
  gamesWon: 7,
  winRate: 0.583,
  threeDartAverage: 100.5,
  highestTurnScore: 180,
  totalDartsThrown: 900,
  dartsPerLeg: 18.4,
  bustRate: 0.1,
  legsPlayed: 128,
  legsWon: 104,
  sixtyPlusTurns: 140,
  oneHundredPlusTurns: 120,
  oneFortyPlusTurns: 100,
  oneEightyTurns: 12,
);

Future<void> _pumpPage(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double scale = 1.0,
  double width = 412,
  FutureOr<PlayerStats> Function()? stats,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        playerProvider('p1').overrideWith((ref) async => null),
        filteredPlayerStatsProvider(
          'p1',
        ).overrideWith((ref) async => stats == null ? _stats : stats()),
        playerX01StartingScoresProvider(
          'p1',
        ).overrideWith((ref) async => const <int>[]),
        playerLegHistoryProvider(
          'p1',
        ).overrideWith((ref) async => const <PlayerLegSnapshot>[]),
        dartHeatmapProvider.overrideWith(
          (ref, filter) => const <DartPosition>[],
        ),
      ],
      child: MaterialApp(
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
        home: const PlayerStatsPage(playerId: 'p1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Widest unbreakable run of [text]: words split at spaces, and after a
/// hyphen (where the line breaker may wrap "Checkout-Punkte").
double _widestWord(String text, TextStyle? style, TextScaler scaler) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r' |(?<=-)'))) {
    if (word.isEmpty) continue;
    final tp = TextPainter(
      text: TextSpan(text: word, style: style),
      textScaler: scaler,
      textDirection: TextDirection.ltr,
    )..layout();
    if (tp.width > widest) widest = tp.width;
    tp.dispose();
  }
  return widest;
}

List<RenderParagraph> _paragraphs(WidgetTester tester, Finder container) {
  final icons = tester
      .renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.descendant(of: container, matching: find.byType(Icon)),
          matching: find.byType(RichText),
        ),
      )
      .toSet();
  return tester
      .renderObjectList<RenderParagraph>(
        find.descendant(of: container, matching: find.byType(RichText)),
      )
      .where((p) => !icons.contains(p))
      .toList();
}

Rect _globalRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

/// Every non-icon text under [container] is laid out at least as wide as its
/// widest word (no mid-word break, no clipped or faded label) and, unless
/// [checkBounds] is false, is painted inside the screen width.
void _expectTextIntact(
  WidgetTester tester,
  Finder container, {
  bool checkBounds = true,
}) {
  final paragraphs = _paragraphs(tester, container);
  expect(paragraphs, isNotEmpty);
  final screenWidth = tester.view.physicalSize.width;
  for (final p in paragraphs) {
    final text = p.text.toPlainText();
    final widest = _widestWord(text, p.text.style, p.textScaler);
    expect(
      p.size.width,
      greaterThanOrEqualTo(widest - 0.5),
      reason: '"$text" is squeezed below its widest word '
          '(${p.size.width} < $widest)',
    );
    expect(
      p.didExceedMaxLines,
      isFalse,
      reason: '"$text" is truncated',
    );
    if (checkBounds) {
      final rect = _globalRect(p);
      expect(rect.left, greaterThanOrEqualTo(-0.5),
          reason: '"$text" starts off screen');
      expect(rect.right, lessThanOrEqualTo(screenWidth + 0.5),
          reason: '"$text" overflows the screen ($rect)');
    }
  }
}

/// The header labels of the two value columns of [StatsTableWidget] keep a
/// visible gap between them.
void _expectHeaderGaps(WidgetTester tester, List<(String, String)> pairs) {
  for (final (left, right) in pairs) {
    final l = _globalRect(
      tester.renderObject<RenderBox>(find.text(left).first),
    );
    final r = _globalRect(
      tester.renderObject<RenderBox>(find.text(right).first),
    );
    // Painted (glyph) extents: the end-aligned text sits at the right of
    // its paragraph box.
    final lp = tester.renderObject<RenderParagraph>(find.text(left).first);
    final rp = tester.renderObject<RenderParagraph>(find.text(right).first);
    final lInk = lp.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: left.length),
    );
    final rInk = rp.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: right.length),
    );
    final lScale = l.width / lp.size.width;
    final rScale = r.width / rp.size.width;
    final lRight = l.left + lInk.last.right * lScale;
    final rLeft = r.left + rInk.first.left * rScale;
    expect(
      rLeft - lRight,
      greaterThanOrEqualTo(8 - 0.5),
      reason: '"$left" and "$right" run together (${rLeft - lRight} px)',
    );
  }
}

void main() {
  group('PlayerStatsPage — large text (DESIGN_SYSTEM §13)', () {
    for (final locale in const [Locale('de'), Locale('fr'), Locale('es')]) {
      for (final scale in const [1.0, 1.4, 2.0]) {
        testWidgets('tabs, summary cards, time range and table headers stay '
            'whole (${locale.languageCode}, ${scale}x, 412 px)',
            (tester) async {
          await _pumpPage(tester, locale: locale, scale: scale);
          expect(tester.takeException(), isNull);
          // Tabs may scroll horizontally; each label is whole.
          _expectTextIntact(tester, find.byType(TabBar), checkBounds: false);
          _expectTextIntact(tester, find.byType(SummaryCardsRowWidget));
          _expectTextIntact(tester, find.byWidgetPredicate((w) => w is SegmentedButton));
          final l10n = await AppLocalizations.delegate.load(locale);
          // The header rows of the detail table (data-row labels may wrap
          // at word boundaries; data values are numerals).
          for (final header in [
            l10n.statsColAverage,
            l10n.statsColBest,
            l10n.statsColTotal,
            l10n.statsColPerLeg,
          ]) {
            _expectTextIntact(
              tester,
              find.ancestor(
                of: find.text(header),
                matching: find.byType(Row),
              ).first,
            );
          }
          _expectTextIntact(tester, find.byType(StatsTableWidget));
          _expectHeaderGaps(tester, [
            (l10n.statsColAverage, l10n.statsColBest),
            (l10n.statsColTotal, l10n.statsColPerLeg),
          ]);
        });
      }
    }

    testWidgets('summary card numerals line up when the labels wrap to '
        'different line counts', (tester) async {
      tester.view.physicalSize = const Size(412, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            // Unbounded height, as on the stats page.
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: StatsCardRowWidget(
                cards: [
                  StatsCardWidget(label: 'Legs', value: '128'),
                  StatsCardWidget(
                    label: 'Games played this season',
                    value: '104',
                  ),
                  StatsCardWidget(label: 'Won', value: '12'),
                ],
              ),
            ),
          ),
        ),
      );
      final label = tester.getRect(find.text('Games played this season'));
      final oneLine = tester.getRect(find.text('Legs'));
      expect(label.height, greaterThan(oneLine.height * 1.5),
          reason: 'the fixture label should wrap');
      final tops = ['128', '104', '12']
          .map((v) => tester.getRect(find.text(v)).top)
          .toList();
      expect(tops[1], closeTo(tops[0], 0.5));
      expect(tops[2], closeTo(tops[0], 0.5));
    });

    testWidgets('stacks the summary cards when one cannot fit its share',
        (tester) async {
      await _pumpPage(tester, locale: const Locale('de'), scale: 2.0);
      final values = ['128', '104', '12']
          .map((v) => tester.getRect(find.text(v).first))
          .toList();
      expect(values[1].top, greaterThan(values[0].bottom));
      expect(values[2].top, greaterThan(values[1].bottom));
    });

    testWidgets('keeps the fixed-width tab row when the labels fit',
        (tester) async {
      await _pumpPage(tester);
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.isScrollable, isFalse);
    });

    testWidgets('scrolls the tab row when a label does not fit',
        (tester) async {
      await _pumpPage(tester, locale: const Locale('fr'));
      final bar = tester.widget<TabBar>(find.byType(TabBar));
      expect(bar.isScrollable, isTrue);
      expect(bar.tabAlignment, TabAlignment.start);
    });

    testWidgets('keeps the three summary cards side by side at 1.0x',
        (tester) async {
      await _pumpPage(tester, locale: const Locale('de'));
      final values = ['128', '104', '12']
          .map((v) => tester.getRect(find.text(v).first))
          .toList();
      expect(values[1].left, greaterThan(values[0].right));
      expect(values[2].left, greaterThan(values[1].right));
    });
  });

  group('AppHeader back button', () {
    for (final (locale, label) in const [
      (Locale('en'), 'Back'),
      (Locale('de'), 'Zurück'),
      (Locale('fr'), 'Retour'),
    ]) {
      testWidgets('is announced in the app locale (${locale.languageCode})',
          (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: kSupportedLocales,
            home: const Scaffold(body: AppHeader(showBack: true)),
          ),
        );
        expect(find.bySemanticsLabel(label), findsOneWidget);
        handle.dispose();
      });
    }
  });
}
