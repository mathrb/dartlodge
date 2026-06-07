import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_setup_tips_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a host screen whose button pushes the tips view, recording the value it
/// pops with into [sink], so tests can assert the Continue / "don't show again"
/// contract (false = keep showing, true = remember).
Future<void> _open(WidgetTester tester, void Function(bool?) sink) async {
  await tester.pumpWidget(MaterialApp(
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
    await tester.pumpWidget(
        const MaterialApp(home: AutoScorerSetupTipsView()));

    // Top tips are on-screen (the list scrolls for the rest); the key
    // model-constraint tip ("any rotation") is among them.
    expect(find.text('Fill the frame'), findsOneWidget);
    expect(find.text('A slight side angle'), findsOneWidget);
    expect(find.text('Any rotation is fine'), findsOneWidget);
    // Checkbox + action live in the bottom bar, always reachable.
    expect(find.text("Don't show this again"), findsOneWidget);
    expect(find.text('Continue to camera'), findsOneWidget);

    // A later tip is reachable by scrolling the list.
    await tester.scrollUntilVisible(find.text('Steel-tip boards'), 120);
    expect(find.text('Steel-tip boards'), findsOneWidget);
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
