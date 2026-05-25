// Regression tests for #246: the live PPR display sums actual dart
// values rather than deriving points from the starting score, so an
// X01 handicap can no longer be credited as "points scored".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/player_score_section_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

GameState _gameStateWith({
  required GameType gameType,
  required int competitorStartingScore,
  required int competitorScore,
  required List<String> dartThrows,
}) {
  return GameState(
    gameId: 'g1',
    gameType: gameType,
    competitors: [
      CompetitorState(
        competitorId: 'c1',
        name: 'TESTPLAYER',
        playerIds: const ['p1'],
        score: competitorScore,
        startingScore: competitorStartingScore,
        dartThrows: dartThrows,
      ),
    ],
    currentTurnIndex: 0,
    dartsThrownInTurn: dartThrows.length,
    isComplete: false,
    status: GameEngineStatus.inProgress,
    turnActive: true,
    legsToWin: 1,
    currentLegIndex: 0,
    inStrategy: 'straight',
    outStrategy: 'straight',
    startingScore: 301,
    cricketScoring: 'standard',
    cricketTargetMode: 'fixed',
    cricketTargets: const [],
    cricketLockedTargets: const {},
    aroundTheClockVariant: 'standard',
    shanghaiTotalRounds: 7,
    catch40TargetRemaining: 0,
    catch40DartsOnTarget: 0,
  );
}

AnimationController _flashController() => AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 200),
    );

void main() {
  testWidgets(
    'X01 with -50 handicap: 3 missed darts show PPR 0, not 50 (#246)',
    (tester) async {
      final state = _gameStateWith(
        gameType: GameType.x01,
        competitorStartingScore: 251, // 301 + (-50 handicap)
        competitorScore: 251,
        dartThrows: const ['MISS', 'MISS', 'MISS'],
      );
      final controller = _flashController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(PlayerScoreSectionWidget(
        gameState: state,
        bustFlashAnim: controller,
      )));

      expect(find.text('0'), findsWidgets);
      expect(find.text('50'), findsNothing);
    },
  );

  testWidgets(
    'X01 PPR is derived from dart values, ignoring handicapped score delta',
    (tester) async {
      // +25 handicap, then T20 + 2 misses. Score delta would suggest -25
      // "points scored"; the dart sum gives 60 (the truth).
      final state = _gameStateWith(
        gameType: GameType.x01,
        competitorStartingScore: 326,
        competitorScore: 266,
        dartThrows: const ['T20', 'MISS', 'MISS'],
      );
      final controller = _flashController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(PlayerScoreSectionWidget(
        gameState: state,
        bustFlashAnim: controller,
      )));

      expect(find.text('60'), findsWidgets);
    },
  );

  testWidgets(
    'Count-Up PPR is also derived from dart values (no handicap leak)',
    (tester) async {
      final state = _gameStateWith(
        gameType: GameType.countUp,
        competitorStartingScore: 50, // +50 handicap
        competitorScore: 50,
        dartThrows: const ['MISS', 'MISS', 'MISS'],
      );
      final controller = _flashController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(PlayerScoreSectionWidget(
        gameState: state,
        bustFlashAnim: controller,
      )));

      expect(find.text('0'), findsWidgets);
    },
  );

  testWidgets(
    'PPR shows the em dash placeholder before three darts have been thrown',
    (tester) async {
      final state = _gameStateWith(
        gameType: GameType.x01,
        competitorStartingScore: 301,
        competitorScore: 261,
        dartThrows: const ['T20'],
      );
      final controller = _flashController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_wrap(PlayerScoreSectionWidget(
        gameState: state,
        bustFlashAnim: controller,
      )));

      expect(find.text('—'), findsOneWidget);
    },
  );
}
