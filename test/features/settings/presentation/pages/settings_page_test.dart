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
    expect(find.text('DANGER ZONE'), findsOneWidget);
  });

  testWidgets('renders French strings', (tester) async {
    await pump(tester, const Locale('fr'));
    expect(find.text('Paramètres'), findsOneWidget); // AppBar title
    expect(find.text('THÈME'), findsOneWidget); // section header (uppercased)
    expect(find.text('ZONE DE DANGER'), findsOneWidget);
  });
}
