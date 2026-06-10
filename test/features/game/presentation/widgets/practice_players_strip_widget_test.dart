// #445 — the camera-first Practice layout shows the active player's target as
// the hero metric and the other players' progress in this compact strip
// (multi-player ATC / Shanghai).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/practice_players_strip_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders each player name (uppercased) and value', (tester) async {
    await tester.pumpWidget(_wrap(const PracticePlayersStripWidget(
      players: [
        (name: 'Bob', value: 7),
        (name: 'Carol', value: 12),
      ],
    )));

    expect(find.text('BOB'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('CAROL'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('renders nothing when the player list is empty', (tester) async {
    await tester.pumpWidget(_wrap(const PracticePlayersStripWidget(
      players: [],
    )));

    expect(find.byType(Text), findsNothing);
  });
}
