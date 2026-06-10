// #444 — the camera-first Cricket layout replaces the full marks table with the
// camera, so this compact strip keeps every player's marks + score visible.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_marks_strip_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

const _targets = [20, 19, 18, 17, 16, 15, 25];

void main() {
  testWidgets('renders target headers including Bull as "B"', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (name: 'Alice', marks: [0, 0, 0, 0, 0, 0, 0], score: 0, isActive: true),
      ],
    )));

    expect(find.text('20'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('B'), findsOneWidget); // Bull column header
  });

  testWidgets('maps mark counts to glyphs (1 / 2 X 3 closed)', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (
          name: 'Alice',
          marks: [1, 2, 3, 0, 0, 0, 0],
          score: 41,
          isActive: true,
        ),
      ],
    )));

    expect(find.text('/'), findsOneWidget); // 1 mark
    expect(find.text('X'), findsOneWidget); // 2 marks
    expect(find.text('⊗'), findsOneWidget); // 3 marks (closed)
    expect(find.text('·'), findsNWidgets(4)); // four unmarked targets
  });

  testWidgets('renders each player name (uppercased) and score', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (name: 'Alice', marks: [0, 0, 0, 0, 0, 0, 0], score: 41, isActive: true),
        (name: 'Bob', marks: [0, 0, 0, 0, 0, 0, 0], score: 88, isActive: false),
      ],
    )));

    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('SC'), findsOneWidget); // score header
  });

  testWidgets('showScore:false hides the score column', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      showScore: false,
      rows: [
        (name: 'Alice', marks: [0, 0, 0, 0, 0, 0, 0], score: 41, isActive: true),
      ],
    )));

    expect(find.text('SC'), findsNothing);
    expect(find.text('41'), findsNothing);
  });

  testWidgets('renders nothing when there are no rows', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [],
    )));

    expect(find.byType(Text), findsNothing);
  });
}
