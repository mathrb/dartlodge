import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/pages/auto_scorer_settings_page.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/capture_count_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/model_update_provider.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 exports the override type from misc.dart, matching
// game_heatmap_section_widget_test.dart.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The page reads the capture store on export-tap and, for the contribution
// tile (#742), through `captureCountProvider` — which tests override, so the
// page still pumps cleanly against mock SharedPreferences. Covers the #457
// capture-mode control; the live camera/capture path stays device-only.
/// Reports a fixed status so the model-update tile can be pumped without the
/// on-device OTA service. `isSupported` must be true or the tile is hidden.
class _FakeModelUpdateService implements ModelUpdateService {
  _FakeModelUpdateService(this._status);
  final ModelUpdateStatus _status;

  @override
  bool get isSupported => true;

  @override
  ModelUpdateStatus get status => _status;

  @override
  Future<ResolvedModel> resolve() async => const ResolvedModel(
        path: kAutoScorerModelAsset,
        version: kAutoScorerModelVersion,
        origin: ModelOrigin.bundled,
      );

  @override
  Future<void> checkAndStage() async {}

  @override
  Future<void> quarantine(String version) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester,
      {int? captureCount, List<Override> extraOverrides = const []}) async {
    // Tall viewport so the whole settings list fits without scrolling — the
    // controls below the fold (capture-mode, toggles) stay tappable.
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          // The real provider opens the on-device capture store; give the tile
          // a number instead of a plugin.
          captureCountProvider.overrideWith((ref) async => captureCount ?? 0),
          ...extraOverrides,
        ],
        child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: const AutoScorerSettingsPage(),
    )));
    await tester.pumpAndSettle();
  }

  SegmentedButton<CaptureMode> modeButton(WidgetTester tester) =>
      tester.widget<SegmentedButton<CaptureMode>>(
          find.byType(SegmentedButton<CaptureMode>));

  testWidgets('capture-mode defaults to Mistakes only and switches to All',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_collect_training_data': true});
    await pump(tester);

    expect(modeButton(tester).selected, {CaptureMode.partial});
    expect(modeButton(tester).onSelectionChanged, isNotNull);

    // The control sits below the fold on the test viewport; scroll it in first.
    await tester.ensureVisible(find.text('All'));
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(modeButton(tester).selected, {CaptureMode.all});
  });

  testWidgets('single record toggle defaults off and enables capture when on',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pump(tester);

    final tile =
        find.widgetWithText(SwitchListTile, 'Record for debugging & training');
    expect(tile, findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    // While recording is off, the capture-mode control is disabled.
    expect(modeButton(tester).onSelectionChanged, isNull);

    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    // Enabling recording turns data collection on, so capture-mode is now live.
    expect(modeButton(tester).onSelectionChanged, isNotNull);
  });

  testWidgets('shows a single export tile (no separate session export)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pump(tester);
    expect(find.text('Export recordings'), findsOneWidget);
    expect(find.text('Export latest recording'), findsNothing);
    expect(find.text('Export training data'), findsNothing);
  });

  testWidgets('capture-mode is disabled when recording is off', (tester) async {
    SharedPreferences.setMockInitialValues({}); // recording off (default)
    await pump(tester);

    expect(modeButton(tester).onSelectionChanged, isNull);
  });

  testWidgets('the contribution tile shows the stored training-photo total',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_collect_training_data': true});
    await pump(tester, captureCount: 12);

    expect(find.text('Your contribution'), findsOneWidget);
    expect(find.text('12 training photos on this device'), findsOneWidget);
  });

  testWidgets('the contribution tile reads sensibly with nothing stored',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    await pump(tester, captureCount: 0);

    expect(find.text('No training photos on this device yet'), findsOneWidget);
  });

  // #782: every failure path used to leave the status at upToDate, so a dead
  // network or a 404 read as "Up to date" in this row while the note under it
  // promised that retrained models arrive on their own.
  testWidgets('the model tile says so when the last check failed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pump(tester, extraOverrides: [
      modelUpdateServiceProvider.overrideWith(
          (ref) async => _FakeModelUpdateService(
              ModelUpdateStatus.checkFailed)),
    ]);

    expect(find.textContaining('Last check failed'), findsOneWidget);
    expect(find.textContaining('Up to date'), findsNothing);
  });
}
