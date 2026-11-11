import 'package:flutter/material.dart';

import '../utils/app_text_styles.dart';
import '../utils/app_theme.dart';
import 'text_measurer.dart';

/// One row in the right-hand side column of a [PostGameHeroCard].
class PostGameHeroStat {
  const PostGameHeroStat({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.danger = false,
  });

  final String label;
  final String value;

  /// Renders the value in the card's accent color (primary on bright cards,
  /// neutral on muted cards). Off by default — additional stats below the
  /// emphasized one are rendered in onSurface.
  final bool emphasize;

  /// Renders the value in `colorScheme.error`. Used by Bob's 27 to flag a
  /// negative final score so the post-game card matches the in-game error
  /// styling instead of falsely celebrating it in the accent colour (#339).
  /// Takes precedence over [emphasize] when both are set.
  final bool danger;
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

  static const double _padding = 20;
  static const double _accentBorder = 4;
  static const double _pillHorizontalPadding = 12;
  static const double _badgeIconGap = 8;
  static const double _badgeIconSize = 20;

  static TextStyle _headlineStyle(ColorScheme cs) => AppTextStyles.headlineSmall
      .copyWith(color: cs.onSurface, fontWeight: FontWeight.w900);

  static TextStyle? _badgeStyle(TextTheme tt, Color onAccent) =>
      tt.labelSmall?.copyWith(color: onAccent, fontWeight: FontWeight.w900);

  static TextStyle? _sublineStyle(TextTheme tt, ColorScheme cs) =>
      tt.bodySmall?.copyWith(
        color: cs.onSurfaceVariant,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final accent = accentColor ?? (muted ? cs.outlineVariant : cs.primaryFixed);
    final onAccent = muted ? cs.onSurface : cs.onPrimaryFixed;

    final header = _buildHeader(cs, tt, accent, onAccent);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border(
            left: BorderSide(color: accent, width: _accentBorder),
          ),
        ),
        child: sideStats.isEmpty
            ? SizedBox(width: double.infinity, child: header)
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Side by side only while the header column keeps room for
                  // its widest word and the stats column for its numerals.
                  // Otherwise (large system text, long names) the stats move
                  // below the header instead of squeezing the name into
                  // mid-word breaks (DESIGN_SYSTEM §13).
                  final measure = TextMeasurer.of(context);
                  // The Container already deducts the accent border from
                  // these constraints; the + 1 is the stats column's own
                  // left border.
                  final needed =
                      _headerMinWidth(measure, cs, tt, onAccent) +
                      _sideColumnWidth(measure, cs, tt) +
                      1;
                  return needed <= constraints.maxWidth
                      ? _buildSideBySide(cs, accent, header)
                      : _buildStacked(cs, accent, header);
                },
              ),
      ),
    );
  }

  Widget _buildHeader(
    ColorScheme cs,
    TextTheme tt,
    Color accent,
    Color onAccent,
  ) {
    return Padding(
      padding: const EdgeInsets.all(_padding),
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
                        horizontal: _pillHorizontalPadding,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(badge!, style: _badgeStyle(tt, onAccent)),
                    ),
                    if (badgeIcon != null) ...[
                      const SizedBox(width: _badgeIconGap),
                      Icon(badgeIcon, color: accent, size: _badgeIconSize),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
              ],
              // Headlines wrap at word boundaries only: the layout choice in
              // [build] guarantees the column is at least as wide as the
              // widest word. Up to three lines fit multi-word status
              // headlines like "Not checked out"; the ellipsis is only a
              // last-resort overflow guard (#341).
              Text(
                headline.toUpperCase(),
                style: _headlineStyle(cs),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (subline != null) ...[
                const SizedBox(height: 4),
                Text(subline!, style: _sublineStyle(tt, cs)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySide(ColorScheme cs, Color accent, Widget header) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: header),
          Container(
            padding: const EdgeInsets.all(_padding),
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
                        alpha: AppTheme.opacityGhostBorderStrong,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SideStat(stat: sideStats[i], accent: accent),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStacked(ColorScheme cs, Color accent, Widget header) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Container(
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 24,
            runSpacing: 16,
            children: [
              for (final stat in sideStats)
                _SideStat(stat: stat, accent: accent),
            ],
          ),
        ),
      ],
    );
  }

  /// Narrowest header column (padding included) that fits the pill on one
  /// line and the widest word of the headline and subline.
  double _headerMinWidth(
    TextMeasurer measure,
    ColorScheme cs,
    TextTheme tt,
    Color onAccent,
  ) {
    var content = measure.widestWord(
      headline.toUpperCase(),
      _headlineStyle(cs),
    );
    if (subline != null) {
      final w = measure.widestWord(subline!, _sublineStyle(tt, cs));
      if (w > content) content = w;
    }
    if (badge != null) {
      var w =
          measure.width(badge!, _badgeStyle(tt, onAccent)) +
          2 * _pillHorizontalPadding;
      if (badgeIcon != null) w += _badgeIconGap + _badgeIconSize;
      if (w > content) content = w;
    }
    return content + 2 * _padding;
  }

  /// Width the side stats column takes when laid out at its natural size.
  double _sideColumnWidth(TextMeasurer measure, ColorScheme cs, TextTheme tt) {
    var content = 48.0; // divider
    for (final stat in sideStats) {
      final label = measure.width(stat.label, _SideStat.labelStyle(tt, cs));
      final value = measure.width(stat.value, _SideStat.valueStyle);
      if (label > content) content = label;
      if (value > content) content = value;
    }
    return content + 2 * _padding;
  }
}

class _SideStat extends StatelessWidget {
  const _SideStat({required this.stat, required this.accent});

  final PostGameHeroStat stat;
  final Color accent;

  static TextStyle? labelStyle(TextTheme tt, ColorScheme cs) =>
      tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 1.5);

  static TextStyle get valueStyle => AppTextStyles.scoreMedium;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(stat.label, style: labelStyle(tt, cs)),
        const SizedBox(height: 4),
        Text(
          stat.value,
          style: valueStyle.copyWith(
            color: stat.danger
                ? cs.error
                : (stat.emphasize ? accent : cs.onSurface),
          ),
        ),
      ],
    );
  }
}
