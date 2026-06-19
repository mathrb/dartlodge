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
}
