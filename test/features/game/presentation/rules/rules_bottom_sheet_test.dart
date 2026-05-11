import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/presentation/rules/rules_bottom_sheet.dart';

void main() {
  Widget _host() => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showRules(context, 'cricket-standard'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

  testWidgets('renders title, tagline, and the Objective heading', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Cricket — Standard'), findsOneWidget);
    expect(find.text('Objective'), findsOneWidget);
    expect(find.text('Winning'), findsOneWidget);
  });

  testWidgets('shows "Rules unavailable." for an unknown slug', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showRules(context, 'no-such-game'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Rules unavailable.'), findsOneWidget);
  });

  testWidgets('Cricket Standard shows related variants block', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Related variants'), findsOneWidget);
    expect(find.text('Cut Throat'), findsOneWidget);
  });
}
