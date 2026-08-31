import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_status_chip.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Status labels are localized; resolve against the English bundle.
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  ({String label, IconData icon}) describe(TrackerPhase phase,
          {int onBoard = 0, bool everCalibrated = true}) =>
      AutoScorerStatusChip.describe(
          l10n,
          TrackerStatus(
              phase: phase, dartsOnBoard: onBoard, dartsThisTurn: 0),
          everCalibrated: everCalibrated);

  /// Pumps the chip and returns the background colour the Chip resolved to.
  Future<Color?> chipBackground(WidgetTester tester, TrackerPhase phase,
      {required bool everCalibrated}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: AutoScorerStatusChip(
          status: TrackerStatus(
              phase: phase, dartsOnBoard: 0, dartsThisTurn: 0),
          everCalibrated: everCalibrated,
        ),
      ),
    ));
    return tester.widget<Chip>(find.byType(Chip)).backgroundColor;
  }

  test('maps each phase to a label', () {
    expect(describe(TrackerPhase.noCalibration).label, 'Aim at the board');
    expect(describe(TrackerPhase.needsCalibration).label,
        'Calibration lost');
    expect(describe(TrackerPhase.idle).label, 'Ready');
    expect(describe(TrackerPhase.turnFull).label, 'Turn full');
    expect(describe(TrackerPhase.cameraMoved).label, 'Camera moved');
    expect(describe(TrackerPhase.rebaselined).label, 'Board cleared');
  });

  test('tracking label pluralises the dart count', () {
    expect(describe(TrackerPhase.tracking, onBoard: 1).label, '1 dart detected');
    expect(describe(TrackerPhase.tracking, onBoard: 3).label, '3 darts detected');
  });

  test('a never-calibrated session reads as a mode, not a fault (#741)', () {
    expect(
        describe(TrackerPhase.needsCalibration, everCalibrated: false).label,
        'Learning mode');
    // Same phase, but the board HAD been recognised: that is a real loss.
    expect(describe(TrackerPhase.needsCalibration, everCalibrated: true).label,
        'Calibration lost');
  });

  testWidgets('learning mode never renders errorContainer (#741)',
      (tester) async {
    final learning = await chipBackground(
        tester, TrackerPhase.needsCalibration,
        everCalibrated: false);
    final lost = await chipBackground(tester, TrackerPhase.needsCalibration,
        everCalibrated: true);
    final normal = await chipBackground(tester, TrackerPhase.idle,
        everCalibrated: true);

    final scheme = ThemeData().colorScheme;
    expect(lost, isNot(learning));
    // Learning mode shares the calm background of an ordinary status; only the
    // mid-session loss keeps the alert one.
    expect(learning, normal);
    expect(learning, isNot(scheme.errorContainer));
  });

  testWidgets('label uses the at-distance titleMedium size (#480)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: const Scaffold(
        body: AutoScorerStatusChip(
          status: TrackerStatus(
              phase: TrackerPhase.tracking, dartsOnBoard: 2, dartsThisTurn: 2),
          everCalibrated: true,
        ),
      ),
    ));

    final label = tester.widget<Text>(find.text('2 darts detected'));
    // titleMedium = 18px — the chip is the at-distance status/alert line now
    // that the camera preview collapses to a vignette.
    expect(label.style?.fontSize, 18);
  });

  testWidgets(
      'a label too long for the row is scaled down, never clipped (#764)',
      (tester) async {
    // Dutch has the longest calibration label of the seven locales, and the
    // chip only ever gets part of the camera bar: the rest goes to the
    // contribution counter and the camera actions.
    const available = 180.0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('nl'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: const Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: available,
              child: AutoScorerStatusChip(
                status: TrackerStatus(
                    phase: TrackerPhase.needsCalibration,
                    dartsOnBoard: 0,
                    dartsThisTurn: 0),
                everCalibrated: true,
              ),
            ),
          ],
        ),
      ),
    ));

    const label = 'Kalibratie verloren';
    // Every word survives: an ellipsis would drop the actionable half.
    expect(find.text(label), findsOneWidget);
    // The label really is wider than the room it gets here. `getSize` is the
    // LAYOUT size, which a FittedBox never changes — it lays its child out
    // unconstrained and scales at paint time.
    final natural = tester.getSize(find.text(label)).width;
    final box = tester.getSize(find.byType(FittedBox)).width;
    expect(natural, greaterThan(box));
    // So assert on the PAINTED rect, which carries the transform: that is the
    // only measurement that tells a real scale-down apart from a label left at
    // full size and clipped by the chip — the #764 bug itself.
    final painted = tester.getRect(find.text(label)).width;
    expect(painted, lessThan(natural));
    expect(painted, lessThanOrEqualTo(box));
  });

  testWidgets('a label that fits still renders at the full at-distance size',
      (tester) async {
    // The scale-down is a safety net, not the normal path: #480 wants this
    // chip read from the oche, and the fontSize assertion above only checks
    // the DECLARED style, which a FittedBox does not change. Assert the
    // painted size too, so a label that outgrows the row can never quietly
    // become the norm.
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: const Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 220,
              child: AutoScorerStatusChip(
                status: TrackerStatus(
                    phase: TrackerPhase.turnFull,
                    dartsOnBoard: 3,
                    dartsThisTurn: 3),
                everCalibrated: true,
              ),
            ),
          ],
        ),
      ),
    ));

    final label = find.text('Turn full');
    expect(tester.getRect(label).width, tester.getSize(label).width);
  });
}
