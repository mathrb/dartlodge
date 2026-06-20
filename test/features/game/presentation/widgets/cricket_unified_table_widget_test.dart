// Regression test for #320: Random and Crazy Cricket MPR was always 0
// because the widget's MPR calc passed no `targets` override to
// `cricketMarksForSegment`, which then fell back to the fixed 15–20 set.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_unified_table_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

CompetitorState _competitor({
  required String name,
  List<String> dartThrows = const [],
}) =>
    CompetitorState(
      competitorId: 'c-$name',
      name: name,
      playerIds: const ['p1'],
      score: 0,
      dartThrows: dartThrows,
      startingScore: 0,
    );

GameState _gameState({
  required List<int> targets,
  required String mode,
  required CompetitorState competitor,
}) =>
    GameState(
      gameId: 'g1',
      gameType: GameType.cricket,
      competitors: [competitor],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      cricketTargets: targets,
      cricketTargetMode: mode,
      cricketScoring: 'standard',
    );

void main() {
  group('CricketUnifiedTableWidget — MPR honours active targets (#320)', () {
    testWidgets(
        'Random Cricket: triples on the assigned non-15-20 targets count toward MPR',
        (tester) async {
      // Random targets = {1, 7, 11} (none in the fixed 15–20 set). T11+T7+T5
      // would give the player 3 marks on T11 (covered), 3 marks on T7
      // (covered), 0 on T5 (not a target). Pre-fix the default fixed set
      // caused all three to score 0. Post-fix: 6 marks across 1 round → MPR
      // = 6.0.
      final comp = _competitor(name: 'Alice', dartThrows: const [
        'T11',
        'T7',
        'T5',
      ]);
      final gs = _gameState(
        targets: const [1, 7, 11],
        mode: 'random',
        competitor: comp,
      );

      await tester.pumpWidget(_wrap(CricketUnifiedTableWidget(
        gameState: gs,
        onMiss: () {},
        onSegmentTapped: (_) {},
      )));

      // StatFormatter.fmtDouble strips trailing zeros, so 6.0 → '6'.
      expect(find.text('6'), findsOneWidget,
          reason: 'MPR should be 6 (6 marks / 1 round)');
    });

    testWidgets('Random Cricket: Bull hits always count regardless of targets',
        (tester) async {
      // Bull (25) is the implicit always-on target. Even if the assigned set
      // omits 25, DB scores 2 marks and SB scores 1.
      final comp = _competitor(name: 'Bob', dartThrows: const [
        'DB',
        'SB',
        'MISS',
      ]);
      final gs = _gameState(
        targets: const [1, 7, 11],
        mode: 'random',
        competitor: comp,
      );

      await tester.pumpWidget(_wrap(CricketUnifiedTableWidget(
        gameState: gs,
        onMiss: () {},
        onSegmentTapped: (_) {},
      )));

      // DB(2) + SB(1) + MISS(0) = 3 marks / 1 round → MPR = 3.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Fixed Cricket: standard 15–20 hits still count', (tester) async {
      // Regression sanity check: passing the fixed list should NOT regress.
      final comp = _competitor(name: 'Carol', dartThrows: const [
        'T20',
        'T19',
        'T15',
      ]);
      final gs = _gameState(
        targets: const [15, 16, 17, 18, 19, 20],
        mode: 'fixed',
        competitor: comp,
      );

      await tester.pumpWidget(_wrap(CricketUnifiedTableWidget(
        gameState: gs,
        onMiss: () {},
        onSegmentTapped: (_) {},
      )));

      // T20(3) + T19(3) + T15(3) = 9 marks / 1 round → MPR = 9.
      expect(find.text('9'), findsOneWidget);
    });
  });

  group('CricketUnifiedTableWidget — closed-row input gate (#590)', () {
    // A competitor who has closed 20 (3 marks) so row 20 reads as closed.
    GameState closedTwentyState() => GameState(
          gameId: 'g1',
          gameType: GameType.cricket,
          competitors: const [
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
          cricketTargets: const [15, 16, 17, 18, 19, 20],
          cricketTargetMode: 'fixed',
          cricketScoring: 'standard',
        );

    // The single-20 input cell's InkWell, located via its Semantics label.
    Finder singleTwentyCell() => find.descendant(
          of: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == 'Single 20'),
          matching: find.byType(InkWell),
        );

    testWidgets('live input (default): a closed row is NOT tappable',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(_wrap(CricketUnifiedTableWidget(
        gameState: closedTwentyState(),
        onMiss: () {},
        onSegmentTapped: tapped.add,
      )));

      await tester.tap(singleTwentyCell());
      await tester.pump();

      expect(tapped, isEmpty,
          reason: 'closed-row cells stay non-tappable during live input');
    });

    testWidgets('correction (allowClosedRows): a closed row IS tappable',
        (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(_wrap(CricketUnifiedTableWidget(
        gameState: closedTwentyState(),
        allowClosedRows: true,
        onMiss: () {},
        onSegmentTapped: tapped.add,
      )));

      await tester.tap(singleTwentyCell());
      await tester.pump();

      expect(tapped, ['20'],
          reason: 'a dart that closed 20 must be re-targetable in correction');
    });
  });
}
