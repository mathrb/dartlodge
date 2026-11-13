// The game boards' accent FOREGROUNDS (closed Cricket mark, X01 keypad
// double/triple dots, status-bar dart badges, active player name) used the
// fixed brand neon `primaryFixed` (#00FFAB) in both themes. On the light
// greys that is 1.16–1.29:1, below WCAG 1.4.11 (3:1, graphics) and 1.4.3
// (4.5:1, text). They now resolve through `AppTheme.boardAccent`: the
// adaptive `primary` on light, the neon (unchanged) on dark.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_text_styles.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_mark_painter.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_marks_strip_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_unified_table_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dot_row_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/game_status_bar_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/player_score_section_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

Widget _wrap(Widget child, {required bool dark}) => MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// WCAG 2.x contrast ratio of [fg] composited over the opaque [bg].
double _contrast(Color fg, Color bg) {
  final over = Color.alphaBlend(fg, bg);
  final a = over.computeLuminance();
  final b = bg.computeLuminance();
  final hi = a > b ? a : b;
  final lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}

// The light board surfaces these foregrounds sit on.
const _lightSurfaces = [
  AppColors.surface,
  AppColors.surfaceContainerLow,
  AppColors.surfaceContainer,
];

GameState _cricketState() => const GameState(
      gameId: 'g1',
      gameType: GameType.cricket,
      competitors: [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 0,
          startingScore: 0,
          marksPerNumber: {'20': 3},
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
    );

GameState _x01State() => const GameState(
      gameId: 'g1',
      gameType: GameType.x01,
      competitors: [
        CompetitorState(
          competitorId: 'c1',
          name: 'Alice',
          playerIds: ['p1'],
          score: 441,
          startingScore: 501,
          dartThrows: ['T20'],
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 1,
      isComplete: false,
      turnActive: true,
      startingScore: 501,
    );

void main() {
  group('AppTheme.boardAccent', () {
    testWidgets('light → primary; dark → primaryFixed (dimmed on request)',
        (tester) async {
      late Color light, dark, darkDim;
      await tester.pumpWidget(_wrap(Builder(builder: (c) {
        light = AppTheme.boardAccent(c, darkAlpha: 0.7);
        return const SizedBox();
      }), dark: false));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_wrap(Builder(builder: (c) {
        dark = AppTheme.boardAccent(c);
        darkDim = AppTheme.boardAccent(c, darkAlpha: 0.7);
        return const SizedBox();
      }), dark: true));
      await tester.pumpAndSettle();

      expect(light, AppColors.primary,
          reason: 'darkAlpha must not dim the light-theme accent');
      expect(dark, AppColorsDark.primaryFixed);
      expect(darkDim, AppColorsDark.primaryFixed.withValues(alpha: 0.7));
    });

    test('light accent meets 4.5:1 on every light board surface', () {
      for (final bg in _lightSurfaces) {
        expect(_contrast(AppColors.primary, bg), greaterThanOrEqualTo(4.5),
            reason: 'primary on $bg');
        // Sanity: the old neon fails even the 3:1 graphics threshold.
        expect(_contrast(AppColors.primaryFixed, bg), lessThan(3));
      }
    });
  });

  group('Cricket closed mark', () {
    Color closedColour(WidgetTester tester) => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<CricketMarkPainter>()
        .firstWhere((p) => p.marks >= 3)
        .color;

    testWidgets('unified table: primary on light, neon on dark',
        (tester) async {
      Widget table(bool dark) => _wrap(
          CricketUnifiedTableWidget(
            gameState: _cricketState(),
            onMiss: () {},
            onSegmentTapped: (_) {},
          ),
          dark: dark);

      await tester.pumpWidget(table(false));
      await tester.pumpAndSettle();
      expect(closedColour(tester), AppColors.primary);

      await tester.pumpWidget(table(true));
      await tester.pumpAndSettle();
      expect(closedColour(tester), AppColorsDark.primaryFixed);
    });

    testWidgets('camera-first strip: closed mark + active name follow theme',
        (tester) async {
      Widget strip(bool dark) => _wrap(
          const CricketMarksStripWidget(
            targets: [20, 19, 18, 17, 16, 15, 25],
            rows: [
              (
                name: 'Alice',
                marks: [3, 0, 0, 0, 0, 0, 0],
                score: 0,
                isActive: true,
                mpr: '0',
                legs: null,
              ),
              // A second player keeps the 20 live (closed by all = dead).
              (
                name: 'Bob',
                marks: [0, 0, 0, 0, 0, 0, 0],
                score: 0,
                isActive: false,
                mpr: '0',
                legs: null,
              ),
            ],
          ),
          dark: dark);

      await tester.pumpWidget(strip(false));
      await tester.pumpAndSettle();
      expect(closedColour(tester), AppColors.primary);
      expect(tester.widget<Text>(find.text('ALICE')).style?.color,
          AppColors.primary);

      await tester.pumpWidget(strip(true));
      await tester.pumpAndSettle();
      expect(closedColour(tester), AppColorsDark.primaryFixed);
      expect(tester.widget<Text>(find.text('ALICE')).style?.color,
          AppColorsDark.primaryFixed);
    });
  });

  group('X01 keypad double/triple dots', () {
    testWidgets('primary on light, 70% neon on dark', (tester) async {
      Widget grid(bool dark) =>
          _wrap(DartInputGridWidget(onSegmentTapped: (_) {}), dark: dark);

      Set<Color> dotColours() =>
          tester.widgetList<DotRow>(find.byType(DotRow)).map((d) => d.color).toSet();

      await tester.pumpWidget(grid(false));
      await tester.pumpAndSettle();
      expect(find.byType(DotRow), findsWidgets);
      expect(dotColours(), {AppColors.primary});

      await tester.pumpWidget(grid(true));
      await tester.pumpAndSettle();
      expect(dotColours(),
          {AppColorsDark.primaryFixed.withValues(alpha: 0.7)});
    });

    testWidgets('BULL subtext follows the theme', (tester) async {
      await tester.pumpWidget(
          _wrap(DartInputGridWidget(onSegmentTapped: (_) {}), dark: false));
      await tester.pumpAndSettle();
      // Two BULL labels: the outer-bull subtext (accent) and the 50 key's
      // label (onPrimaryFixed on the neon fill, unchanged).
      final colours = tester
          .widgetList<Text>(find.text('BULL'))
          .map((t) => t.style?.color)
          .toSet();
      expect(colours, {AppColors.primary, AppColors.onPrimaryFixed});
    });
  });

  group('status-bar dart badge text', () {
    testWidgets('primary on light, neon on dark', (tester) async {
      Widget bar(bool dark) => _wrap(
          const GameStatusBarWidget(
            configLabel: '501',
            roundInLeg: 1,
            currentTurnDarts: ['T20', 'D19', ''],
          ),
          dark: dark);

      await tester.pumpWidget(bar(false));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('T20')).style?.color,
          AppColors.primary);

      await tester.pumpWidget(bar(true));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('T20')).style?.color,
          AppColorsDark.primaryFixed);
    });
  });

  group('X01 active player card', () {
    testWidgets('name + turn score use primary on light', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 200),
      );
      addTearDown(controller.dispose);

      Widget section(bool dark) => _wrap(
          PlayerScoreSectionWidget(
            gameState: _x01State(),
            bustFlashAnim: controller,
          ),
          dark: dark);

      await tester.pumpWidget(section(false));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('ALICE')).style?.color,
          AppColors.primary);
      // Turn score (T20 = 60), body-small text → full-opacity primary.
      final turn = tester
          .widgetList<Text>(find.text('60'))
          .firstWhere((t) => t.style?.fontSize == AppTextStyles.bodySmall.fontSize);
      expect(turn.style?.color, AppColors.primary);

      await tester.pumpWidget(section(true));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('ALICE')).style?.color,
          AppColorsDark.primaryFixed);
    });
  });
}
