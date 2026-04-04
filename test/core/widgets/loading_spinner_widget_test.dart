import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/widgets/loading_spinner_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LoadingSpinnerWidget', () {
    testWidgets('renders CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingSpinnerWidget()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('without height — no SizedBox wrapper', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingSpinnerWidget()));
      // Direct child of Scaffold body is Center, not SizedBox
      expect(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height != null,
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('with height — renders inside SizedBox of given height',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoadingSpinnerWidget(height: 80)));
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.height, 80);
    });

    testWidgets('with color — passes color to indicator', (tester) async {
      await tester.pumpWidget(
        _wrap(const LoadingSpinnerWidget(color: Colors.red)),
      );
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, Colors.red);
    });
  });
}
