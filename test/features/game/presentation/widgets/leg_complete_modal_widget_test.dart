import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/features/game/presentation/widgets/leg_complete_modal_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  Future<void> openModal(
    WidgetTester tester, {
    required VoidCallback onNextLeg,
    VoidCallback? onUndo,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: kSupportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => LegCompleteModalWidget(
                  winnerName: 'Ann',
                  legNumber: 1,
                  onNextLeg: onNextLeg,
                  onUndo: onUndo,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('offers Undo last dart next to Next Leg', (tester) async {
    var undone = 0;
    var next = 0;
    await openModal(tester, onNextLeg: () => next++, onUndo: () => undone++);

    expect(find.text('Leg 1 won by Ann'), findsOneWidget);
    expect(find.text('Next Leg'), findsOneWidget);

    await tester.tap(find.text('Undo last dart'));
    await tester.pumpAndSettle();

    expect(undone, 1);
    expect(next, 0);
    expect(
      find.text('Leg 1 won by Ann'),
      findsNothing,
      reason: 'the modal closes before the undo runs',
    );
  });

  testWidgets('Next Leg still closes the modal without undoing', (
    tester,
  ) async {
    var undone = 0;
    var next = 0;
    await openModal(tester, onNextLeg: () => next++, onUndo: () => undone++);

    await tester.tap(find.text('Next Leg'));
    await tester.pumpAndSettle();

    expect(next, 1);
    expect(undone, 0);
    expect(find.text('Leg 1 won by Ann'), findsNothing);
  });

  testWidgets('hides the undo action without a callback', (tester) async {
    await openModal(tester, onNextLeg: () {});

    expect(find.text('Undo last dart'), findsNothing);
    expect(find.text('Next Leg'), findsOneWidget);
  });
}
