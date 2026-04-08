import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
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
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          // Singles → Doubles → Triples (6 equal rows)
          Expanded(
            child: Column(
              children: [
                // Singles (20–11)
                Expanded(
                  child: _NumberRow(
                    numbers: _row1,
                    prefix: '',
                    dots: 0,
                    bgColor: cs.surfaceContainerHighest,
                    textColor: cs.onSurface,
                    onTap: onSegmentTapped,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(height: 4),
                // Singles (10–1)
                Expanded(
                  child: _NumberRow(
                    numbers: _row2,
                    prefix: '',
                    dots: 0,
                    bgColor: cs.surfaceContainerHighest,
                    textColor: cs.onSurface,
                    onTap: onSegmentTapped,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(height: 4),
                // Doubles (D20–D11)
                Expanded(
                  child: _NumberRow(
                    numbers: _row1,
                    prefix: 'D',
                    dots: 2,
                    bgColor: cs.surfaceContainerLow,
                    textColor: cs.onSurfaceVariant,
                    dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                    onTap: onSegmentTapped,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(height: 4),
                // Doubles (D10–D1)
                Expanded(
                  child: _NumberRow(
                    numbers: _row2,
                    prefix: 'D',
                    dots: 2,
                    bgColor: cs.surfaceContainerLow,
                    textColor: cs.onSurfaceVariant,
                    dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                    onTap: onSegmentTapped,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(height: 4),
                // Triples (T20–T11)
                Expanded(
                  child: _NumberRow(
                    numbers: _row1,
                    prefix: 'T',
                    dots: 3,
                    bgColor: cs.surfaceContainer,
                    textColor: cs.onSurfaceVariant,
                    dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                    onTap: onSegmentTapped,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(height: 4),
                // Triples (T10–T1)
                Expanded(
                  child: _NumberRow(
                    numbers: _row2,
                    prefix: 'T',
                    dots: 3,
                    bgColor: cs.surfaceContainer,
                    textColor: cs.onSurfaceVariant,
                    dotColor: cs.primaryFixed.withValues(alpha: 0.7),
                    onTap: onSegmentTapped,
                    enabled: enabled,
                  ),
                ),
              ],
            ),
          ),
          // Special buttons row
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Miss
                Expanded(
                  flex: 2,
                  child: Semantics(
                    label: 'Miss',
                    child: InkWell(
                      onTap: enabled ? () => onSegmentTapped('MISS') : null,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      splashColor: AppTheme.kineticSplashColor,
                      highlightColor: AppTheme.kineticSplashColor,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'MISS',
                          style: AppTextStyles.segmentButton
                              .copyWith(color: cs.onSurface),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Single Bull (25)
                Expanded(
                  flex: 3,
                  child: Semantics(
                    label: 'Single Bull',
                    child: InkWell(
                      onTap: enabled ? () => onSegmentTapped('SB') : null,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      splashColor: AppTheme.kineticSplashColor,
                      highlightColor: AppTheme.kineticSplashColor,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '25',
                              style: AppTextStyles.segmentButton
                                  .copyWith(color: cs.onSurface),
                            ),
                            Text(
                              'BULL',
                              style: AppTextStyles.multiplierLabel.copyWith(
                                color: cs.primaryFixed.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Double Bull (50)
                Expanded(
                  flex: 3,
                  child: Semantics(
                    label: 'Double Bull',
                    child: InkWell(
                      onTap: enabled ? () => onSegmentTapped('DB') : null,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      splashColor: AppTheme.kineticSplashColor,
                      highlightColor: AppTheme.kineticSplashColor,
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.primaryFixed,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '50',
                              style: AppTextStyles.segmentButton
                                  .copyWith(color: AppColors.onPrimaryFixed),
                            ),
                            Text(
                              'BULL',
                              style: AppTextStyles.multiplierLabel.copyWith(
                                color: AppColors.onPrimaryFixed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.numbers,
    required this.prefix,
    required this.dots,
    required this.bgColor,
    required this.textColor,
    required this.onTap,
    required this.enabled,
    this.dotColor,
  });

  final List<int> numbers;
  final String prefix;
  final int dots;
  final Color bgColor;
  final Color textColor;
  final Color? dotColor;
  final void Function(String) onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < numbers.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _GridCell(
              label: '${numbers[i]}',
              segment: '$prefix${numbers[i]}',
              semanticLabel:
                  '${prefix.isEmpty ? 'Single' : prefix == 'D' ? 'Double' : 'Triple'} ${numbers[i]}',
              bgColor: bgColor,
              textColor: textColor,
              dots: dots,
              dotColor: dotColor ?? textColor,
              onTap: onTap,
              enabled: enabled,
            ),
          ),
        ],
      ],
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
    required this.dotColor,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final String segment;
  final String semanticLabel;
  final Color bgColor;
  final Color textColor;
  final int dots;
  final Color dotColor;
  final void Function(String) onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: InkWell(
        onTap: enabled ? () => onTap(segment) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        splashColor: AppTheme.kineticSplashColor,
        highlightColor: AppTheme.kineticSplashColor,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.segmentButton.copyWith(color: textColor),
              ),
              if (dots > 0) ...[
                const SizedBox(height: 4),
                _DotRow(count: dots, color: dotColor),
              ],
            ],
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
