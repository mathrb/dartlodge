import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../domain/models/game_config.dart';

/// Compact status bar shown below the app header on game boards.
///
/// Displays: `[configLabel] · ROUND x [/ y] [· LEG x/y] | [sum] [dart badges]`
///
/// [configLabel] is game-type specific — e.g. `'501'` for X01 or `'Standard'`
/// for Cricket.
/// [totalRounds] is optional; when null the round denominator is omitted.
/// [currentLegIndex] and [legsToWin] are optional; when absent the leg section
/// is hidden (e.g. practice games have no leg concept).
class GameStatusBarWidget extends StatelessWidget {
  const GameStatusBarWidget({
    required this.configLabel,
    required this.roundInLeg,
    required this.currentTurnDarts,
    this.currentLegIndex,
    this.legsToWin,
    this.totalRounds,
    super.key,
  });

  final String configLabel;
  final int? currentLegIndex;
  final int? legsToWin;
  final int roundInLeg;
  final int? totalRounds;
  final List<String> currentTurnDarts;

  int get _turnSum => currentTurnDarts.isEmpty
      ? 0
      : currentTurnDarts
          .map((s) => Segment.parse(s).scoreValue)
          .fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labelStyle = AppTextStyles.labelSmall.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 1.2,
      fontSize: 10,
    );
    final dot = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
    );

    final turnSum = _turnSum;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(configLabel, style: labelStyle),
          dot,
          Text(
            totalRounds != null
                ? 'ROUND $roundInLeg / $totalRounds'
                : 'ROUND $roundInLeg',
            style: labelStyle,
          ),
          if (currentLegIndex != null && legsToWin != null) ...[
            dot,
            Text('LEG ${currentLegIndex! + 1} / $legsToWin', style: labelStyle),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 1,
              height: 16,
              child: ColoredBox(
                color: cs.outlineVariant.withValues(alpha: 0.2),
              ),
            ),
          ),
          Text(
            '$turnSum',
            style: AppTextStyles.labelMedium.copyWith(
              color: turnSum > 0
                  ? cs.onSurfaceVariant.withValues(alpha: 0.8)
                  : cs.onSurfaceVariant.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 8),
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            SizedBox(
              height: 20,
              child: Center(
                child: currentTurnDarts.length > i
                    ? _DartBadge(segment: currentTurnDarts[i])
                    : Icon(
                        Icons.navigation,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        semanticLabel: 'dart not thrown',
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DartBadge extends StatelessWidget {
  const _DartBadge({required this.segment});

  final String segment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryFixed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: cs.primaryFixed.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        segment,
        style: AppTextStyles.labelMedium.copyWith(
          color: cs.primaryFixed,
        ),
      ),
    );
  }
}
