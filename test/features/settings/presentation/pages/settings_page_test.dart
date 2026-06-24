import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dart_lodge/features/settings/presentation/pages/settings_page.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, Locale locale) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders English strings', (tester) async {
    await pump(tester, const Locale('en'));
    expect(find.text('Settings'), findsOneWidget); // AppBar title
    expect(find.text('THEME'), findsOneWidget); // section header (uppercased)
    expect(find.text('SOUND'), findsOneWidget); // section header (uppercased)
    expect(find.text('Sound effects'), findsOneWidget); // toggle title
    expect(find.text('DANGER ZONE'), findsOneWidget);
  });

  testWidgets('renders French strings', (tester) async {
    await pump(tester, const Locale('fr'));
    expect(find.text('Paramètres'), findsOneWidget); // AppBar title
    expect(find.text('THÈME'), findsOneWidget); // section header (uppercased)
    expect(find.text('SON'), findsOneWidget); // section header (uppercased)
    expect(find.text('ZONE DE DANGER'), findsOneWidget);
  });

  testWidgets('sound toggle is on by default and persists when turned off',
      (tester) async {
    await pump(tester, const Locale('en'));

    final soundSwitch = find.ancestor(
      of: find.text('Sound effects'),
      matching: find.byType(SwitchListTile),
    );

    expect(
      tester.widget<SwitchListTile>(soundSwitch).value,
      isTrue, // default ON
    );

    await tester.tap(soundSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(soundSwitch).value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sound_enabled'), isFalse);
  });

  testWidgets(
      'crash-reporting toggle is on by default and persists when turned off',
      (tester) async {
    await pump(tester, const Locale('en'));

    final crashSwitch = find.ancestor(
      of: find.text('Crash reporting'),
      matching: find.byType(SwitchListTile),
    );

    expect(
      tester.widget<SwitchListTile>(crashSwitch).value,
      isTrue, // opt-out: default ON
    );

    await tester.tap(crashSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(crashSwitch).value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('crash_reporting_enabled'), isFalse);
    // Toggling surfaces the "takes effect after restart" note.
    expect(find.text('Takes effect after restarting the app'), findsOneWidget);
  });

  testWidgets(
      'Report a Bug is disabled when Sentry is inactive this session',
      (tester) async {
    // Sentry is never initialized in flutter test, so Sentry.isEnabled is false
    // and the Report-a-Bug row must be disabled with the explanatory subtitle.
    await pump(tester, const Locale('en'));

    final reportBugTile = find.ancestor(
      of: find.text('Report a Bug'),
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(reportBugTile).enabled, isFalse);
    expect(
      find.text('Enable crash reporting and restart the app to report bugs'),
      findsOneWidget,
    );
  });
}
