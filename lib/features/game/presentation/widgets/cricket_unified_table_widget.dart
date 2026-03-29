import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/app_theme.dart';
import '../../domain/models/game_state.dart';

// ── File-private helpers ──────────────────────────────────────────────────────

String _singleSegment(int n) => n == 25 ? 'SB' : '$n';
String _doubleSegment(int n) => n == 25 ? 'DB' : 'D$n';
String _tripleSegment(int n) => 'T$n';
String _cricketKey(int n) => n == 25 ? 'Bull' : '$n';

bool _isRowClosed(int n, GameState gs) =>
    gs.competitors.every((c) => (c.marksPerNumber[_cricketKey(n)] ?? 0) >= 3);

int _marksForPlayer(CompetitorState c, int n) =>
    c.marksPerNumber[_cricketKey(n)] ?? 0;

// ── Public widget ─────────────────────────────────────────────────────────────

class CricketUnifiedTableWidget extends StatelessWidget {
  const CricketUnifiedTableWidget({
    super.key,
    required this.gameState,
    required this.onSegmentTapped,
    required this.onMiss,
  });

  final GameState gameState;
  final ValueChanged<String> onSegmentTapped;
  final VoidCallback onMiss;

  static const _numbers = [20, 19, 18, 17, 16, 15, 25];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CricketHeaderRow(
          gameState: gameState,
          onMiss: onMiss,
        ),
        for (final n in _numbers)
          Expanded(
            child: _CricketNumberRow(
              target: n,
              competitors: gameState.competitors,
              currentTurnIndex: gameState.currentTurnIndex,
              isRowClosed: _isRowClosed(n, gameState),
              onSegmentTapped: onSegmentTapped,
            ),
          ),
      ],
    );
  }
}

// ── Header row ────────────────────────────────────────────────────────────────

class _CricketHeaderRow extends StatelessWidget {
  const _CricketHeaderRow({
    required this.gameState,
    required this.onMiss,
  });

