import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
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
    required this.onUndo,
    required this.onNextPlayer,
  });

  final GameState gameState;
  final ValueChanged<String> onSegmentTapped;
  final VoidCallback onMiss;
  final VoidCallback onUndo;
  final VoidCallback onNextPlayer;

  static const _numbers = [20, 19, 18, 17, 16, 15, 25];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CricketHeaderRow(
          gameState: gameState,
          onMiss: onMiss,
          onUndo: onUndo,
        ),
        for (final n in _numbers)
          _CricketNumberRow(
            target: n,
            competitors: gameState.competitors,
            isRowClosed: _isRowClosed(n, gameState),
            dartsThrownInTurn: gameState.dartsThrownInTurn,
            onSegmentTapped: onSegmentTapped,
          ),
        _CricketFooterRow(
          dartsThrownInTurn: gameState.dartsThrownInTurn,
          onNextPlayer: onNextPlayer,
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
    required this.onUndo,
  });

  final GameState gameState;
  final VoidCallback onMiss;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < gameState.competitors.length; i++)
            Expanded(
              child: _PlayerHeaderCell(
                competitor: gameState.competitors[i],
                isActive: i == gameState.currentTurnIndex,
              ),
            ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: cs.surface,
              side: BorderSide(color: cs.outline),
            ),
            onPressed: onMiss,
            child: const Text('MISS'),
          ),
          Tooltip(
            message:
                gameState.dartsThrownInTurn == 0 ? 'No darts to undo' : '',
            child: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: gameState.dartsThrownInTurn > 0 ? onUndo : null,
            ),
          ),
          // Blank spacer matching triple column width
          const SizedBox(width: 56),
        ],
      ),
    );
  }
}

class _PlayerHeaderCell extends StatelessWidget {
  const _PlayerHeaderCell({
    required this.competitor,
    required this.isActive,
  });

  final CompetitorState competitor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: isActive ? cs.primary.withValues(alpha: 0.10) : null,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            '${competitor.score}',
            style: AppTextStyles.scoreSmall(context).copyWith(
              color: isActive ? cs.onSurface : AppColors.inactiveScore,
            ),
          ),
          Text(
            competitor.name.toUpperCase(),
            style: AppTextStyles.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Number row ────────────────────────────────────────────────────────────────

class _CricketNumberRow extends StatelessWidget {
  const _CricketNumberRow({
    required this.target,
    required this.competitors,
    required this.isRowClosed,
    required this.dartsThrownInTurn,
    required this.onSegmentTapped,
  });

  final int target;
  final List<CompetitorState> competitors;
  final bool isRowClosed;
  final int dartsThrownInTurn;
  final ValueChanged<String> onSegmentTapped;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: isRowClosed
          ? cs.surfaceContainerHighest.withValues(alpha: 0.38)
          : null,
      child: Row(
        children: [
          for (final c in competitors)
            Expanded(
              child: _MarkCell(
                marks: _marksForPlayer(c, target),
              ),
            ),
          _InputCell(
            label: _singleSegment(target),
            bg: null,
            textColor: cs.onSurface,
            dotCount: 1,
            semanticLabel:
                'Single ${target == 25 ? "Bull" : "$target"}',
            onTap: isRowClosed
                ? null
                : () => onSegmentTapped(_singleSegment(target)),
            isRowClosed: isRowClosed,
          ),
          _InputCell(
            label: _doubleSegment(target),
            bg: cs.primaryContainer,
            textColor: cs.onPrimaryContainer,
            dotCount: 2,
            semanticLabel:
                'Double ${target == 25 ? "Bull" : "$target"}',
            onTap: isRowClosed
                ? null
                : () => onSegmentTapped(_doubleSegment(target)),
            isRowClosed: isRowClosed,
          ),
          if (target != 25)
            _InputCell(
              label: _tripleSegment(target),
              bg: cs.primary,
              textColor: cs.onPrimary,
              dotCount: 3,
              semanticLabel: 'Triple $target',
              onTap: isRowClosed
                  ? null
                  : () => onSegmentTapped(_tripleSegment(target)),
              isRowClosed: isRowClosed,
            )
          else
            const _DisabledTripleCell(),
        ],
      ),
    );
  }
}

// ── Mark cell ─────────────────────────────────────────────────────────────────

class _MarkCell extends StatelessWidget {
  const _MarkCell({required this.marks});
  final int marks;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (symbol, color) = switch (marks) {
      0 => ('─', cs.onSurfaceVariant),
      1 => ('/', cs.onSurface),
      2 => ('X', cs.onSurface),
      _ => ('⊗', AppColors.cricketClosed),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          symbol,
          style: AppTextStyles.headingMedium.copyWith(color: color),
        ),
      ),
    );
  }
}

// ── Input cell ────────────────────────────────────────────────────────────────

class _InputCell extends StatelessWidget {
  const _InputCell({
    required this.label,
    required this.bg,
    required this.textColor,
    required this.dotCount,
    required this.semanticLabel,
    required this.onTap,
    required this.isRowClosed,
  });

  final String label;
  final Color? bg;
  final Color textColor;
  final int dotCount;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool isRowClosed;

  @override
  Widget build(BuildContext context) {
    final cell = Tooltip(
      message: isRowClosed ? 'Number already closed' : '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: bg,
          width: 56,
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style:
                    AppTextStyles.segmentButton.copyWith(color: textColor),
              ),
              if (dotCount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    dotCount,
                    (_) => Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: textColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Semantics(label: semanticLabel, child: cell);
  }
}

// ── Disabled triple cell (Bull row) ──────────────────────────────────────────

class _DisabledTripleCell extends StatelessWidget {
  const _DisabledTripleCell();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Triple Bull — not applicable in Cricket',
      child: SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: Text(
            '≡',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

// ── Footer row ────────────────────────────────────────────────────────────────

class _CricketFooterRow extends StatelessWidget {
  const _CricketFooterRow({
    required this.dartsThrownInTurn,
    required this.onNextPlayer,
  });

  final int dartsThrownInTurn;
  final VoidCallback onNextPlayer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 1)),
      ),
      child: Row(
        children: [
          const Expanded(child: SizedBox.shrink()),
          _NextPlayerButton(
            dartsThrownInTurn: dartsThrownInTurn,
            onNextPlayer: onNextPlayer,
          ),
        ],
      ),
    );
  }
}

class _NextPlayerButton extends StatelessWidget {
  const _NextPlayerButton({
    required this.dartsThrownInTurn,
    required this.onNextPlayer,
  });

  final int dartsThrownInTurn;
  final VoidCallback onNextPlayer;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        if (dartsThrownInTurn >= 3) {
          onNextPlayer();
        } else {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => _AdvanceTurnConfirmDialog(
              dartsThrownInTurn: dartsThrownInTurn,
            ),
          );
          if (confirmed == true) {
            onNextPlayer();
          }
        }
      },
      child: const Text('NEXT PLAYER'),
    );
  }
}

class _AdvanceTurnConfirmDialog extends StatelessWidget {
  const _AdvanceTurnConfirmDialog({required this.dartsThrownInTurn});
  final int dartsThrownInTurn;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Advance turn?'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: [screenWidth - 48, 320.0].reduce((a, b) => a < b ? a : b),
        ),
        child: Text(
          "You've only thrown $dartsThrownInTurn dart(s). Advance anyway?",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
