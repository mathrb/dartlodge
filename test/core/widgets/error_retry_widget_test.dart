import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_darts/core/widgets/error_retry_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ErrorRetryWidget — compact (no title)', () {
    testWidgets('renders message and Retry TextButton', (tester) async {
      await tester.pumpWidget(_wrap(
        ErrorRetryWidget(message: 'Something went wrong', onRetry: () {}),
      ));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('onRetry fires when Retry is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        ErrorRetryWidget(
          message: 'Load failed',
          onRetry: () => called = true,
        ),
      ));
      await tester.tap(find.text('Retry'));
      expect(called, isTrue);
    });

    testWidgets('does not render icon or ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(
        ErrorRetryWidget(message: 'err', onRetry: () {}),
      ));
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('ErrorRetryWidget — prominent (with title)', () {
    testWidgets('renders icon, title, message and ElevatedButton', (tester) async {
      await tester.pumpWidget(_wrap(
        ErrorRetryWidget(
          title: 'Failed to load',
          message: 'Network error',
          onRetry: () {},
        ),
      ));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('onRetry fires when Retry ElevatedButton is tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(
        ErrorRetryWidget(
          title: 'Error',
          message: 'detail',
          onRetry: () => called = true,
        ),
      ));
      await tester.tap(find.text('Retry'));
      expect(called, isTrue);
    });
  });
}
