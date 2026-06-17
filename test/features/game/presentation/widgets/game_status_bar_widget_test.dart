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
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
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

  testWidgets(
      'camera-first: empty slots are tappable and report their index (#427)',
      (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(_wrap(GameStatusBarWidget(
      configLabel: '170',
      roundInLeg: 1,
      currentTurnDarts: const ['T20', '', ''],
      tapEmptySlots: true,
      onDartTapped: tapped.add,
    )));

    // Empty slots render the "enter dart" affordance instead of the inert
    // "dart not thrown" placeholder.
    expect(find.bySemanticsLabel('enter dart'), findsNWidgets(2));
    expect(find.bySemanticsLabel('dart not thrown'), findsNothing);

    // Tapping the first empty slot (index 1) reports that index.
    await tester.tap(find.bySemanticsLabel('enter dart').first);
    expect(tapped, [1]);

    // The thrown dart is still tappable for correction.
    await tester.tap(find.text('T20'));
    expect(tapped, [1, 0]);
  });

  testWidgets('without tapEmptySlots, empty slots stay inert placeholders',
      (tester) async {
    await tester.pumpWidget(_wrap(GameStatusBarWidget(
      configLabel: '170',
      roundInLeg: 1,
      currentTurnDarts: const ['T20', '', ''],
      onDartTapped: (_) {},
    )));

    expect(find.bySemanticsLabel('dart not thrown'), findsNWidgets(2));
    expect(find.bySemanticsLabel('enter dart'), findsNothing);
  });

  testWidgets('showDarts:false hides the darts/turn-sum, keeps the metadata',
      (tester) async {
    await tester.pumpWidget(_wrap(const GameStatusBarWidget(
      configLabel: '501',
      roundInLeg: 3,
      currentTurnDarts: ['T20', 'T20', '20'],
      showDarts: false,
    )));

    // Metadata still present.
    expect(find.text('501'), findsOneWidget);
    expect(find.text('ROUND 3'), findsOneWidget);
    // Darts, placeholders and the turn-sum cluster are gone.
    expect(find.text('T20'), findsNothing);
    expect(find.bySemanticsLabel('dart not thrown'), findsNothing);
    expect(find.text('100'), findsNothing); // turn sum (T20+T20+20)
  });
}
