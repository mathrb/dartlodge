// #441 — the prominent dart band is the large, at-distance-readable version of
// the 3-dart turn indicator used in auto-scoring mode. It shares the API trio
// (currentTurnDarts / onDartTapped / tapEmptySlots) and the semantics labels
// ('enter dart' / 'dart not thrown') with GameStatusBarWidget so the boards can
// compose it without per-game branching.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/providers/auto_scorer_providers.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/prominent_dart_band_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

/// The band listens to the `core/` training-capture signal (#762), so it needs
/// a scope; [container] lets a test bump that signal from the outside, the way
/// the auto-scorer does when a frame is stored.
Widget _wrap(Widget child, {ProviderContainer? container}) {
  final app = MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
  return container == null
      ? ProviderScope(child: app)
      : UncontrolledProviderScope(container: container, child: app);
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

  group('training-capture acknowledgement (#762)', () {
    testWidgets('nothing is shown until a frame is actually stored',
        (tester) async {
      await tester.pumpWidget(_wrap(const ProminentDartBandWidget(
        currentTurnDarts: ['T20'],
        tapEmptySlots: true,
      )));
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('+1'), findsNothing);
    });

    testWidgets('the whole band flashes when a frame is stored, then clears',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(_wrap(
        const ProminentDartBandWidget(
          currentTurnDarts: ['T20'],
          tapEmptySlots: true,
        ),
        container: container,
      ));

      container.read(trainingCaptureSignalProvider.notifier).bump();
      await tester.pump();
      // A short pump on purpose: the test binding scales animation durations
      // down, so a fraction of [kContributionBandFlashDuration] would already
      // be over.
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('+1'), findsOneWidget);
      expect(find.bySemanticsLabel('Frame saved for training'), findsOneWidget);

      // It must not sit over the scores: the band comes back on its own.
      await tester.pumpAndSettle();
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('the badge clears the segment labels at a real phone width',
        (tester) async {
      // The band exists to be read from the oche (#478), so an acknowledgement
      // that sits on top of a segment costs more than it gives. Measured, not
      // eyeballed: the first version of this badge cut into the third slot's
      // glyphs at 412dp with a full turn.
      tester.view.physicalSize = const Size(412 * 3, 400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(_wrap(
        const ProminentDartBandWidget(currentTurnDarts: ['T20', 'D20', 'MISS']),
        container: container,
      ));

      container.read(trainingCaptureSignalProvider.notifier).bump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      // The PAINTED rects: a segment is drawn through a FittedBox, so its
      // layout size is not where it ends up on screen.
      final badge = tester.getRect(find.text('+1'));
      for (final segment in ['T20', 'D20', 'MISS']) {
        expect(badge.overlaps(tester.getRect(find.text(segment))), isFalse,
            reason: 'the badge covers $segment');
      }
    });

    testWidgets('the acknowledgement never blocks a tap on the band',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final tapped = <int>[];
      await tester.pumpWidget(_wrap(
        ProminentDartBandWidget(
          currentTurnDarts: const ['T20'],
          tapEmptySlots: true,
          onDartTapped: tapped.add,
        ),
        container: container,
      ));

      container.read(trainingCaptureSignalProvider.notifier).bump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.text('T20'));
      await tester.pumpAndSettle();

      expect(tapped, [0]);
    });
  });
}
