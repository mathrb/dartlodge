import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import 'cricket_mark_painter.dart';

/// Per-player row data for [CricketMarksStripWidget]. [marks] is aligned to the
/// widget's `targets` list (one mark count per target).
typedef CricketMarksRow = ({
  String name,
  List<int> marks,
  int score,
  bool isActive,
  String mpr,
});

/// At-distance marks grid shown in the camera-first Cricket layout (#444,
/// enlarged for the oche in #479): the player reads it from ~2.4 m, so marks
/// are painted glyphs with thick strokes ([CricketMarkPainter]) — at distance
/// it is stroke weight and colour that carry legibility, not font size.
///
/// Layout is flex-derived (no horizontal scroll): the 7 target columns share
/// the width remaining after the fixed name and score columns, so the grid
/// fits any phone width by construction.
///
/// Colour semantics: closed (3+) = `primaryFixed`; 1–2 marks = `onSurface`;
/// unmarked = ghost dot. A **dead** target (closed by every player) renders
/// its header struck-through and all its marks greyed — at a glance, nowhere
/// useful to aim.
///
/// Game-state-free: the board resolves `targets` (display order, 25 = Bull)
/// and each player's per-target [marks] / score, so the widget is testable in
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
  static const double _scoreWidth = 60;

  int _marksAt(CricketMarksRow r, int i) =>
      i < r.marks.length ? r.marks[i] : 0;

  /// A target is dead when every player has closed it — nothing left to score.
  bool _isDead(int i) => rows.every((r) => _marksAt(r, i) >= 3);

  /// Accessibility / test handle for a mark cell.
  static String semanticsForMarks(int marks) => switch (marks) {
        <= 0 => 'no marks',
        1 => '1 mark',
        2 => '2 marks',
        _ => 'closed',
      };

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    // Compress rows (and glyphs) as the player count grows so the grid keeps
    // fitting above the dart band + camera vignette.
    final compact = rows.length > 2;
    final rowHeight = compact ? 40.0 : 56.0;
    final glyphSize = compact ? 26.0 : 34.0;

    Widget targetCell(Widget child) =>
        Expanded(child: Center(child: child));

    final header = SizedBox(
      height: 28,
      child: Row(
        children: [
          const SizedBox(width: _nameWidth),
          for (var i = 0; i < targets.length; i++)
            targetCell(
              Text(
                targets[i] == 25 ? 'B' : '${targets[i]}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: _isDead(i)
                      ? cs.onSurfaceVariant
                          .withValues(alpha: AppTheme.opacityDisabled)
                      : cs.onSurfaceVariant,
                  decoration: _isDead(i) ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          if (showScore)
            SizedBox(
              width: _scoreWidth,
              child: Center(
                child: Text(
                  'SC',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Color markColor(int marks, bool dead) {
      if (dead) {
        // Greyed even when closed: the whole column is out of play.
        return cs.onSurfaceVariant.withValues(alpha: AppTheme.opacityDisabled);
      }
      return switch (marks) {
        <= 0 => cs.onSurfaceVariant
            .withValues(alpha: AppTheme.opacityGhostBorderStrong),
        1 || 2 => cs.onSurface,
        _ => cs.primaryFixed,
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          for (final r in rows)
            Container(
              height: rowHeight,
              decoration: BoxDecoration(
                color: r.isActive ? cs.surfaceContainerLow : null,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: _nameWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        // Live MPR (#696) under the name — small, so the marks
                        // grid stays dominant; same column as the manual table's
                        // MPR (which pairs it with the name).
                        Text(
                          'MPR ${r.mpr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < targets.length; i++)
                    targetCell(
                      Semantics(
                        label: semanticsForMarks(_marksAt(r, i)),
                        child: SizedBox(
                          width: glyphSize,
                          height: glyphSize,
                          child: CustomPaint(
                            painter: CricketMarkPainter(
                              marks: _marksAt(r, i),
                              color: markColor(_marksAt(r, i), _isDead(i)),
                              strokeWidth: 4,
                              zeroAsDot: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showScore)
                    SizedBox(
                      width: _scoreWidth,
                      child: Center(
                        child: Text(
                          '${r.score}',
                          maxLines: 1,
                          // Inactive players dimmer than the active one
                          // (DESIGN_SYSTEM §2.6 inactiveScore).
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: r.isActive
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
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
