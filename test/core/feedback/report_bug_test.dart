import 'package:dart_lodge/core/feedback/report_bug.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Pump a button that opens the shared report-bug dialog, so the dialog UI is
  // exercised independently of any feature page (#688).
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showReportBugDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
  }

  test('isBugReportingAvailable is false when Sentry is not initialized', () {
    // flutter test never calls SentryFlutter.init, so the hub is the NoOpHub.
    expect(isBugReportingAvailable(), isFalse);
  });

  testWidgets('showReportBugDialog shows the report dialog with Send/Cancel',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Report a Bug'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Cancel dismisses the dialog without submitting', (tester) async {
    await pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Report a Bug'), findsNothing);
  });

  testWidgets('entering a message and tapping Send closes the dialog',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'something broke');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    // Sentry.captureFeedback is a no-op here (hub disabled); the dialog closes.
    expect(find.text('Report a Bug'), findsNothing);
  });
}
