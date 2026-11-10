// Regression test for #261: at 412px width with the ATC stats Row's
// 4:1 flex split, the right-hand `AtcSummaryColumnWidget` is allotted
// ~82px. Its OVERALL value uses `AppTextStyles.scoreSmall` (36pt), so
// "100%" would overflow and wrap to three lines ("10\n0\n%") without
// the FittedBox guard. Test renders the widget in a tight column and
// asserts the "100%" Text stays on a single line.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/statistics/presentation/widgets/atc_summary_column_widget.dart';

Widget _wrap(Widget child, {double width = 90, Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: kSupportedLocales,
    theme: AppTheme.light(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets(
      'OVERALL value renders on a single line at 90px column width (#261)',
      (tester) async {
    // All-hit fixture → OVERALL = 100% (so does every per-segment row).
    // Scope the finder to the FittedBox below "OVERALL" — that's the
    // headline value the bug report is about.
    await tester.pumpWidget(_wrap(
      AtcSummaryColumnWidget(
        hits: const {1: 5, 2: 5, 3: 5},
        attempts: const {1: 5, 2: 5, 3: 5},
      ),
    ));

    final overallText = find.descendant(
      of: find.byType(FittedBox),
      matching: find.text('100%'),
    );
    expect(overallText, findsOneWidget);
    final renderText = tester.renderObject<RenderBox>(overallText);
    // One line tall ≈ font height (40px). If the FittedBox guard
    // regressed, the Text would wrap and the box would be ~3× taller.
    // 100 is a generous one-line ceiling.
    expect(renderText.size.height, lessThan(100));
  });

  testWidgets(
      'no-data state renders the em-dash placeholder on a single line',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const AtcSummaryColumnWidget(hits: {}, attempts: {}),
    ));

    expect(find.text('—'), findsOneWidget);
    final renderText = tester.renderObject<RenderBox>(find.text('—'));
    expect(renderText.size.height, lessThan(100));
  });

  // On a 412 px phone the column is ~70 px wide inside its card, and the
  // WEAKEST section header wrapped mid-word ("WEAKES" / "T"). Each header
  // must be exactly one line of its own style tall; a wrap doubles it.
  for (final (locale, headers) in [
    (const Locale('en'), ['OVERALL', 'BEST', 'WEAKEST']),
    (const Locale('fr'), ['GLOBAL', 'MEILLEURS', 'PLUS FAIBLES']),
  ]) {
    testWidgets(
        'section headers stay on one line at 70px column width '
        '(${locale.languageCode})', (tester) async {
      await tester.pumpWidget(_wrap(
        const AtcSummaryColumnWidget(hits: {}, attempts: {}),
        width: 70,
        locale: locale,
      ));

      for (final header in headers) {
        final finder = find.text(header);
        final oneLine = TextPainter(
          text: TextSpan(text: 'X', style: tester.widget<Text>(finder).style),
          textDirection: TextDirection.ltr,
        )..layout();
        expect(tester.getSize(finder).height, oneLine.height,
            reason: '"$header" wrapped');
        oneLine.dispose();
      }
    });
  }
}
