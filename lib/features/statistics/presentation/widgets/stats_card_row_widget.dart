import 'package:flutter/material.dart';

import '../../../../core/widgets/text_measurer.dart';
import 'stats_card_widget.dart';

/// A row of equal-width [StatsCardWidget]s, or a stack of full-width cards
/// when a card cannot fit its share of the row without breaking a label
/// word or the value (long locales, large system text — DESIGN_SYSTEM §13).
///
/// Side by side, the cards share the tallest card's height so their values
/// line up when the labels wrap to different line counts.
class StatsCardRowWidget extends StatelessWidget {
  const StatsCardRowWidget({required this.cards, super.key});

  final List<StatsCardWidget> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final measure = TextMeasurer.of(context);
    final labelStyle = StatsCardWidget.labelStyle(theme);
    final valueStyle = StatsCardWidget.valueStyle(theme);
    // Horizontal space a card adds around its text: its padding plus the
    // [Card] margin (Material 3 default: 4 per side).
    final chrome = StatsCardWidget.padding.horizontal +
        (theme.cardTheme.margin ?? const EdgeInsets.all(4)).horizontal;

    return LayoutBuilder(
      builder: (context, constraints) {
        final share = constraints.maxWidth / cards.length;
        final fits = cards.every((c) {
          final content = [
            measure.widestWord(c.label, labelStyle),
            measure.width(c.value, valueStyle),
            if (c.subtitle != null)
              measure.widestWord(c.subtitle!, theme.textTheme.bodySmall),
          ].reduce((a, b) => a > b ? a : b);
          return content + chrome <= share;
        });

        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards,
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final c in cards) Expanded(child: c)],
          ),
        );
      },
    );
  }
}