  final GameState gameState;
  final VoidCallback onMiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < gameState.competitors.length; i++)
              Expanded(
                flex: 3,
                child: _PlayerHeaderCell(
                  competitor: gameState.competitors[i],
                  isActive: i == gameState.currentTurnIndex,
                  currentRoundInLeg: gameState.currentRoundInLeg,
                ),
              ),
            Expanded(
              flex: 3,
              child: _MissCell(onTap: onMiss),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHeaderCell extends StatelessWidget {
  const _PlayerHeaderCell({
    required this.competitor,
    required this.isActive,
    required this.currentRoundInLeg,
  });

  final CompetitorState competitor;
  final bool isActive;
  final int currentRoundInLeg;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final totalMarks = competitor.marksPerNumber.values
        .map((v) => v.clamp(0, 3))
        .fold(0, (a, b) => a + b);
    final mpr =
        currentRoundInLeg > 0 ? totalMarks / currentRoundInLeg : 0.0;

    final cell = Container(
      decoration: BoxDecoration(
        color: isActive ? cs.primaryContainer.withValues(alpha: 0.10) : null,
        border: Border(
          left: BorderSide(
            color: isActive
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.15),
            width: isActive ? 4.0 : 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${competitor.score}',
            style: AppTextStyles.scoreMedium(context).copyWith(
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            competitor.name.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(
              letterSpacing: 2.0,
              fontWeight: FontWeight.w800,
              color: isActive ? cs.primary : cs.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MPR',
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 8,
                  color: isActive
                      ? cs.primary.withValues(alpha: 0.60)
                      : cs.onSurfaceVariant.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                mpr.toStringAsFixed(1),
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isActive) return Opacity(opacity: 0.60, child: cell);
    return cell;
  }
}

class _MissCell extends StatelessWidget {
  const _MissCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      splashColor: AppTheme.kineticSplashColor,
      highlightColor: AppTheme.kineticSplashColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              color: cs.error,
              size: 18,
              semanticLabel: '',
            ),
            const SizedBox(width: 8),
            Text(
              'MISS',
              style: AppTextStyles.labelLarge.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Number row ────────────────────────────────────────────────────────────────

class _CricketNumberRow extends StatelessWidget {
  const _CricketNumberRow({
    required this.target,
    required this.competitors,
    required this.currentTurnIndex,
    required this.isRowClosed,
    required this.onSegmentTapped,
  });

  final int target;
  final List<CompetitorState> competitors;
  final int currentTurnIndex;
  final bool isRowClosed;
  final ValueChanged<String> onSegmentTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isRowClosed
            ? cs.surfaceContainerHighest.withValues(alpha: 0.38)
            : null,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Player mark columns
          for (var i = 0; i < competitors.length; i++)
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: i == currentTurnIndex
                      ? cs.primaryContainer.withValues(alpha: 0.05)
                      : null,
                  border: Border(
                    right: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: _MarkCell(
                  marks: _marksForPlayer(competitors[i], target),
                  isActivePlayer: i == currentTurnIndex,
                ),
              ),
            ),
          // Input cells
          if (target != 25) ...[
            Expanded(
              flex: 1,
              child: _InputCell(
                displayLabel: '$target',
                dotCount: 1,
                semanticLabel: 'Single $target',
                onTap: isRowClosed
                    ? null
                    : () => onSegmentTapped(_singleSegment(target)),
                isRowClosed: isRowClosed,
                hasBorderRight: true,
              ),
            ),
            Expanded(
              flex: 1,
              child: _InputCell(
                displayLabel: '$target',
                dotCount: 2,
                semanticLabel: 'Double $target',
                onTap: isRowClosed
                    ? null
                    : () => onSegmentTapped(_doubleSegment(target)),
                isRowClosed: isRowClosed,
                hasBorderRight: true,
              ),
            ),
            Expanded(
              flex: 1,
              child: _InputCell(
                displayLabel: '$target',
                dotCount: 3,
                semanticLabel: 'Triple $target',
                onTap: isRowClosed
                    ? null
                    : () => onSegmentTapped(_tripleSegment(target)),
                isRowClosed: isRowClosed,
                hasBorderRight: false,
              ),
            ),
          ] else ...[
            // Bull row: SB (flex 1) + DB (flex 2)
            Expanded(
              flex: 1,
              child: _InputCell(
                displayLabel: 'SB',
                dotCount: 1,
                semanticLabel: 'Single Bull',
                onTap: isRowClosed ? null : () => onSegmentTapped('SB'),
                isRowClosed: isRowClosed,
                hasBorderRight: true,
              ),
            ),
            Expanded(
              flex: 2,
              child: _InputCell(
                displayLabel: 'DB',
                dotCount: 2,
                semanticLabel: 'Double Bull',
                onTap: isRowClosed ? null : () => onSegmentTapped('DB'),
                isRowClosed: isRowClosed,
                hasBorderRight: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Mark cell ─────────────────────────────────────────────────────────────────

class _MarkCell extends StatelessWidget {
  const _MarkCell({required this.marks, required this.isActivePlayer});

  final int marks;
  final bool isActivePlayer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color color;
    if (marks == 0) {
      color = cs.onSurfaceVariant.withValues(alpha: 0.20);
    } else if (marks >= 3) {
      color = cs.primaryFixed;
    } else {
      // 1–2 marks
      color = isActivePlayer
          ? cs.primary
          : cs.onSurface.withValues(alpha: 0.30);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 28,
          height: 28,
          child: CustomPaint(
            painter: _MarkPainter(marks: marks, color: color),
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({required this.marks, required this.color});

  final int marks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final arm = size.width * 0.38;

    if (marks == 0) {
      canvas.drawLine(
        Offset(cx - arm, cy),
        Offset(cx + arm, cy),
        paint..strokeWidth = 2.0,
      );
      return;
    }

    // Diagonal arm length for slash/X marks (same for all mark counts)
    final armDiag = arm / sqrt(2) * 1.15;

    if (marks >= 3) {
      canvas.drawCircle(Offset(cx, cy), size.width * 0.44, paint);
    }

    if (marks >= 2) {
      canvas.drawLine(
          Offset(cx - armDiag, cy + armDiag), Offset(cx + armDiag, cy - armDiag), paint);
      canvas.drawLine(
          Offset(cx - armDiag, cy - armDiag), Offset(cx + armDiag, cy + armDiag), paint);
    } else {
      canvas.drawLine(
          Offset(cx - armDiag, cy + armDiag), Offset(cx + armDiag, cy - armDiag), paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.marks != marks || old.color != color;
}

// ── Input cell ────────────────────────────────────────────────────────────────

class _InputCell extends StatelessWidget {
  const _InputCell({
    required this.displayLabel,
    required this.dotCount,
    required this.semanticLabel,
    required this.onTap,
    required this.isRowClosed,
    required this.hasBorderRight,
  });

  final String displayLabel;
  final int dotCount;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool isRowClosed;
  final bool hasBorderRight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      child: Tooltip(
        message: isRowClosed ? 'Number already closed' : '',
        child: InkWell(
          onTap: onTap,
          splashColor: AppTheme.kineticSplashColor,
          highlightColor: AppTheme.kineticSplashColor,
          child: Container(
            decoration: hasBorderRight
                ? BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.10),
                      ),
                    ),
                  )
                : null,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayLabel,
                  style: AppTextStyles.segmentButton.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    dotCount,
                    (_) => Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.40),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
