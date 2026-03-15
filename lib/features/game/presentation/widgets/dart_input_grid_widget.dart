import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';

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
            _GridCell(
              label: 'MISS',
              segment: 'MISS',
              semanticLabel: 'Miss',
              bgColor: cs.surface,
              textColor: cs.onSurface,
              dots: 0,
              onTap: onSegmentTapped,
              enabled: enabled,
            ),
            _GridCell(
              label: 'SB',
              segment: 'SB',
              semanticLabel: 'Single Bull',
              bgColor: cs.surface,
              textColor: cs.onSurface,
              dots: 0,
              onTap: onSegmentTapped,
              enabled: enabled,
            ),
            _GridCell(
              label: 'DB',
              segment: 'DB',
              semanticLabel: 'Double Bull',
              bgColor: cs.surface,
              textColor: cs.onSurface,
              dots: 0,
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
                  _GridCell(
                    label: '$n',
                    segment: '$n',
                    semanticLabel: 'Single $n',
                    bgColor: cs.surface,
                    textColor: cs.onSurface,
                    dots: 0,
                    onTap: onSegmentTapped,
                    enabled: enabled,
                  ),
              ]),
            ),
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final n in _row2)
                  _GridCell(
                    label: '$n',
                    segment: '$n',
                    semanticLabel: 'Single $n',
                    bgColor: cs.surface,
                    textColor: cs.onSurface,
                    dots: 0,
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
                  _GridCell(
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
                  _GridCell(
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
                  _GridCell(
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
                  _GridCell(
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

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.label,
    required this.segment,
    required this.semanticLabel,
    required this.bgColor,
    required this.textColor,
    required this.dots,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final String segment;
  final String semanticLabel;
  final Color bgColor;
  final Color textColor;
  final int dots;
  final void Function(String) onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        label: semanticLabel,
        child: InkWell(
          onTap: enabled ? () => onTap(segment) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                right: BorderSide(color: cs.outline, width: 1),
                bottom: BorderSide(color: cs.outline, width: 1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  label,
                  style: AppTextStyles.segmentButton.copyWith(color: textColor),
                ),
                if (dots > 0) _DotRow(count: dots, color: textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  const _DotRow({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
