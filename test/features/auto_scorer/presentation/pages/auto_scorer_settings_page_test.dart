import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/session_recording_provider.dart';
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
  Future<ModelUpdateStatus> restingStatus() async => _status;

  @override
  Future<ResolvedModel> resolve() async => const ResolvedModel(
        path: kAutoScorerModelAsset,
        version: kAutoScorerModelVersion,
        origin: ModelOrigin.bundled,
      );

  @override
  Future<void> checkAndStage() async {}

  @override
  Future<void> quarantine(String version, {bool remember = true}) async {}
}

/// Stands in for the web stubs (#377 §8): a store that can never hold anything.
/// Only [isSupported] is exercised — the page reads nothing else while it is
/// false, which is the point of #790.
class _UnsupportedCaptureStore implements CaptureStore {
  @override
  bool get isSupported => false;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// A store that exists but cannot be read — the disk failure behind #790's
/// first point. Exercises the real `captureCountProvider`, not a stub of it.
class _UnreadableCaptureStore implements CaptureStore {
  @override
  bool get isSupported => true;
  @override
  Future<List<CaptureRecord>> list() async =>
      throw Exception('store unreadable');
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _UnsupportedTraceStore implements SessionTraceStore {
  @override
  bool get isSupported => false;
  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester,
      {int? captureCount,
      bool realCaptureCount = false,
      List<Override> extraOverrides = const []}) async {
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
          if (!realCaptureCount)
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

  // #785: the row had promised this update, so it must not fall back to a
  // reassuring label once the model is discarded.
  testWidgets('the model tile says so when an update was discarded',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pump(tester, extraOverrides: [
      modelUpdateServiceProvider.overrideWith((ref) async =>
          _FakeModelUpdateService(ModelUpdateStatus.updateRejected)),
    ]);

    expect(find.textContaining('Update could not be used'), findsOneWidget);
    expect(find.textContaining('Up to date'), findsNothing);
    expect(find.textContaining('Update ready'), findsNothing);
  });

  // #790 — four rows on this page stated something they had not verified.

  testWidgets('a failed store read is not dressed up as a count in progress',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_collect_training_data': true});
    await pump(tester, realCaptureCount: true, extraOverrides: [
      captureStoreProvider.overrideWith((ref) async => _UnreadableCaptureStore()),
    ]);

    expect(find.text("Couldn't read the photos stored on this device."),
        findsOneWidget);
    // "Counting…" never resolves, so it must not be the resting state of a
    // failure — that is what left the player waiting for a number.
    expect(find.text('Counting…'), findsNothing);
  });

  testWidgets('capture-mode names no mode while nothing is being captured',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {}); // collection off
    await pump(tester);

    // Disabled AND unselected: greying it out alone still answered "we capture
    // your mistakes" when the honest answer is "nothing".
    expect(modeButton(tester).onSelectionChanged, isNull);
    expect(modeButton(tester).selected, isEmpty);
  });

  testWidgets('capture-mode names its mode again once collection is on',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'auto_scorer_collect_training_data': true});
    await pump(tester);

    expect(modeButton(tester).selected, {CaptureMode.partial});
  });

  testWidgets('the record toggle owns up when only one pipeline is on',
      (tester) async {
    // A pre-#686 install: the two opt-ins were separate controls, so one can be
    // on alone. The unified switch then claims both behaviours.
    SharedPreferences.setMockInitialValues({
      'auto_scorer_record_sessions': true,
      'auto_scorer_collect_training_data': false,
    });
    await pump(tester);

    expect(find.textContaining('Partly on:'), findsOneWidget);
  });

  testWidgets('the record toggle makes its full claim when both agree',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'auto_scorer_record_sessions': true,
      'auto_scorer_collect_training_data': true,
    });
    await pump(tester);

    expect(find.textContaining('Partly on:'), findsNothing);
    expect(find.textContaining('Store board photos'), findsOneWidget);
  });

  testWidgets('says so when auto-scoring is off', (tester) async {
    SharedPreferences.setMockInitialValues({'auto_scorer_use': false});
    await pump(tester);
    expect(find.textContaining('Auto-scoring is off.'), findsOneWidget);
  });

  testWidgets('stays quiet about the master switch when it is on',
      (tester) async {
    SharedPreferences.setMockInitialValues({'auto_scorer_use': true});
    await pump(tester);
    expect(find.textContaining('Auto-scoring is off.'), findsNothing);
  });

  testWidgets('offers no recording, counter or export without a store',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    await pump(tester, extraOverrides: [
      captureStoreProvider.overrideWith((ref) async => _UnsupportedCaptureStore()),
      sessionTraceStoreProvider
          .overrideWith((ref) async => _UnsupportedTraceStore()),
    ]);

    // On web both stores are no-op stubs, so the whole block promised an
    // on-device archive that could never exist.
    expect(find.text('Record for debugging & training'), findsNothing);
    expect(find.text('Your contribution'), findsNothing);
    expect(find.text('Export recordings'), findsNothing);
    // The detection controls below it are unaffected — they tune the live
    // camera, which does not need a store.
    expect(find.textContaining('Calibration confidence'), findsOneWidget);
  });
}
