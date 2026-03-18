import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RoundSumLabel(sum: _roundSum),
          const SizedBox(width: 12),
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
      style: AppTextStyles.headingSmall.copyWith(fontSize: 24, color: cs.primary),
    );
  }
}

class _DartChip extends StatelessWidget {
  const _DartChip({required this.segment});

  final String segment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        segment,
        style: AppTextStyles.segmentButton.copyWith(color: cs.onSurface),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SvgPicture.asset(
        'assets/icons/dart_placeholder.svg',
        width: 36,
        height: 36,
        colorFilter: ColorFilter.mode(cs.outline, BlendMode.srcIn),
      ),
    );
  }
}
