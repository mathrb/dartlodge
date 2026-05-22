// Regression test for #261: the Checkout Practice engine pads
// bust/checkout turns to 3 dart slots (so `dartThrows.length` stays
// aligned with `dartsThrownInTurn`). Those slots used to be 'MISS'
// strings and showed up in the status bar as MISS chips the user
// never threw. They're now empty-string sentinels — the status bar
// must render them as the "dart not thrown" placeholder icon.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/game_status_bar_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
      'empty-slot sentinels render as "dart not thrown" placeholders (#261)',
      (tester) async {
    await tester.pumpWidget(_wrap(const GameStatusBarWidget(
      configLabel: '170',
      roundInLeg: 1,
      currentTurnDarts: ['T20', '', ''],
    )));

    // The lone real dart 'T20' renders as text inside a chip.
    expect(find.text('T20'), findsOneWidget);
    // No phantom MISS chips for the two padded slots.
    expect(find.text('MISS'), findsNothing);
    // Two "dart not thrown" placeholders for the two empty slots.
    expect(
      find.bySemanticsLabel('dart not thrown'),
      findsNWidgets(2),
    );
  });

  testWidgets('empty-slot sentinels do not contribute to the turn sum',
      (tester) async {
    await tester.pumpWidget(_wrap(const GameStatusBarWidget(
      configLabel: '170',
      roundInLeg: 1,
      currentTurnDarts: ['T20', '', ''],
    )));

    // Turn sum = 60 (T20), not 60 + parse('') noise.
    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('a real MISS still renders as a MISS chip', (tester) async {
    await tester.pumpWidget(_wrap(const GameStatusBarWidget(
      configLabel: '170',
      roundInLeg: 1,
      currentTurnDarts: ['T20', 'MISS', 'MISS'],
    )));

    expect(find.text('T20'), findsOneWidget);
    // Real MISS chips render their label.
    expect(find.text('MISS'), findsNWidgets(2));
  });
}
