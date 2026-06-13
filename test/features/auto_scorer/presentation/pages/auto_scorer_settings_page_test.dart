import 'package:dart_lodge/features/auto_scorer/presentation/pages/auto_scorer_settings_page.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The page reads the capture store only on export-tap (not in build), so it
// pumps cleanly against mock SharedPreferences. Covers the #457 capture-mode
// control; the live camera/capture path stays device-only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester) async {
    // Tall viewport so the whole settings list fits without scrolling — the
    // controls below the fold (capture-mode, toggles) stay tappable.
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(home: AutoScorerSettingsPage())));
    await tester.pumpAndSettle();
  }

  SegmentedButton<CaptureMode> modeButton(WidgetTester tester) =>
      tester.widget<SegmentedButton<CaptureMode>>(
          find.byType(SegmentedButton<CaptureMode>));

  testWidgets('capture-mode defaults to All and switches to Mistakes only',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_collect_training_data': true});
    await pump(tester);

    expect(modeButton(tester).selected, {CaptureMode.all});
    expect(modeButton(tester).onSelectionChanged, isNotNull);

    // The control sits below the fold on the test viewport; scroll it in first.
    await tester.ensureVisible(find.text('Mistakes only'));
    await tester.tap(find.text('Mistakes only'));
    await tester.pumpAndSettle();

    expect(modeButton(tester).selected, {CaptureMode.partial});
  });

  testWidgets('session recording toggle defaults off and switches on',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pump(tester);

    final tile = find.widgetWithText(SwitchListTile, 'Record sessions (debug)');
    expect(tile, findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
  });

  testWidgets('shows the export-latest-recording tile', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pump(tester);
    expect(find.text('Export latest recording'), findsOneWidget);
  });

  testWidgets('capture-mode is disabled when data collection is off',
      (tester) async {
    SharedPreferences.setMockInitialValues({}); // collect off (default)
    await pump(tester);

    expect(modeButton(tester).onSelectionChanged, isNull);
  });
}
