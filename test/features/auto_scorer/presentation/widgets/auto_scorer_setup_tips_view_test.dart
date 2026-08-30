import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_setup_tips_view.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/calibration_marker_diagram_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a host screen whose button pushes the tips view, recording the value it
/// pops with into [sink], so tests can assert the Continue / "don't show again"
/// contract (false = keep showing, true = remember).
Future<void> _open(WidgetTester tester, void Function(bool?) sink) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              sink(await Navigator.of(context).push<bool>(MaterialPageRoute(
                  builder: (_) => const AutoScorerSetupTipsView())));
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the setup tips and always-visible controls',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: const AutoScorerSetupTipsView(),
    ));

    // The marker diagram opens the screen — the tips below all refer to it.
    expect(find.text('What the camera looks for'), findsOneWidget);
    expect(find.byType(CalibrationMarkerDiagram), findsOneWidget);

    // The tips follow the diagram, reachable by scrolling the list.
    await tester.scrollUntilVisible(find.text('Fill the frame'), 120);
    expect(find.text('Fill the frame'), findsOneWidget);

    // #740: the framing tip no longer sends the player to the image corners.
    final tip1 = tester.widget<Text>(find.textContaining('fills most of'));
    expect(tip1.data, isNot(contains('corner')));

    // The key model-constraint tip ("any rotation") is there too.
    await tester.scrollUntilVisible(find.text('Any rotation is fine'), 120);
    expect(find.text('Any rotation is fine'), findsOneWidget);
    // Checkbox + action live in the bottom bar, always reachable.
    expect(find.text("Don't show this again"), findsOneWidget);
    expect(find.text('Continue to camera'), findsOneWidget);

    // A later tip is reachable by scrolling the list.
    await tester.scrollUntilVisible(find.text('Steel-tip boards'), 120);
    expect(find.text('Steel-tip boards'), findsOneWidget);
  });

  testWidgets('review mode hides the checkbox + Continue action',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: const AutoScorerSetupTipsView(reviewOnly: true),
    ));

    // Diagram + tips still render…
    expect(find.byType(CalibrationMarkerDiagram), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Fill the frame'), 120);
    expect(find.text('Fill the frame'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Any rotation is fine'), 120);
    expect(find.text('Any rotation is fine'), findsOneWidget);
    // …but the game-flow controls are gone (nothing to continue to / remember).
    expect(find.text("Don't show this again"), findsNothing);
    expect(find.text('Continue to camera'), findsNothing);
  });

  testWidgets('Continue without checking pops false', (tester) async {
    bool? result;
    await _open(tester, (v) => result = v);
    await tester.tap(find.text('Continue to camera'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('checking "don\'t show again" then Continue pops true',
      (tester) async {
    bool? result;
    await _open(tester, (v) => result = v);
    await tester.tap(find.text("Don't show this again"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to camera'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
