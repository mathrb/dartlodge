import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/widgets/app_header.dart';

/// #599: AppHeader shows the brand logo by default, but a page title when
/// [title] is provided (so Statistics reads as a titled destination).
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows the DARTLODGE logo when no title is given', (tester) async {
    await tester.pumpWidget(wrap(const AppHeader()));
    expect(find.text('DARTLODGE'), findsOneWidget);
  });

  testWidgets('shows the page title instead of the logo when title is given',
      (tester) async {
    await tester.pumpWidget(wrap(const AppHeader(title: 'Statistics')));
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('DARTLODGE'), findsNothing);
  });

  testWidgets('untitled wordmark is two-tone: DART neon + LODGE on-surface '
      '(#692)', (tester) async {
    await tester.pumpWidget(wrap(const AppHeader()));
    final cs = Theme.of(tester.element(find.byType(AppHeader))).colorScheme;

    final textWidget = tester.widget<Text>(find.descendant(
      of: find.byType(AppHeader),
      matching: find.byType(Text),
    ));
    final root = textWidget.textSpan! as TextSpan;
    final spans = root.children!.cast<TextSpan>();

    expect(spans.map((s) => s.text).toList(), ['DART', 'LODGE']);
    expect(spans[0].style!.color, cs.primaryFixed); // DART = brand neon
    expect(spans[1].style!.color, cs.onSurface); // LODGE = neutral on-surface
    expect(spans[0].style!.color, isNot(spans[1].style!.color));
  });
}
