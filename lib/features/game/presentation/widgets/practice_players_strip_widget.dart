import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';

/// Compact strip of the non-active players' progress, shown in the camera-first
/// Practice layout (#445 / epic #440) for the multi-player variants (Around the
/// Clock, Shanghai). The active player's target is the hero metric; this keeps
/// everyone else visible at a glance.
///
/// Game-state-free: the board passes a pre-filtered list of `(name, value)` for
/// the players whose turn it is NOT — `value` is the per-variant progress (ATC
/// current target, Shanghai score). Practice-specific (the X01 strip is left
/// untouched).
class PracticePlayersStripWidget extends StatelessWidget {
  const PracticePlayersStripWidget({required this.players, super.key});

  /// The non-active competitors: display name and their progress value.
  final List<({String name, int value})> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in players)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: cs.outlineVariant
                      .withValues(alpha: AppTheme.opacityGhostBorderLight),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name.toUpperCase(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.value}',
                    maxLines: 1,
                    style: AppTextStyles.scoreSmall.copyWith(
                      color: cs.onSurfaceVariant,
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
