// The in-game boards at large text sizes (DESIGN_SYSTEM §13: layouts must
// not break at 1.4×). Before the fix, at 1.4× the 3-player X01 remaining
// score "376" wrapped to "37" / "6", the Cricket input labels stacked "20" as
// "2" / "0" (and "SB" as "S" / "B"), and the status-bar dart badges — the
// entry point for dart correction — were clipped off the right edge; at 2.0×
// no badge was visible at all, and the X01 keypad stacked "19" as "1" / "9".

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_text_styles.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_unified_table_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/game_status_bar_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/player_score_section_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

const _scales = [1.4, 2.0];

Future<void> _pumpScaled(
  WidgetTester tester,
  Widget child, {
  required double scale,
  double height = 915,
}) async {
  tester.view.physicalSize = Size(412, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

/// The non-icon paragraphs under [container].
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

RenderParagraph _paragraphWithText(
  WidgetTester tester,
  Finder container,
  String text,
) =>
    _paragraphs(tester, container)
        .firstWhere((p) => p.text.toPlainText() == text);

/// [p] is laid out on one line at its full width and height (no wrap, no clipped
/// glyphs) and painted inside [bounds] (a FittedBox scale-down counts at its
/// painted size).
void _expectOneLineInside(RenderParagraph p, Rect bounds) {
  final text = p.text.toPlainText();
  final tp = TextPainter(
    text: p.text,
    textScaler: p.textScaler,
    textDirection: TextDirection.ltr,
  )..layout();
  final natural = tp.size;
  tp.dispose();
  expect(
    p.size.width,
    greaterThanOrEqualTo(natural.width - 0.5),
    reason: '"$text" is squeezed (${p.size.width} < ${natural.width})',
  );
  expect(
    p.size.height,
    lessThanOrEqualTo(natural.height + 0.5),
    reason: '"$text" wraps onto several lines',
  );
  expect(
    p.size.height,
    greaterThanOrEqualTo(natural.height - 0.5),
    reason: '"$text" is clipped vertically '
        '(${p.size.height} < ${natural.height})',
  );
  final rect = MatrixUtils.transformRect(
    p.getTransformTo(null),
    Offset.zero & p.size,
  );
  expect(
    rect.left >= bounds.left - 0.5 && rect.right <= bounds.right + 0.5,
    isTrue,
    reason: '"$text" is painted outside its box ($rect vs $bounds)',
  );
}

CompetitorState _competitor(String name, int score, int startingScore) =>
    CompetitorState(
      competitorId: 'c-$name',
      name: name,
      playerIds: ['p-$name'],
      score: score,
      startingScore: startingScore,
    );

void main() {
  group('X01 three-player cards at large text', () {
    for (final scale in _scales) {
      testWidgets('remaining score stays on one line at ${scale}x',
          (tester) async {
        final controller = AnimationController(
          vsync: const TestVSync(),
          duration: const Duration(milliseconds: 300),
        );
        addTearDown(controller.dispose);
        final state = GameState(
          gameId: 'g1',
          gameType: GameType.x01,
          competitors: [
            _competitor('Alexandra', 376, 501),
            _competitor('Bartholomew', 501, 501),
            _competitor('Chiara', 501, 501),
          ],
          currentTurnIndex: 0,
          dartsThrownInTurn: 0,
          isComplete: false,
        );
        await _pumpScaled(
          tester,
          PlayerScoreSectionWidget(
            gameState: state,
            bustFlashAnim: controller,
          ),
          scale: scale,
        );

        final section = find.byType(PlayerScoreSectionWidget);
        for (final score in ['376', '501']) {
          final p = _paragraphWithText(tester, section, score);
          // The numeral keeps its design size (scoreMedium/scoreSmall)
          // instead of growing with the text scale until it wraps.
          expect(p.textScaler.scale(48), 48);
          _expectOneLineInside(p, tester.getRect(section));
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Cricket table at large text', () {
    GameState cricketState() => GameState(
          gameId: 'g1',
          gameType: GameType.cricket,
          competitors: [
            _competitor('Alexandra', 104, 0),
            _competitor('Bartholomew', 0, 0),
            _competitor('Chiara', 0, 0),
          ],
          currentTurnIndex: 0,
          dartsThrownInTurn: 0,
          isComplete: false,
          cricketTargets: const [15, 16, 17, 18, 19, 20],
          cricketTargetMode: 'fixed',
          cricketScoring: 'standard',
        );

    for (final scale in _scales) {
      testWidgets(
          'input labels, MISS and the score stay on one line at ${scale}x',
          (tester) async {
        await _pumpScaled(
          tester,
          CricketUnifiedTableWidget(
            gameState: cricketState(),
            onSegmentTapped: (_) {},
            onMiss: () {},
          ),
          scale: scale,
        );

        for (final label in [
          'Single 20',
          'Double 20',
          'Triple 20',
          'Single 15',
          'Single Bull',
          'Double Bull',
        ]) {
          final cell = find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == label,
          );
          expect(cell, findsOneWidget, reason: label);
          final bounds = tester.getRect(cell);
          final paragraphs = _paragraphs(tester, cell);
          expect(paragraphs, hasLength(1), reason: label);
          _expectOneLineInside(paragraphs.single, bounds);
        }

        final miss = find.ancestor(
          of: find.text('MISS'),
          matching: find.byType(InkWell),
        );
        _expectOneLineInside(
          _paragraphWithText(tester, miss, 'MISS'),
          tester.getRect(miss),
        );

        final table = find.byType(CricketUnifiedTableWidget);
        final score = _paragraphWithText(tester, table, '104');
        expect(score.textScaler.scale(48), 48);
        _expectOneLineInside(score, tester.getRect(table));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Status bar at large text', () {
    for (final scale in _scales) {
      testWidgets('all three dart badges stay visible at ${scale}x',
          (tester) async {
        await _pumpScaled(
          tester,
          const Align(
            alignment: Alignment.topCenter,
            child: GameStatusBarWidget(
              configLabel: 'Standard',
              roundInLeg: 1,
              totalRounds: 20,
              currentLegIndex: 0,
              maxLegs: 3,
              currentTurnDarts: ['T20', 'D17', 'SB'],
            ),
          ),
          scale: scale,
        );

        final bar = find.byType(GameStatusBarWidget);
        final barRect = tester.getRect(bar);
        for (final dart in ['T20', 'D17', 'SB']) {
          final p = _paragraphWithText(tester, bar, dart);
          _expectOneLineInside(p, barRect);
          // The badge box is tall enough for its text (not clipped
          // vertically by a fixed-height slot).
          final badge = find.ancestor(
            of: find.text(dart),
            matching: find.byType(Container),
          ).first;
          expect(
            tester.getSize(badge).height,
            greaterThanOrEqualTo(p.size.height),
            reason: '$dart badge clips its text',
          );
        }
        // The turn sum (T20 + D17 + SB = 119) stays readable too.
        _expectOneLineInside(_paragraphWithText(tester, bar, '119'), barRect);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('at 1.0x the metadata keeps its full size', (tester) async {
      await _pumpScaled(
        tester,
        const Align(
          alignment: Alignment.topCenter,
          child: GameStatusBarWidget(
            configLabel: '501',
            roundInLeg: 1,
            currentTurnDarts: ['T20'],
          ),
        ),
        scale: 1.0,
      );
      final config = find.text('501');
      final size = tester.getSize(config);
      final tp = TextPainter(
        text: TextSpan(
          text: '501',
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Painted at its natural size: the FittedBox does not shrink it.
      final painted = tester.getRect(config);
      expect(painted.width, closeTo(size.width, 0.5));
      expect(size.width, closeTo(tp.width, 0.5));
      tp.dispose();
    });
  });
  group('X01 keypad at large text', () {
    for (final scale in _scales) {
      testWidgets('two-digit labels stay on one line at ${scale}x',
          (tester) async {
        await _pumpScaled(
          tester,
          SizedBox(
            height: 420,
            child: DartInputGridWidget(onSegmentTapped: (_) {}),
          ),
          scale: scale,
        );
        for (final label in [
          'Single 19',
          'Single 10',
          'Double 18',
          'Triple 20',
          'Triple 11',
          'Single Bull',
          'Double Bull',
        ]) {
          final cell = find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == label,
          );
          expect(cell, findsOneWidget, reason: label);
          final paragraphs = _paragraphs(tester, cell);
          expect(paragraphs, isNotEmpty, reason: label);
          final bounds = tester.getRect(cell);
          for (final p in paragraphs) {
            _expectOneLineInside(p, bounds);
            // Painted inside the cell vertically too ("BULL" under the
            // number in the fixed-height bull row).
            final rect = MatrixUtils.transformRect(
              p.getTransformTo(null),
              Offset.zero & p.size,
            );
            expect(rect.bottom, lessThanOrEqualTo(bounds.bottom + 0.5),
                reason: '${p.text.toPlainText()} in $label');
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  });
}
