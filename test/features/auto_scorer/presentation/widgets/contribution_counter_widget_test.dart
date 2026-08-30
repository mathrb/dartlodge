import 'package:dart_lodge/features/auto_scorer/presentation/widgets/contribution_counter_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(int count) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: kSupportedLocales,
      home: Scaffold(body: Center(child: ContributionCounter(count: count))),
    );

/// The uniform scale the counter is currently drawn at. Scoped to the
/// counter's own Transform — Material inserts others (ink, icons) above it.
double _scale(WidgetTester tester) {
  final transform = tester.widget<Transform>(find
      .descendant(
        of: find.byType(ContributionCounter),
        matching: find.byType(Transform),
      )
      .first);
  return transform.transform.getMaxScaleOnAxis();
}

void main() {
  testWidgets('renders the count with a spoken description', (tester) async {
    await tester.pumpWidget(_host(3));

    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('3 training photos captured this game'),
        findsOneWidget);
  });

  testWidgets('reads correctly at zero and at one', (tester) async {
    await tester.pumpWidget(_host(0));
    expect(find.text('0'), findsOneWidget);
    expect(find.bySemanticsLabel('No training photos captured this game'),
        findsOneWidget);

    await tester.pumpWidget(_host(1));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('1 training photo captured this game'),
        findsOneWidget);
  });

  testWidgets('pulses when the count goes up, then settles back',
      (tester) async {
    await tester.pumpWidget(_host(1));
    expect(_scale(tester), closeTo(1.0, 1e-6));

    await tester.pumpWidget(_host(2));
    // Into the pulse, the counter is enlarged. A short pump on purpose: a test
    // binding with `disableAnimations` scales the controller's duration down,
    // so anything expressed as a fraction of [kContributionPulseDuration]
    // would already be over.
    await tester.pump(const Duration(milliseconds: 10));
    expect(_scale(tester), greaterThan(1.0));
    expect(find.text('2'), findsOneWidget);

    // …and back to rest once it finishes, so it doesn't sit highlighted.
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1.0, 1e-6));
  });

  testWidgets('a reset to zero is not acknowledged (#742)', (tester) async {
    // A new camera session restarts the count — that is not a contribution.
    await tester.pumpWidget(_host(4));
    await tester.pumpWidget(_host(0));
    await tester.pump(const Duration(milliseconds: 10));
    expect(_scale(tester), closeTo(1.0, 1e-6));
  });
}
