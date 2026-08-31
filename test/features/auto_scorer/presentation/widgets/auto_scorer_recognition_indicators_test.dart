import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/auto_scorer/domain/framing/recognition_state.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_recognition_indicators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Pumps the halo and returns the colour it actually painted its border in.
  Future<Color> haloBorderColor(
      WidgetTester tester, RecognitionGrade? grade) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RecognitionHalo(
          grade: grade,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    ));
    final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first);
    final decoration = container.decoration! as BoxDecoration;
    return decoration.border!.top.color;
  }

  testWidgets('a null grade paints the neutral border, not the alarm (#758)',
      (tester) async {
    final neutral = await haloBorderColor(tester, null);
    final alarm = await haloBorderColor(tester, RecognitionGrade.none);
    final context = tester.element(find.byType(RecognitionHalo));

    expect(neutral, isNot(alarm));
    expect(neutral, Theme.of(context).colorScheme.outlineVariant);
  });

  testWidgets('the graded colours are unchanged', (tester) async {
    final none = await haloBorderColor(tester, RecognitionGrade.none);
    final partial = await haloBorderColor(tester, RecognitionGrade.partial);
    final ready = await haloBorderColor(tester, RecognitionGrade.ready);
    final context = tester.element(find.byType(RecognitionHalo));

    expect(none, Theme.of(context).colorScheme.error);
    expect(partial, AppTheme.award(context));
    expect(ready, AppTheme.success(context));
  });
}
