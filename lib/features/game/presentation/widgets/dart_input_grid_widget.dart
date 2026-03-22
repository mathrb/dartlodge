import 'package:flutter/material.dart';

import '../../../../core/widgets/input_cell_widget.dart';

const _row1 = [20, 19, 18, 17, 16, 15, 14, 13, 12, 11];
const _row2 = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

class DartInputGridWidget extends StatelessWidget {
  const DartInputGridWidget({
    required this.onSegmentTapped,
    this.enabled = true,
    super.key,
  });

  final void Function(String segment) onSegmentTapped;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Row 0: special segments
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InputCellWidget(
              label: 'MISS',
              segment: 'MISS',
              semanticLabel: 'Miss',
              bgColor: cs.surface,
              textColor: cs.onSurface,
              onTap: onSegmentTapped,
              enabled: enabled,
            ),
            InputCellWidget(
              label: 'SB',
              segment: 'SB',
              semanticLabel: 'Single Bull',
              bgColor: cs.surface,
              textColor: cs.onSurface,
              onTap: onSegmentTapped,
              enabled: enabled,
            ),
            InputCellWidget(
              label: 'DB',
              segment: 'DB',
              semanticLabel: 'Double Bull',
              bgColor: cs.surface,
              textColor: cs.onSurface,
              onTap: onSegmentTapped,
              enabled: enabled,
            ),
          ]),
        ),
        const _TierSeparator(),
        // Singles rows
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final n in _row1)
              InputCellWidget(
                label: '$n',
                segment: '$n',
                semanticLabel: 'Single $n',
                bgColor: cs.surface,
                textColor: cs.onSurface,
                onTap: onSegmentTapped,
                enabled: enabled,
              ),
          ]),
        ),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final n in _row2)
              InputCellWidget(
                label: '$n',
                segment: '$n',
                semanticLabel: 'Single $n',
                bgColor: cs.surface,
                textColor: cs.onSurface,
                onTap: onSegmentTapped,
                enabled: enabled,
              ),
          ]),
        ),
        const _TierSeparator(),
        // Doubles rows
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final n in _row1)
              InputCellWidget(
                label: 'D$n',
                segment: 'D$n',
                semanticLabel: 'Double $n',
                bgColor: cs.primaryContainer,
                textColor: cs.onPrimaryContainer,
                dots: 2,
                onTap: onSegmentTapped,
                enabled: enabled,
              ),
          ]),
        ),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final n in _row2)
              InputCellWidget(
                label: 'D$n',
                segment: 'D$n',
                semanticLabel: 'Double $n',
                bgColor: cs.primaryContainer,
                textColor: cs.onPrimaryContainer,
                dots: 2,
                onTap: onSegmentTapped,
                enabled: enabled,
              ),
          ]),
        ),
        const _TierSeparator(),
        // Triples rows
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final n in _row1)
              InputCellWidget(
                label: 'T$n',
                segment: 'T$n',
                semanticLabel: 'Triple $n',
                bgColor: cs.primary,
                textColor: cs.onPrimary,
                dots: 3,
                onTap: onSegmentTapped,
                enabled: enabled,
              ),
          ]),
        ),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final n in _row2)
              InputCellWidget(
                label: 'T$n',
                segment: 'T$n',
                semanticLabel: 'Triple $n',
                bgColor: cs.primary,
                textColor: cs.onPrimary,
                dots: 3,
                onTap: onSegmentTapped,
                enabled: enabled,
              ),
          ]),
        ),
      ],
    );
  }
}

class _TierSeparator extends StatelessWidget {
  const _TierSeparator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 1,
      child: ColoredBox(color: cs.outlineVariant),
    );
  }
}
