import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dart_lodge/features/settings/presentation/pages/settings_page.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    Locale locale, {
    double scale = 1.0,
    Size size = const Size(1080, 3200),
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ── Theme selector at large text (DESIGN_SYSTEM §13) ──────────────────────

  RenderParagraph themeLabel(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(SegmentedButton<ThemeMode>),
          matching: find.text(text),
        ),
      );

  // The test font draws every glyph 1 em wide, far wider than the app font,
  // so at 2.0x a 412 dp page also overflows unrelated rows (the language
  // tile) in tests although they fit on a device. The 2.0x case runs on a
  // 700 dp surface, where "Système" still breaks on one segment without the
  // fix but the rest of the page lays out.
  for (final (scale, width) in [(1.3, 412.0), (2.0, 700.0)]) {
    testWidgets('fr theme labels stay on one line at ${scale}x', (
      tester,
    ) async {
      await pump(
        tester,
        const Locale('fr'),
        scale: scale,
        size: Size(width, 3200),
      );

      expect(tester.takeException(), isNull);
      for (final label in ['Clair', 'Système', 'Sombre']) {
        final p = themeLabel(tester, label);
        expect(_lineCount(p), 1, reason: '"$label" must not break mid-word');
        expect(p.didExceedMaxLines, isFalse);
      }
    });
  }

  testWidgets('en theme labels are not scaled down at 1.0x', (tester) async {
    // A wide surface: the test font is wider than the app font, so 412 dp
    // would already squeeze the labels here.
    await pump(tester, const Locale('en'));

    for (final label in ['Light', 'System', 'Dark']) {
      final p = themeLabel(tester, label);
      expect(_lineCount(p), 1);
      final fitted = find.ancestor(
        of: find.text(label),
        matching: find.byType(FittedBox),
      );
      expect(fitted, findsOneWidget);
      final box = tester.renderObject<RenderBox>(fitted);
      expect(
        box.size.width,
        closeTo(p.size.width, 0.01),
        reason: '"$label" fits, so the FittedBox must not shrink it',
      );
    }
  });

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
      'simplified-input toggle is off by default and persists when turned on',
      (tester) async {
    await pump(tester, const Locale('en'));

    final simplifiedSwitch = find.ancestor(
      of: find.text('Simplified scoring keypad'),
      matching: find.byType(SwitchListTile),
    );

    expect(
      tester.widget<SwitchListTile>(simplifiedSwitch).value,
      isFalse, // dense grid stays the default
    );

    await tester.tap(simplifiedSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(simplifiedSwitch).value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('simplified_scoring_layout'), isTrue);
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

  testWidgets(
      'Contact us shows the project address and stays enabled with Sentry off',
      (tester) async {
    await pump(tester, const Locale('en'));

    final contactTile = find.ancestor(
      of: find.text('Contact us'),
      matching: find.byType(ListTile),
    );
    expect(contactTile, findsOneWidget);
    expect(find.text('dartlodge@gmail.com'), findsOneWidget);
    expect(tester.widget<ListTile>(contactTile).enabled, isTrue);
  });
}

/// The number of laid-out lines of [p]: its height over one line's height.
int _lineCount(RenderParagraph p) {
  final oneLine = TextPainter(
    text: p.text,
    textScaler: p.textScaler,
    textDirection: p.textDirection,
    maxLines: 1,
  )..layout();
  final lines = (p.size.height / oneLine.height).round();
  oneLine.dispose();
  return lines;
}
