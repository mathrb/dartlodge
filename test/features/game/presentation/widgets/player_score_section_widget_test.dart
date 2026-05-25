// Regression tests for #246: the live PPR display sums actual dart
// values rather than deriving points from the starting score, so an
// X01 handicap can no longer be credited as "points scored". The
// invariant under test is "PPR depends only on dartThrows" — proven by
// varying the competitor's starting score and current score across
// each test case and asserting the PPR value never moves.

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

// Reads the rendered PPR value by scoping into the column that holds
// the 'PPR' label. Avoids collisions with the active card's round-sum
// chip, which can independently render the same numeric literal.
String _readPpr(WidgetTester tester) {
  final pprLabel = find.text('PPR');
  expect(pprLabel, findsOneWidget);
  final column =
      find.ancestor(of: pprLabel, matching: find.byType(Column)).first;
  final texts = tester
      .widgetList<Text>(find.descendant(of: column, matching: find.byType(Text)))
      .toList();
  // The column has exactly two Text children: [0] is the 'PPR' label,
  // [1] is the value.
  expect(texts.length, 2);
  return texts[1].data!;
}

Future<String> _pumpAndReadPpr(
  WidgetTester tester, {
  required GameType gameType,
  required int competitorStartingScore,
  required int competitorScore,
  required List<String> dartThrows,
}) async {
  final state = _gameStateWith(
    gameType: gameType,
    competitorStartingScore: competitorStartingScore,
    competitorScore: competitorScore,
    dartThrows: dartThrows,
  );
  final controller = _flashController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(_wrap(PlayerScoreSectionWidget(
    gameState: state,
    bustFlashAnim: controller,
  )));
  return _readPpr(tester);
}

// Per-case starting-score / current-score variations exercised by the
// invariant tests. Each pair represents a different X01 setup that
// would have produced a different (wrong) value under the old
// `startingScore - cs.score` formula — proving PPR no longer leaks
// through that axis.
const _x01ScoreVariations = <(int, int)>[
  (251, 251), // -50 handicap on 301, no points scored yet
  (301, 301), // 301 with no handicap, no points scored yet
  (326, 326), // +25 handicap on 301
  (501, 461), // 501 game mid-leg
];

void main() {
  testWidgets(
    'X01 PPR for 3 missed darts is always 0, regardless of starting score (#246)',
    (tester) async {
      for (final (start, score) in _x01ScoreVariations) {
        final ppr = await _pumpAndReadPpr(
          tester,
          gameType: GameType.x01,
          competitorStartingScore: start,
          competitorScore: score,
          dartThrows: const ['MISS', 'MISS', 'MISS'],
        );
        expect(ppr, '0',
            reason: 'starting=$start score=$score should give PPR 0');
      }
    },
  );

  testWidgets(
    'X01 PPR for T20 + 2 misses is always 60, regardless of starting score',
    (tester) async {
      for (final (start, score) in _x01ScoreVariations) {
        final ppr = await _pumpAndReadPpr(
          tester,
          gameType: GameType.x01,
          competitorStartingScore: start,
          competitorScore: score,
          dartThrows: const ['T20', 'MISS', 'MISS'],
        );
        expect(ppr, '60',
            reason: 'starting=$start score=$score should give PPR 60');
      }
    },
  );

  testWidgets(
    'Count-Up PPR is also derived from dart values (no handicap leak)',
    (tester) async {
      final ppr = await _pumpAndReadPpr(
        tester,
        gameType: GameType.countUp,
        competitorStartingScore: 50, // +50 handicap
        competitorScore: 50,
        dartThrows: const ['MISS', 'MISS', 'MISS'],
      );
      expect(ppr, '0');
    },
  );

  testWidgets(
    'PPR shows the em dash placeholder before three darts have been thrown',
    (tester) async {
      final ppr = await _pumpAndReadPpr(
        tester,
        gameType: GameType.x01,
        competitorStartingScore: 301,
        competitorScore: 261,
        dartThrows: const ['T20'],
      );
      expect(ppr, '—');
    },
  );
}
