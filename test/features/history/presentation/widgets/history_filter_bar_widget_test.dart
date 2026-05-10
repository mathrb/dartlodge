import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/history/presentation/widgets/history_filter_bar_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );

void main() {
  testWidgets('renders the dropdown with the "All" sentinel selected',
      (tester) async {
    await tester.pumpWidget(_wrap(HistoryFilterBarWidget(
      selectedGameType: null,
      selectedDateFrom: null,
      selectedDateTo: null,
      onGameTypeChanged: (_) {},
      onDateRangeChanged: (_, __) {},
      onClearFilters: () {},
    )));

    // The dropdown is built with DropdownMenuItem<GameType?> — assert that
    // the field is present and that "All" appears in the visible label.
    expect(find.byType(DropdownButtonFormField<GameType?>), findsOneWidget);
    expect(find.text('All'), findsWidgets);
  });

  testWidgets('preselected game type reflects in the field label',
      (tester) async {
    await tester.pumpWidget(_wrap(HistoryFilterBarWidget(
      selectedGameType: GameType.bobs27,
      selectedDateFrom: null,
      selectedDateTo: null,
      onGameTypeChanged: (_) {},
      onDateRangeChanged: (_, __) {},
      onClearFilters: () {},
    )));

    expect(find.text("Bob's 27"), findsOneWidget);
  });

  testWidgets('Clear button shows only when a filter is active',
      (tester) async {
    // Inactive: no clear icon.
    await tester.pumpWidget(_wrap(HistoryFilterBarWidget(
      selectedGameType: null,
      selectedDateFrom: null,
      selectedDateTo: null,
      onGameTypeChanged: (_) {},
      onDateRangeChanged: (_, __) {},
      onClearFilters: () {},
    )));
    expect(find.byIcon(Icons.clear), findsNothing);

    // Active: clear icon shown.
    await tester.pumpWidget(_wrap(HistoryFilterBarWidget(
      selectedGameType: GameType.cricket,
      selectedDateFrom: null,
      selectedDateTo: null,
      onGameTypeChanged: (_) {},
      onDateRangeChanged: (_, __) {},
      onClearFilters: () {},
    )));
    expect(find.byIcon(Icons.clear), findsOneWidget);
  });
}
