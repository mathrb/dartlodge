// The full scoring keypad marks its double and triple keys with a small
// "D" / "T" prefix, the notation the checkout route ("T20 · T19 · D12"), the
// dart chips and the history already use. The 2/3 dots stay as a secondary
// cue, and the prefix is excluded from semantics so the screen-reader names
// (and the e2e selectors "Triple 20 20") are unchanged.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_colors.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dart_input_grid_widget.dart';
import 'package:dart_lodge/features/game/presentation/widgets/dot_row_widget.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

Widget _wrap({bool dark = false}) => MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 420,
          child: DartInputGridWidget(onSegmentTapped: (_) {}),
        ),
      ),
    );

Finder _cell(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == label,
    );

void main() {
  testWidgets('every double key shows a D prefix, every triple key a T',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('D'), findsNWidgets(20));
    expect(find.text('T'), findsNWidgets(20));
    // The dots stay as a secondary cue.
    expect(find.byType(DotRow), findsNWidgets(40));
  });

  testWidgets('the prefix sits in its own key, left of the number',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    for (final (label, prefix) in [
      ('Triple 19', 'T'),
      ('Double 12', 'D'),
    ]) {
      final cell = _cell(label);
      expect(cell, findsOneWidget, reason: label);
      final letter = find.descendant(of: cell, matching: find.text(prefix));
      final number = find.descendant(
          of: cell, matching: find.text(label.split(' ').last));
      expect(letter, findsOneWidget, reason: label);
      expect(number, findsOneWidget, reason: label);
      expect(tester.getRect(letter).right,
          lessThanOrEqualTo(tester.getRect(number).left + 0.5),
          reason: label);
    }
  });

  testWidgets('single keys have no prefix', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    final single = _cell('Single 20');
    expect(single, findsOneWidget);
    expect(find.descendant(of: single, matching: find.text('D')), findsNothing);
    expect(find.descendant(of: single, matching: find.text('T')), findsNothing);
  });

  testWidgets('screen-reader names are unchanged (e2e selectors)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Triple 20\n20'), findsOneWidget);
    expect(find.bySemanticsLabel('Double 1\n1'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'\bT20\b')), findsNothing);
    handle.dispose();
  });

  testWidgets('prefix uses the board accent in both themes', (tester) async {
    Set<Color?> letterColours() => tester
        .widgetList<Text>(find.byWidgetPredicate(
            (w) => w is Text && (w.data == 'D' || w.data == 'T')))
        .map((t) => t.style?.color)
        .toSet();

    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(letterColours(), {AppColors.primary});

    await tester.pumpWidget(_wrap(dark: true));
    await tester.pumpAndSettle();
    expect(letterColours(),
        {AppColorsDark.primaryFixed.withValues(alpha: 0.7)});
  });
}
