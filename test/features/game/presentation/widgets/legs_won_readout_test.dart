// The X01 / Cricket boards show each player's legs won during a multi-leg
// match, so the match score (e.g. 1-1 before a decider) is visible without
// waiting for the end screen. Single-leg games hide the readout.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_marks_strip_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_unified_table_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/legs_won_label.dart';
import 'package:dart_lodge/features/game/presentation/widgets/player_score_section_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/x01_other_players_strip_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

CompetitorState _competitor(String name, {int legsWon = 0, int score = 0}) =>
    CompetitorState(
      competitorId: 'c-$name',
      name: name,
      playerIds: ['p-$name'],
      score: score,
      startingScore: score,
      legsWon: legsWon,
    );

GameState _gameState({
  required GameType gameType,
  required int legsToWin,
  required List<CompetitorState> competitors,
}) => GameState(
  gameId: 'g1',
  gameType: gameType,
  competitors: competitors,
  currentTurnIndex: 0,
  dartsThrownInTurn: 0,
  isComplete: false,
  legsToWin: legsToWin,
  startingScore: 501,
  cricketTargets: gameType == GameType.cricket
      ? const [15, 16, 17, 18, 19, 20]
      : const [],
  cricketTargetMode: 'fixed',
  cricketScoring: 'standard',
);

AnimationController _flashController() => AnimationController(
  vsync: const TestVSync(),
  duration: const Duration(milliseconds: 200),
);

void main() {
  group('legsWonLabel', () {
    testWidgets('formats the tally in a multi-leg game, null in a single leg', (
      tester,
    ) async {
      final alex = _competitor('Alex', legsWon: 1);
      final multi = _gameState(
        gameType: GameType.x01,
        legsToWin: 2,
        competitors: [alex],
      );
      final single = _gameState(
        gameType: GameType.x01,
        legsToWin: 1,
        competitors: [alex],
      );
      String? multiLabel;
      String? singleLabel;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              multiLabel = legsWonLabel(context, multi, alex);
              singleLabel = legsWonLabel(context, single, alex);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(multiLabel, 'LEGS 1');
      expect(singleLabel, isNull);
    });

    testWidgets('Italian keeps the invariant loanword', (tester) async {
      final alex = _competitor('Alex', legsWon: 2);
      final gs = _gameState(
        gameType: GameType.x01,
        legsToWin: 3,
        competitors: [alex],
      );
      String? label;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              label = legsWonLabel(context, gs, alex);
              return const SizedBox.shrink();
            },
          ),
          locale: const Locale('it'),
        ),
      );
      expect(label, 'LEG 2');
    });
  });

  group('X01 player cards', () {
    testWidgets('show each player\'s legs won in a best-of match', (
      tester,
    ) async {
      final controller = _flashController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          PlayerScoreSectionWidget(
            gameState: _gameState(
              gameType: GameType.x01,
              legsToWin: 2,
              competitors: [
                _competitor('Sam', legsWon: 1, score: 501),
                _competitor('Alex', legsWon: 0, score: 501),
              ],
            ),
            bustFlashAnim: controller,
          ),
        ),
      );
      expect(find.text('LEGS 1'), findsOneWidget);
      expect(find.text('LEGS 0'), findsOneWidget);
    });

    testWidgets('hide the readout in a single-leg game', (tester) async {
      final controller = _flashController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          PlayerScoreSectionWidget(
            gameState: _gameState(
              gameType: GameType.x01,
              legsToWin: 1,
              competitors: [
                _competitor('Sam', score: 501),
                _competitor('Alex', score: 501),
              ],
            ),
            bustFlashAnim: controller,
          ),
        ),
      );
      expect(find.textContaining('LEGS'), findsNothing);
    });
  });

  group('Cricket table header', () {
    testWidgets('shows each player\'s legs won in a best-of match', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CricketUnifiedTableWidget(
            gameState: _gameState(
              gameType: GameType.cricket,
              legsToWin: 2,
              competitors: [
                _competitor('Sam', legsWon: 1),
                _competitor('Alex', legsWon: 1),
              ],
            ),
            onMiss: () {},
            onSegmentTapped: (_) {},
          ),
        ),
      );
      expect(find.text('LEGS 1'), findsNWidgets(2));
    });

    testWidgets('hides the readout in a single-leg game', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CricketUnifiedTableWidget(
            gameState: _gameState(
              gameType: GameType.cricket,
              legsToWin: 1,
              competitors: [_competitor('Sam'), _competitor('Alex')],
            ),
            onMiss: () {},
            onSegmentTapped: (_) {},
          ),
        ),
      );
      expect(find.textContaining('LEGS'), findsNothing);
    });
  });

  group('camera-first strips', () {
    testWidgets('X01 other-players strip shows the readout when given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const X01OtherPlayersStripWidget(
            players: [
              (name: 'Alex', score: 280, ppr: '50.1', legs: 'LEGS 1'),
              (name: 'Kim', score: 301, ppr: '40.0', legs: null),
            ],
          ),
        ),
      );
      expect(find.text('LEGS 1'), findsOneWidget);
      expect(find.textContaining('LEGS'), findsOneWidget);
    });

    testWidgets('Cricket marks strip shows the readout when given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CricketMarksStripWidget(
            targets: [20, 19, 18, 17, 16, 15, 25],
            rows: [
              (
                name: 'Sam',
                marks: [0, 0, 0, 0, 0, 0, 0],
                score: 0,
                isActive: true,
                mpr: '0',
                legs: 'LEGS 1',
              ),
              (
                name: 'Alex',
                marks: [0, 0, 0, 0, 0, 0, 0],
                score: 0,
                isActive: false,
                mpr: '0',
                legs: null,
              ),
            ],
          ),
        ),
      );
      expect(find.text('LEGS 1'), findsOneWidget);
      expect(find.textContaining('LEGS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
