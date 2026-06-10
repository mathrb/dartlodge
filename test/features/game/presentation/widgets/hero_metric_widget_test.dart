// #442 — the hero metric widget renders the primary game-state value (X01
// remaining score / practice target) large and at-distance-readable for
// auto-scoring mode. Presentational and game-agnostic: value is a pre-formatted
// String, with an optional uppercase caption and an optional value tint.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/game/presentation/widgets/hero_metric_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders the value', (tester) async {
    await tester.pumpWidget(_wrap(const HeroMetricWidget(value: '341')));

    expect(find.text('341'), findsOneWidget);
  });

  testWidgets('renders the label uppercased above the value', (tester) async {
    await tester.pumpWidget(_wrap(const HeroMetricWidget(
      value: '14',
      label: 'Target',
    )));

    expect(find.text('TARGET'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
  });

  testWidgets('without a label, only the value is rendered', (tester) async {
    await tester.pumpWidget(_wrap(const HeroMetricWidget(value: '341')));

    // The value is the sole Text in the widget.
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('applies valueColor to the value text', (tester) async {
    const color = Color(0xFF00FFAB);
    await tester.pumpWidget(_wrap(const HeroMetricWidget(
      value: '170',
      valueColor: color,
    )));

    final text = tester.widget<Text>(find.text('170'));
    expect(text.style?.color, color);
  });

  testWidgets('renders the value on a single line (numerals never wrap)',
      (tester) async {
    await tester.pumpWidget(_wrap(const HeroMetricWidget(value: '1001')));

    expect(find.text('1001'), findsOneWidget);
    final text = tester.widget<Text>(find.text('1001'));
    expect(text.maxLines, 1);
  });
}
