import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// The X01 301 game from the History detail report: a long and a medium name,
/// three-chip turns and a CHECKOUT flag.
LegTurnBreakdown _x01LongNames() => const LegTurnBreakdown(turns: [
      TurnRow(
        round: 1,
        competitorId: 'a',
        competitorName: 'Alexandra',
        darts: ['T20', 'T20', 'T20'],
        turnScore: 180,
        startingScore: 301,
        remainingScore: 121,
      ),
      TurnRow(
        round: 1,
        competitorId: 'b',
        competitorName: 'Bartholomew',
        darts: ['20', '20', '20'],
        turnScore: 60,
        startingScore: 301,
        remainingScore: 241,
      ),
      TurnRow(
        round: 2,
        competitorId: 'a',
        competitorName: 'Alexandra',
        darts: ['T20', 'T19', 'D2'],
        turnScore: 121,
        startingScore: 121,
        remainingScore: 0,
        checkout: true,
      ),
    ]);

LegTurnBreakdown _cricketTwoPlayer() => const LegTurnBreakdown(turns: [
      TurnRow(
        round: 1,
        competitorId: 'a',
        competitorName: 'Alexandra',
        darts: ['T20', 'MISS', 'D19'],
        turnScore: 5,
      ),
      TurnRow(
        round: 1,
        competitorId: 'b',
        competitorName: 'Bartholomew',
        darts: ['SB', '18', 'T17'],
        turnScore: 5,
      ),
    ]);

/// Pumps the table on a [width] px wide phone (412 by default) inside the detail page's 16 px
/// padding, in [locale] at [scale] text size.
Future<void> _pumpPhone(
  WidgetTester tester, {
  required GameType gameType,
  required LegTurnBreakdown breakdown,
  Locale locale = const Locale('en'),
  double scale = 1.0,
  double width = 412,
}) async {
  tester.view.physicalSize = Size(width, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: TurnBreakdownTableWidget(
          gameType: gameType,
          breakdown: breakdown,
        ),
      ),
    ),
  ));
}

/// Every visible text in the table except player names (which may ellipsize
/// in the table layout) is laid out at its full single-line width: no header
/// breaks mid-word, no chip or CHECKOUT flag is clipped, so no column has
/// collapsed. Also checks every text stays inside the table horizontally.
void _expectNoTextSqueezed(WidgetTester tester, {Set<String> names = const {}}) {
  final tableRect = tester.getRect(find.byType(TurnBreakdownTableWidget));
  final paragraphs = find.descendant(
    of: find.byType(TurnBreakdownTableWidget),
    matching: find.byType(RichText),
  );
  expect(paragraphs, findsWidgets);
  for (final element in paragraphs.evaluate()) {
    final rp = element.renderObject! as RenderParagraph;
    final text = rp.text.toPlainText();
    if (names.contains(text)) continue;
    final needed = rp.getMaxIntrinsicWidth(double.infinity);
    expect(rp.size.width, greaterThanOrEqualTo(needed - 0.5),
        reason: '"$text" is squeezed to ${rp.size.width} px, '
            'needs $needed px on one line');
    final rect = rp.localToGlobal(Offset.zero) & rp.size;
    expect(rect.left, greaterThanOrEqualTo(tableRect.left - 0.5),
        reason: '"$text" paints left of the table');
    expect(rect.right, lessThanOrEqualTo(tableRect.right + 0.5),
        reason: '"$text" paints right of the table');
  }
}

const _longNames = {'Alexandra', 'Bartholomew'};

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

  group('phone width (412 px)', () {
    for (final locale in const [Locale('en'), Locale('fr'), Locale('de')]) {
      for (final scale in const [1.0, 1.4]) {
        testWidgets(
            'X01 ${locale.languageCode} at ${scale}x: no header, chip or flag '
            'is squeezed', (tester) async {
          await _pumpPhone(tester,
              gameType: GameType.x01,
              breakdown: _x01LongNames(),
              locale: locale,
              scale: scale);
          _expectNoTextSqueezed(tester, names: _longNames);
          expect(find.text('T20'), findsNWidgets(4));
          expect(find.text('20'), findsNWidgets(3));
          expect(find.text('CHECKOUT'), findsOneWidget);
        });
      }
    }

    testWidgets('the column table is kept wherever its floors fit',
        (tester) async {
      // The test font draws every glyph 1 em wide, so the X01 floors only fit
      // a wider surface here; with the real font they fit a 412 px phone.
      await _pumpPhone(tester,
          gameType: GameType.x01, breakdown: _x01TwoPlayer(), width: 600);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('DARTS'), findsOneWidget);
      _expectNoTextSqueezed(tester);
    });

    testWidgets(
        'at 2.0x the turns stack instead of collapsing columns, keeping '
        'every value', (tester) async {
      await _pumpPhone(tester,
          gameType: GameType.x01, breakdown: _x01LongNames(), scale: 2.0);
      expect(find.byType(Table), findsNothing);
      // Each turn labels its own values.
      expect(find.text('DARTS'), findsNWidgets(3));
      expect(find.text('LEFT'), findsNWidgets(3));
      expect(find.text('Bartholomew'), findsOneWidget);
      expect(find.text('Alexandra'), findsNWidgets(2));
      expect(find.text('T20'), findsNWidgets(4));
      expect(find.text('CHECKOUT'), findsOneWidget);
      _expectNoTextSqueezed(tester);
    });

    testWidgets('Cricket at 2.0x stacks without a turn-score column',
        (tester) async {
      await _pumpPhone(tester,
          gameType: GameType.cricket,
          breakdown: _cricketTwoPlayer(),
          scale: 2.0);
      expect(find.byType(Table), findsNothing);
      expect(find.text('MARKS'), findsNWidgets(2));
      expect(find.text('MISS'), findsOneWidget);
      _expectNoTextSqueezed(tester);
    });
  });
}
