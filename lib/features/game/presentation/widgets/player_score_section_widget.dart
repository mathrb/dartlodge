import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../domain/models/game_state.dart';

class PlayerScoreSectionWidget extends StatelessWidget {
  const PlayerScoreSectionWidget({
    required this.gameState,
    required this.bustFlashAnim,
    super.key,
  });

  final GameState gameState;
  final Animation<double> bustFlashAnim;

  String _pprDisplay(CompetitorState cs) {
    if (cs.dartThrows.length < 3) return '—';
    final totalReduction = gameState.startingScore - cs.score;
    return ((totalReduction / cs.dartThrows.length) * 3).toStringAsFixed(1);
  }

  TextStyle _scoreStyle(BuildContext context) {
    final n = gameState.competitors.length;
    if (n <= 2) return AppTextStyles.scoreActive(context);
    if (n <= 4) return AppTextStyles.scoreMedium(context);
    return AppTextStyles.scoreSmall(context);
  }

  @override
  Widget build(BuildContext context) {
    final scoreStyle = _scoreStyle(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < gameState.competitors.length; i++)
            Expanded(
              child: _PlayerColumn(
                competitor: gameState.competitors[i],
                isActive: i == gameState.currentTurnIndex,
                scoreStyle: scoreStyle,
                pprDisplay: _pprDisplay(gameState.competitors[i]),
                bustFlashAnim: bustFlashAnim,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  const _PlayerColumn({
    required this.competitor,
    required this.isActive,
    required this.scoreStyle,
    required this.pprDisplay,
    required this.bustFlashAnim,
  });

  final CompetitorState competitor;
  final bool isActive;
  final TextStyle scoreStyle;
  final String pprDisplay;
  final Animation<double> bustFlashAnim;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg =
        isDark ? AppColorsDark.activePlayerBg : AppColors.activePlayerBg;

    final decoration = isActive
        ? BoxDecoration(
            color: activeBg,
            border: Border(
              left: BorderSide(color: cs.primary, width: 4),
            ),
          )
        : BoxDecoration(color: cs.surface);

    final nameColor = isActive ? cs.secondary : cs.onSurfaceVariant;
    final nameText =
        '${competitor.name.toUpperCase()}${isActive ? ' ▶' : ''}';

    return Stack(
      children: [
        Container(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedScore(score: competitor.score, style: scoreStyle),
              Text(
                nameText,
                style: AppTextStyles.playerName.copyWith(color: nameColor),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'PPR $pprDisplay',
                style: AppTextStyles.bodySmall
                    .copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        // Bust border flash (active column only)
        if (isActive)
          AnimatedBuilder(
            animation: bustFlashAnim,
            builder: (context, _) {
              if (bustFlashAnim.value == 0.0) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: cs.error
                              .withValues(alpha: bustFlashAnim.value),
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AnimatedScore extends StatefulWidget {
  const _AnimatedScore({required this.score, required this.style});

  final int score;
  final TextStyle style;

  @override
  State<_AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<_AnimatedScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Tween<double> _tween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tween = Tween<double>(
      begin: widget.score.toDouble(),
      end: widget.score.toDouble(),
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _tween = Tween<double>(
        begin: oldWidget.score.toDouble(),
        end: widget.score.toDouble(),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Text('${widget.score}', style: widget.style);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _tween.evaluate(_controller).round();
        return Text('$value', style: widget.style);
      },
    );
  }
}
