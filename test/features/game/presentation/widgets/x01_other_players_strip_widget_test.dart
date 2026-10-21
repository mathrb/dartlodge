// #443 — the camera-first X01 layout shows the active player's score as the
// hero metric and the other players' remaining scores in this compact strip.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/x01_other_players_strip_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders each player name (uppercased) and remaining score',
      (tester) async {
    await tester.pumpWidget(_wrap(const X01OtherPlayersStripWidget(
      players: [
        (name: 'Bob', score: 280, ppr: '0'),
        (name: 'Carol', score: 412, ppr: '0'),
      ],
    )));

    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('280'), findsOneWidget);
    expect(find.text('CAROL'), findsOneWidget);
    expect(find.text('412'), findsOneWidget);
  });

  testWidgets('renders nothing when the player list is empty', (tester) async {
    await tester.pumpWidget(_wrap(const X01OtherPlayersStripWidget(
      players: [],
    )));

    expect(find.byType(Text), findsNothing);
  });

  // #801: a second row of chips cost the never-scrolling board ~50dp, and with
  // three players that was what pushed the hero score off screen.
  testWidgets('three opponents share one row on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const X01OtherPlayersStripWidget(
      players: [
        (name: 'Charlie', score: 501, ppr: '58.4'),
        (name: 'Dorothy', score: 501, ppr: '58.4'),
        (name: 'Eleanor', score: 501, ppr: '58.4'),
      ],
    )));

    expect(tester.takeException(), isNull);
    final rows = {
      for (final name in ['CHARLIE', 'DOROTHY', 'ELEANOR'])
        tester.getRect(find.text(name)).center.dy,
    };
    expect(rows, hasLength(1));
    for (final name in ['CHARLIE', 'DOROTHY', 'ELEANOR']) {
      final r = tester.getRect(find.text(name));
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(320));
    }
  });

  testWidgets('four opponents wrap rather than shrink past reading',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568) * 3;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(const X01OtherPlayersStripWidget(
      players: [
        (name: 'Bob', score: 501, ppr: '0'),
        (name: 'Carol', score: 501, ppr: '0'),
        (name: 'Dave', score: 501, ppr: '0'),
        (name: 'Erin', score: 501, ppr: '0'),
      ],
    )));

    expect(tester.takeException(), isNull);
    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.getRect(find.text('ERIN')).top,
        greaterThan(tester.getRect(find.text('BOB')).bottom));
  });
}
