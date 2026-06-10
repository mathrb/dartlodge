import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';

/// Per-player row data for [CricketMarksStripWidget]. [marks] is aligned to the
/// widget's `targets` list (one mark count per target).
typedef CricketMarksRow = ({
  String name,
  List<int> marks,
  int score,
  bool isActive,
});

/// Compact marks grid shown in the camera-first Cricket layout (#444 / epic
/// #440), where the full `CricketUnifiedTableWidget` is replaced by the camera.
/// Keeps every player's marks + score visible at a glance above the camera.
///
/// Game-state-free: the board resolves `targets` (display order, 25 = Bull) and
/// each player's per-target [marks] / score, so the widget is testable in
/// isolation.
class CricketMarksStripWidget extends StatelessWidget {
  const CricketMarksStripWidget({
    required this.targets,
    required this.rows,
    this.showScore = true,
    super.key,
  });

  /// Targets in display order; 25 renders as the Bull column (`B`).
  final List<int> targets;

  /// One entry per competitor.
  final List<CricketMarksRow> rows;

  /// Whether to render the trailing score column (false for the no-score
  /// variant, which has no score).
  final bool showScore;

  static const double _nameWidth = 68;
  static const double _markWidth = 22;
  static const double _scoreWidth = 44;

  /// Compact mark glyph: 0 unmarked, 1 slash, 2 cross, 3+ closed.
  static String _glyph(int marks) => switch (marks) {
        <= 0 => '·',
        1 => '/',
        2 => 'X',
        _ => '⊗',
      };

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    Widget cell(double width, Widget child, {Alignment align = Alignment.center}) =>
        SizedBox(width: width, child: Align(alignment: align, child: child));

    final headerStyle = AppTextStyles.labelSmall.copyWith(
      color: cs.onSurfaceVariant,
      letterSpacing: 0.5,
    );

    final header = Row(
      children: [
        cell(_nameWidth, const SizedBox.shrink()),
        for (final t in targets)
          cell(
            _markWidth,
            Text(t == 25 ? 'B' : '$t', style: headerStyle),
          ),
        if (showScore)
          cell(_scoreWidth, Text('SC', style: headerStyle)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            for (final r in rows)
              Container(
                decoration: BoxDecoration(
                  color: r.isActive ? cs.surfaceContainerLow : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    cell(
                      _nameWidth,
                      Text(
                        r.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: r.isActive
                              ? cs.primaryFixed
                              : cs.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      align: Alignment.centerLeft,
                    ),
                    for (var i = 0; i < targets.length; i++)
                      cell(
                        _markWidth,
                        Text(
                          _glyph(i < r.marks.length ? r.marks[i] : 0),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: (i < r.marks.length ? r.marks[i] : 0) > 0
                                ? cs.onSurface
                                : cs.onSurfaceVariant
                                    .withValues(alpha: AppTheme.opacityGhostBorderStrong),
                          ),
                        ),
                      ),
                    if (showScore)
                      cell(
                        _scoreWidth,
                        Text(
                          '${r.score}',
                          maxLines: 1,
                          // Inactive players dimmer than the active one
                          // (DESIGN_SYSTEM §2.6 inactiveScore), matching the
                          // unified table's active/inactive hierarchy.
                          style: AppTextStyles.labelLarge.copyWith(
                            color: r.isActive
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
