import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';

/// Compact strip of the non-active players' remaining scores, shown in the
/// camera-first X01 layout (#443 / epic #440) where the active player's score
/// is the hero metric. Keeps every opponent visible at a glance without the
/// full multi-card score section.
///
/// Game-state-free: the board passes a pre-filtered list of `(name, score)` for
/// the players whose turn it is NOT, so the widget is testable in isolation.
class X01OtherPlayersStripWidget extends StatelessWidget {
  const X01OtherPlayersStripWidget({required this.players, super.key});

  /// The non-active competitors: their display name and remaining score.
  final List<({String name, int score})> players;

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
                    '${p.score}',
                    maxLines: 1,
                    // Inactive players: the score-tier token (DESIGN_SYSTEM §3.2)
                    // in the inactive `onSurfaceVariant` colour, dimmer than the
                    // active hero, preserving the active/inactive hierarchy.
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
