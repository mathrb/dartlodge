// #444 — the camera-first Cricket layout replaces the full marks table with the
// camera, so this strip keeps every player's marks + score visible. Since #479
// it is the at-distance version: marks are painted glyphs (CricketMarkPainter),
// so tests find cells via their Semantics labels, not text glyphs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_mark_painter.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_marks_strip_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

const _targets = [20, 19, 18, 17, 16, 15, 25];

/// The strip's mark painters, keyed by what they render.
Iterable<CricketMarkPainter> _markPainters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<CricketMarkPainter>();

void main() {
  testWidgets('renders target headers including Bull as "B"', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (name: 'Alice', marks: [0, 0, 0, 0, 0, 0, 0], score: 0, isActive: true, mpr: '0'),
      ],
    )));

    expect(find.text('20'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('B'), findsOneWidget); // Bull column header
  });

  testWidgets('maps mark counts to semantics (1 mark / 2 marks / closed)',
      (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (
          name: 'Alice',
          marks: [1, 2, 3, 0, 0, 0, 0],
          score: 41,
          isActive: true,
          mpr: '0',
        ),
      ],
    )));

    expect(find.bySemanticsLabel('1 mark'), findsOneWidget);
    expect(find.bySemanticsLabel('2 marks'), findsOneWidget);
    expect(find.bySemanticsLabel('closed'), findsOneWidget);
    expect(find.bySemanticsLabel('no marks'), findsNWidgets(4));
  });

  testWidgets('marks are painted with the at-distance stroke weight',
      (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (name: 'Alice', marks: [3, 1, 0, 0, 0, 0, 0], score: 0, isActive: true, mpr: '0'),
      ],
    )));

    final painters = _markPainters(tester).toList();
    expect(painters, hasLength(7)); // one glyph per target
    expect(painters.every((p) => p.strokeWidth == 4), isTrue);
    expect(painters.every((p) => p.zeroAsDot), isTrue);
  });

  testWidgets(
      'dead target (closed by all players) strikes its header and greys marks',
      (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        // 20 closed by BOTH (dead); 19 closed by Alice only (live closed).
        (name: 'Alice', marks: [3, 3, 0, 0, 0, 0, 0], score: 0, isActive: true, mpr: '0'),
        (name: 'Bob', marks: [3, 0, 0, 0, 0, 0, 0], score: 0, isActive: false, mpr: '0'),
      ],
    )));

    // The 20 column is dead → struck-through header.
    final dead = tester.widget<Text>(find.text('20'));
    expect(dead.style?.decoration, TextDecoration.lineThrough);
    // 19 is closed by Alice only → still in play, no strike.
    final alive = tester.widget<Text>(find.text('19'));
    expect(alive.style?.decoration, isNull);

    // Three closed glyphs: two dead (20 column) + one live (Alice's 19).
    // The dead pair shares one greyed colour, DISTINCT from the live closed
    // mark's primaryFixed — this is what proves the dead-guard in markColor.
    final closed = _markPainters(tester).where((p) => p.marks >= 3).toList();
    expect(closed, hasLength(3));
    final colours = closed.map((p) => p.color).toSet();
    expect(colours, hasLength(2),
        reason: 'dead marks must be greyed, not live-closed primaryFixed');
  });

  testWidgets('renders each player name (uppercased) and score', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (name: 'Alice', marks: [0, 0, 0, 0, 0, 0, 0], score: 41, isActive: true, mpr: '0'),
        (name: 'Bob', marks: [0, 0, 0, 0, 0, 0, 0], score: 88, isActive: false, mpr: '0'),
      ],
    )));

    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('41'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('SC'), findsOneWidget); // score header
  });

  testWidgets('rows compress beyond 2 players', (tester) async {
    const row = (
      name: 'P',
      marks: [0, 0, 0, 0, 0, 0, 0],
      score: 0,
      isActive: false,
      mpr: '0',
    );
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [row, row],
    )));
    final tall =
        tester.getSize(find.bySemanticsLabel('no marks').first).height;

    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [row, row, row],
    )));
    final short =
        tester.getSize(find.bySemanticsLabel('no marks').first).height;

    expect(tall, greaterThan(short));
  });

  testWidgets('showScore:false hides the score column', (tester) async {
    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      showScore: false,
      rows: [
        (name: 'Alice', marks: [0, 0, 0, 0, 0, 0, 0], score: 41, isActive: true, mpr: '0'),
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

  testWidgets('fits a narrow 360 dp screen without horizontal scroll',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const CricketMarksStripWidget(
      targets: _targets,
      rows: [
        (name: 'Annabelle', marks: [3, 2, 1, 0, 0, 0, 0], score: 120, isActive: true, mpr: '0'),
        (name: 'Bob', marks: [1, 0, 0, 0, 0, 0, 0], score: 85, isActive: false, mpr: '0'),
      ],
    )));

    // Flex-derived columns: no SingleChildScrollView, no overflow errors.
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
