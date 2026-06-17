import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/features/settings/presentation/widgets/language_selector.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

void main() {
  Widget wrap({
    required Locale appLocale,
    required Locale? value,
    required ValueChanged<Locale?> onChanged,
  }) {
    return MaterialApp(
      locale: appLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: LanguageSelector(value: value, onChanged: onChanged),
      ),
    );
  }

  testWidgets('English: shows label + system default, picking a language '
      'calls onChanged', (tester) async {
    Locale? picked;
    var called = false;
    await tester.pumpWidget(wrap(
      appLocale: const Locale('en'),
      value: null,
      onChanged: (l) {
        called = true;
        picked = l;
      },
    ));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    // Dialog is open with the language options.
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(picked, const Locale('fr'));
  });

  testWidgets('French: row label and system option are localized',
      (tester) async {
    await tester.pumpWidget(wrap(
      appLocale: const Locale('fr'),
      value: null,
      onChanged: (_) {},
    ));
    await tester.pumpAndSettle();

    expect(find.text('Langue'), findsOneWidget);
    expect(find.text('Système par défaut'), findsOneWidget);
  });

  testWidgets('explicit value shows its autonym; picking System calls '
      'onChanged(null)', (tester) async {
    Locale? picked = const Locale('fr');
    var called = false;
    await tester.pumpWidget(wrap(
      appLocale: const Locale('en'),
      value: const Locale('fr'),
      onChanged: (l) {
        called = true;
        picked = l;
      },
    ));
    await tester.pumpAndSettle();

    // Trailing shows the current pick's autonym.
    expect(find.text('Français'), findsOneWidget);

    // Open the picker via the row label (unique before the dialog opens).
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('System default'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(picked, isNull);
  });

  testWidgets('tapping the already-selected option closes the dialog '
      '(no dead-end)', (tester) async {
    var called = false;
    await tester.pumpWidget(wrap(
      appLocale: const Locale('en'),
      value: const Locale('fr'),
      onChanged: (_) => called = true,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.byType(SimpleDialog), findsOneWidget);

    // Tap the currently-selected row (disambiguate from the trailing label).
    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Français'));
    await tester.pumpAndSettle();

    // Without toggleable:true the tap would be swallowed and the dialog would
    // stay open with no way out. It must close.
    expect(find.byType(SimpleDialog), findsNothing);
    expect(called, isTrue);
  });
}
