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
        (name: 'Bob', score: 280),
        (name: 'Carol', score: 412),
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
}
