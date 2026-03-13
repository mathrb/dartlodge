import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../domain/models/game_config.dart';

class DartIndicatorWidget extends StatelessWidget {
  const DartIndicatorWidget({
    required this.currentTurnDarts,
    super.key,
  });

  /// 0–3 canonical segment strings (e.g. 'T20', 'D5', '19', 'SB', 'MISS')
  final List<String> currentTurnDarts;

  int get _roundSum => currentTurnDarts
      .map((s) => Segment.parse(s).scoreValue)
      .fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          _RoundSumLabel(sum: _roundSum),
          const SizedBox(width: 8),
          ...List.generate(
            3,
            (i) => i < currentTurnDarts.length
                ? _DartChip(segment: currentTurnDarts[i])
                : const _EmptySlot(),
          ),
        ],
      ),
    );
  }
}

class _RoundSumLabel extends StatelessWidget {
  const _RoundSumLabel({required this.sum});

  final int sum;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      '$sum',
      style: AppTextStyles.headingSmall.copyWith(color: cs.primary),
    );
  }
}

class _DartChip extends StatelessWidget {
  const _DartChip({required this.segment});

  final String segment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        segment,
        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cs.outline, width: 1),
      ),
    );
  }
}
