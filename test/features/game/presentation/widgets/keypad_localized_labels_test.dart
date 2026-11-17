// The scoring keypads' screen-reader labels (and the few visible segment
// words: the Bob's 27 bar, the simplified keypad's Double/Triple toggles)
// come from the ARB files, so a French or Italian board no longer announces
// "Single 20" / "Miss" in English. English stays byte-identical: the e2e
// suite selects keys by these names ("Triple 20 20", "Miss MISS").

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_unified_table_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_input_buttons_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/simplified_dart_input_grid_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

Widget _wrap(Widget child, Locale locale) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

/// Every semantics label in the tree, merged-node text included.
List<String> _labels(WidgetTester tester) {
  final labels = <String>[];
  void visit(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return labels;
}

bool _hasLabelStartingWith(WidgetTester tester, String prefix) =>
    _labels(tester).any((l) => l.startsWith(prefix));

GameState _cricketState() => const GameState(
      gameId: 'g1',
      gameType: GameType.cricket,
      competitors: [
        CompetitorState(
          competitorId: 'c1',
          name: 'Sam',
          playerIds: ['p1'],
          score: 0,
          startingScore: 0,
        ),
      ],
      currentTurnIndex: 0,
      dartsThrownInTurn: 0,
      isComplete: false,
      cricketTargets: [15, 16, 17, 18, 19, 20],
      cricketTargetMode: 'fixed',
      cricketScoring: 'standard',
    );

void main() {
  group('DartInputGridWidget semantic labels', () {
    testWidgets('French board announces French segment names', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(
          DartInputGridWidget(onSegmentTapped: (_) {}), const Locale('fr')));

      for (final prefix in [
        'Simple 20',
        'Double 20',
        'Triple 20',
        'Miss',
        'Outer bull',
        'Double bull',
      ]) {
        expect(_hasLabelStartingWith(tester, prefix), isTrue,
            reason: 'missing "$prefix" in ${_labels(tester)}');
      }
      expect(_hasLabelStartingWith(tester, 'Single'), isFalse);
      handle.dispose();
    });

    testWidgets('English labels are unchanged (e2e selectors)',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(
          DartInputGridWidget(onSegmentTapped: (_) {}), const Locale('en')));

      expect(find.bySemanticsLabel(RegExp(r'^Single 20\b')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Double 20\b')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Triple 20\b')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Miss\b')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Single Bull\b')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Double Bull\b')), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('Cricket input cells announce Italian segment names',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(
      CricketUnifiedTableWidget(
        gameState: _cricketState(),
        onMiss: () {},
        onSegmentTapped: (_) {},
      ),
      const Locale('it'),
    ));

    for (final prefix in [
      'Singolo 20',
      'Doppio 20',
      'Triplo 20',
      'Outer bull',
      'Doppio bull',
    ]) {
      expect(_hasLabelStartingWith(tester, prefix), isTrue,
          reason: 'missing "$prefix" in ${_labels(tester)}');
    }
    expect(_hasLabelStartingWith(tester, 'Single'), isFalse);
    expect(_hasLabelStartingWith(tester, 'Triple'), isFalse);
    handle.dispose();
  });

  group("Bob's 27 bar", () {
    testWidgets('shows the round double in the board language',
        (tester) async {
      await tester.pumpWidget(_wrap(
        PracticeInputButtonsWidget(
          gameType: GameType.bobs27,
          currentTarget: 5,
          enabled: true,
          onDartThrown: (_) {},
        ),
        const Locale('it'),
      ));
      expect(find.text('Doppio 5'), findsOneWidget);
      expect(find.text('Double 5'), findsNothing);
    });

    testWidgets('bull round reads Doppio bull in Italian', (tester) async {
      await tester.pumpWidget(_wrap(
        PracticeInputButtonsWidget(
          gameType: GameType.bobs27,
          currentTarget: 25,
          enabled: true,
          onDartThrown: (_) {},
        ),
        const Locale('it'),
      ));
      expect(find.text('Doppio bull'), findsOneWidget);
    });

    testWidgets('English stays "Double 5" / "Double Bull"', (tester) async {
      await tester.pumpWidget(_wrap(
        PracticeInputButtonsWidget(
          gameType: GameType.bobs27,
          currentTarget: 25,
          enabled: true,
          onDartThrown: (_) {},
        ),
        const Locale('en'),
      ));
      expect(find.text('Double Bull'), findsOneWidget);
    });
  });

  testWidgets('Simplified keypad toggles and labels follow the locale',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(
      SimplifiedDartInputGridWidget(onSegmentTapped: (_) {}),
      const Locale('nl'),
    ));

    expect(find.text('DUBBEL'), findsOneWidget);
    expect(find.text('TRIPLE'), findsOneWidget);
    expect(_hasLabelStartingWith(tester, 'Misser'), isTrue,
        reason: '${_labels(tester)}');
    expect(_hasLabelStartingWith(tester, 'Miss '), isFalse);
    handle.dispose();
  });
}
