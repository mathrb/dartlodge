import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_camera_bar.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/contribution_counter_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> tapped;

  setUp(() => tapped = []);

  Future<void> pump(
    WidgetTester tester, {
    TrackerPhase phase = TrackerPhase.tracking,
    bool everCalibrated = true,
    int contributions = 0,
    bool showContributions = true,
  }) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: AutoScorerCameraBar(
          status: TrackerStatus(
              phase: phase, dartsOnBoard: 0, dartsThisTurn: 0),
          everCalibrated: everCalibrated,
          contributions: contributions,
          showContributions: showContributions,
          onReAim: () => tapped.add('re-aim'),
          onRemoveDarts: () => tapped.add('remove'),
          onStop: () => tapped.add('stop'),
        ),
      ),
    ));
  }

  group('the rare actions carry words, not just icons (#761)', () {
    testWidgets('they are behind one menu, none of them loose in the row',
        (tester) async {
      await pump(tester);

      // Nothing is reachable until the menu is opened...
      expect(find.text('Re-aim camera'), findsNothing);
      expect(find.text('Remove darts'), findsNothing);
      expect(find.text('Stop auto-scoring'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // ...and then every one of them is spelled out.
      expect(find.text('Re-aim camera'), findsOneWidget);
      expect(find.text('Remove darts'), findsOneWidget);
      expect(find.text('Stop auto-scoring'), findsOneWidget);
    });

    testWidgets('choosing one runs it', (tester) async {
      await pump(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove darts'));
      await tester.pumpAndSettle();

      expect(tapped, ['remove']);
    });
  });

  group('re-aim stays one tap while the board is lost (#761)', () {
    testWidgets('a lost calibration surfaces it beside the status',
        (tester) async {
      await pump(tester,
          phase: TrackerPhase.needsCalibration, everCalibrated: true);

      // Visible without opening anything, and labelled.
      expect(find.widgetWithText(TextButton, 'Re-aim camera'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Re-aim camera'));
      expect(tapped, ['re-aim']);
    });

    testWidgets('learning mode does not surface it — nothing was lost',
        (tester) async {
      // Same phase, but the board was never recognised: that is a valid way to
      // play (#741), not something to recover from.
      await pump(tester,
          phase: TrackerPhase.needsCalibration, everCalibrated: false);

      expect(find.widgetWithText(TextButton, 'Re-aim camera'), findsNothing);
    });

    testWidgets('an ordinary running state does not surface it',
        (tester) async {
      await pump(tester);
      expect(find.widgetWithText(TextButton, 'Re-aim camera'), findsNothing);
    });
  });

  group('the contribution counter appears with the first capture (#761)', () {
    testWidgets('zero captures shows nothing', (tester) async {
      // A working camera scores on its own and captures nothing, so a counter
      // stuck at zero all game reads as a broken feature.
      await pump(tester, contributions: 0);
      expect(find.byType(ContributionCounter), findsNothing);
    });

    testWidgets('the first capture brings it in', (tester) async {
      await pump(tester, contributions: 1);
      expect(find.byType(ContributionCounter), findsOneWidget);
    });

    testWidgets('recording off keeps it away whatever the count',
        (tester) async {
      await pump(tester, contributions: 3, showContributions: false);
      expect(find.byType(ContributionCounter), findsNothing);
    });
  });
}
