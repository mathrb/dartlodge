import 'package:dart_lodge/features/auto_scorer/presentation/widgets/aim_explanation_panel.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> fired;

  Future<void> pump(WidgetTester tester, {required bool recordingOn}) async {
    fired = [];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(
        body: AimExplanationPanel(
          recordingOn: recordingOn,
          onPlayAnyway: () => fired.add('play'),
          onKeepAiming: () => fired.add('keep'),
          onEnableRecording: () => fired.add('enable'),
        ),
      ),
    ));
  }

  testWidgets('explains the situation and offers both ways out',
      (tester) async {
    await pump(tester, recordingOn: true);

    expect(find.text("The camera can't find your board"), findsOneWidget);
    expect(find.textContaining('four points on the outer wire'), findsOneWidget);
    expect(find.text('Play anyway'), findsOneWidget);
    expect(find.text('Keep aiming'), findsOneWidget);
  });

  testWidgets('states the loop without implying on-device learning (#743)',
      (tester) async {
    await pump(tester, recordingOn: true);

    final loop = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.contains('score by hand'));
    // The honest chain: photos → sent → retrained → the new model comes back.
    expect(loop, contains('retrained'));
    expect(loop, contains('reaches the app on its own'));
    // And the explicit denial the maintainer asked for.
    expect(loop, contains('Nothing is learned on your phone'));
  });

  testWidgets('offers to turn recording on only when it is off',
      (tester) async {
    await pump(tester, recordingOn: false);
    expect(find.text('Turn on recording'), findsOneWidget);
    expect(find.textContaining('No photos are being saved'), findsOneWidget);

    // The offer sits in the panel's scrollable prose (the two actions are the
    // part pinned in view), so bring it up before tapping.
    await tester.ensureVisible(find.text('Turn on recording'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn on recording'));
    expect(fired, ['enable']);

    await pump(tester, recordingOn: true);
    expect(find.text('Turn on recording'), findsNothing);
    expect(find.textContaining('Recording is on'), findsOneWidget);
  });

  testWidgets('both actions stay available with recording off (#743)',
      (tester) async {
    // Declining the recording offer must never block playing on.
    await pump(tester, recordingOn: false);

    await tester.tap(find.text('Play anyway'));
    await tester.tap(find.text('Keep aiming'));
    expect(fired, ['play', 'keep']);
  });
}
