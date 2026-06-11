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

    await tester.tap(find.text('Mistakes only'));
    await tester.pumpAndSettle();

    expect(modeButton(tester).selected, {CaptureMode.partial});
  });

  testWidgets('capture-mode is disabled when data collection is off',
      (tester) async {
    SharedPreferences.setMockInitialValues({}); // collect off (default)
    await pump(tester);

    expect(modeButton(tester).onSelectionChanged, isNull);
  });
}
