// #441 — the prominent dart band is the large, at-distance-readable version of
// the 3-dart turn indicator used in auto-scoring mode. It shares the API trio
// (currentTurnDarts / onDartTapped / tapEmptySlots) and the semantics labels
// ('enter dart' / 'dart not thrown') with GameStatusBarWidget so the boards can
// compose it without per-game branching.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/prominent_dart_band_widget.dart';
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
  testWidgets('thrown darts render their segment labels', (tester) async {
    await tester.pumpWidget(_wrap(const ProminentDartBandWidget(
      currentTurnDarts: ['T20', 'D20', 'SB'],
    )));

    expect(find.text('T20'), findsOneWidget);
    expect(find.text('D20'), findsOneWidget);
    expect(find.text('SB'), findsOneWidget);
  });

  testWidgets('slots render at the at-distance height (#478)', (tester) async {
    await tester.pumpWidget(_wrap(const ProminentDartBandWidget(
      currentTurnDarts: ['T20', '', ''],
    )));

    // 110 px per the distance-readability design (2026-06-12) — readable from
    // the oche (~2.4 m) in camera-first mode.
    final slot = tester.getSize(
      find.ancestor(of: find.text('T20'), matching: find.byType(Container)).first,
    );
    expect(slot.height, 110);
  });

  testWidgets('empty-slot sentinels render as "dart not thrown" placeholders',
      (tester) async {
    await tester.pumpWidget(_wrap(const ProminentDartBandWidget(
      currentTurnDarts: ['T20', '', ''],
    )));

    expect(find.text('T20'), findsOneWidget);
    // No phantom MISS chips for the two padded slots (#261).
    expect(find.text('MISS'), findsNothing);
    expect(find.bySemanticsLabel('dart not thrown'), findsNWidgets(2));
  });

  testWidgets('a real MISS still renders as a MISS badge', (tester) async {
    await tester.pumpWidget(_wrap(const ProminentDartBandWidget(
      currentTurnDarts: ['T20', 'MISS', 'MISS'],
    )));

    expect(find.text('T20'), findsOneWidget);
    expect(find.text('MISS'), findsNWidgets(2));
  });

  testWidgets('tapping a thrown dart reports its index', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(_wrap(ProminentDartBandWidget(
      currentTurnDarts: const ['T20', 'D20', '20'],
      onDartTapped: tapped.add,
    )));

    await tester.tap(find.text('D20'));
    expect(tapped, [1]);
  });

  testWidgets(
      'camera-first: empty slots are tappable and report their index',
      (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(_wrap(ProminentDartBandWidget(
      currentTurnDarts: const ['T20', '', ''],
      tapEmptySlots: true,
      onDartTapped: tapped.add,
    )));

    // Empty slots expose the "enter dart" affordance, not the inert placeholder.
    expect(find.bySemanticsLabel('enter dart'), findsNWidgets(2));
    expect(find.bySemanticsLabel('dart not thrown'), findsNothing);

    // Tapping the first empty slot (index 1) reports that index.
    await tester.tap(find.bySemanticsLabel('enter dart').first);
    expect(tapped, [1]);

    // The thrown dart stays tappable for correction.
    await tester.tap(find.text('T20'));
    expect(tapped, [1, 0]);
  });

  testWidgets('without tapEmptySlots, empty slots stay inert placeholders',
      (tester) async {
    await tester.pumpWidget(_wrap(ProminentDartBandWidget(
      currentTurnDarts: const ['T20', '', ''],
      onDartTapped: (_) {},
    )));

    expect(find.bySemanticsLabel('dart not thrown'), findsNWidgets(2));
    expect(find.bySemanticsLabel('enter dart'), findsNothing);
  });

  testWidgets('with onDartTapped null, a thrown dart is not tappable',
      (tester) async {
    // No callback wired → no InkWell wraps the badge, so no gesture is dispatched.
    await tester.pumpWidget(_wrap(const ProminentDartBandWidget(
      currentTurnDarts: ['T20', '', ''],
    )));

    expect(find.widgetWithText(InkWell, 'T20'), findsNothing);
  });
}
