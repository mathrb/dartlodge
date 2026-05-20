import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';
import '../utils/app_theme.dart';

/// One row in the right-hand side column of a [PostGameHeroCard].
class PostGameHeroStat {
  const PostGameHeroStat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;

  /// Renders the value in the card's accent color (primary on bright cards,
  /// neutral on muted cards). Off by default — additional stats below the
  /// emphasized one are rendered in onSurface.
  final bool emphasize;
}

/// Reusable post-game result card — rounded container with an accent left
/// border, a headline / subline on the left, and an optional column of side
/// stats on the right. Extracted from `GameSummarySectionWidget`'s former
/// private `_WinnerCard` so practice drills and Shanghai can share the
/// chrome (#230).
class PostGameHeroCard extends StatelessWidget {
  const PostGameHeroCard({
    super.key,
    required this.headline,
    this.badge,
    this.badgeIcon,
    this.subline,
    this.sideStats = const [],
    this.accentColor,
    this.backgroundIcon,
    this.muted = false,
  });

  /// Big headline text (uppercased by this widget). For winner cards this is
  /// the competitor name; for drills it can be a status string like
  /// `Checked out!` or a numeric headline like `170 → 0`.
  final String headline;

  /// Optional pill above the headline (e.g. `WINNER`). When null the pill
  /// row is omitted.
  final String? badge;
  final IconData? badgeIcon;

  /// Optional small caption below the headline (e.g. `1 LEG WON`).
  final String? subline;

  final List<PostGameHeroStat> sideStats;

  /// Override for the left border + badge background + emphasized stat
  /// color. Defaults to `cs.primaryFixed` (or `cs.outlineVariant` when
  /// [muted] is true).
  final Color? accentColor;

  /// Decorative outline icon in the top-right of the headline area
  /// (e.g. `Icons.emoji_events` for winners). Omitted when null.
  final IconData? backgroundIcon;

  /// When true the card uses neutral colors throughout — used for
  /// non-celebratory outcomes like Bob's 27 busted-to-zero.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent =
        accentColor ?? (muted ? cs.outlineVariant : cs.primaryFixed);
    final onAccent = muted ? cs.onSurface : cs.onPrimaryFixed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border(left: BorderSide(color: accent, width: 4)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      if (backgroundIcon != null)
                        Positioned(
                          right: -24,
                          top: -24,
                          child: Icon(
                            backgroundIcon,
                            size: 120,
                            color: cs.onSurface.withValues(alpha: 0.04),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (badge != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    badge!,
                                    style: tt.labelSmall?.copyWith(
                                      color: onAccent,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (badgeIcon != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(badgeIcon, color: accent, size: 20),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            headline.toUpperCase(),
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (subline != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subline!,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (sideStats.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    border: Border(
                      left: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < sideStats.length; i++) ...[
                        if (i > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            width: 48,
                            color: cs.outlineVariant.withValues(
                                alpha: AppTheme.opacityGhostBorderStrong),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _SideStat(
                          stat: sideStats[i],
                          accent: accent,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideStat extends StatelessWidget {
  const _SideStat({required this.stat, required this.accent});

  final PostGameHeroStat stat;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          stat.label,
          style: tt.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.value,
          style: AppTextStyles.scoreMedium.copyWith(
            color: stat.emphasize ? accent : cs.onSurface,
          ),
        ),
      ],
    );
  }
}
