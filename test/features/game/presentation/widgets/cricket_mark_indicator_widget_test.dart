import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/features/game/presentation/widgets/cricket_mark_indicator_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CricketMarkIndicatorWidget', () {
    testWidgets('marks=0 renders dash (–)', (tester) async {
      await tester.pumpWidget(_wrap(const CricketMarkIndicatorWidget(marks: 0)));
      expect(find.text('–'), findsOneWidget);
    });

    testWidgets('marks=1 renders slash (/)', (tester) async {
      await tester.pumpWidget(_wrap(const CricketMarkIndicatorWidget(marks: 1)));
      expect(find.text('/'), findsOneWidget);
    });

    testWidgets('marks=2 renders X', (tester) async {
      await tester.pumpWidget(_wrap(const CricketMarkIndicatorWidget(marks: 2)));
      expect(find.text('X'), findsOneWidget);
    });

    testWidgets('marks=3 renders circled times (⊗)', (tester) async {
      await tester.pumpWidget(_wrap(const CricketMarkIndicatorWidget(marks: 3)));
      expect(find.text('⊗'), findsOneWidget);
    });

    testWidgets('marks=-1 clamps to 0 and renders dash (–)', (tester) async {
      await tester
          .pumpWidget(_wrap(const CricketMarkIndicatorWidget(marks: -1)));
      expect(find.text('–'), findsOneWidget);
    });

    testWidgets('marks=4 clamps to 3 and renders circled times (⊗)',
        (tester) async {
      await tester.pumpWidget(_wrap(const CricketMarkIndicatorWidget(marks: 4)));
      expect(find.text('⊗'), findsOneWidget);
    });

    testWidgets('renders without providers (StatelessWidget)', (tester) async {
      await tester.pumpWidget(_wrap(const CricketMarkIndicatorWidget(marks: 0)));
      expect(tester.takeException(), isNull);
    });
  });
}
