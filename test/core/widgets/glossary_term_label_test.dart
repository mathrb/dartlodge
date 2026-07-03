import 'package:dart_lodge/core/glossary/stat_term.dart';
import 'package:dart_lodge/core/widgets/glossary_term_label.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, StatTerm term) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: Center(
          child: GlossaryTermLabel(label: 'PPR', term: term),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the label text with an info glyph', (tester) async {
    await pump(tester, StatTerm.ppr);
    expect(find.text('PPR'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('exposes a button semantics node', (tester) async {
    await pump(tester, StatTerm.ppr);
    expect(
      tester.getSemantics(find.byType(GlossaryTermLabel)),
      containsSemantics(isButton: true),
    );
  });

  testWidgets('tapping opens the definition dialog for the term',
      (tester) async {
    await pump(tester, StatTerm.mpr);

    // Definition not shown until tapped.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.glossaryMprBody), findsNothing);

    await tester.tap(find.byType(GlossaryTermLabel));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l10n.glossaryMprTitle), findsOneWidget);
    expect(find.text(l10n.glossaryMprBody), findsOneWidget);
  });
}
