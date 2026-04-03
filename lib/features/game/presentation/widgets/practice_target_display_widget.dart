import 'package:flutter/material.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/constants.dart';

class PracticeTargetDisplayWidget extends StatelessWidget {
  const PracticeTargetDisplayWidget({
    required this.gameType,
    required this.currentTarget,
    required this.practiceRound,
    required this.totalRounds,
    required this.score,
    required this.practiceAttempts,
    required this.practiceSuccesses,
    this.roundScore = 0,
    super.key,
  });

  final GameType gameType;
  final int? currentTarget;
  final int practiceRound;
  final int? totalRounds;
  final int score;
  final int practiceAttempts;
  final int practiceSuccesses;
  final int roundScore;

  String get _targetLabel {
    if (gameType == GameType.catch40) return '${60 + practiceRound}';
    final n = currentTarget;
    if (n == null) return '—';
    return switch (gameType) {
      GameType.bobs27 => 'D$n',
      _ => '$n',
    };
  }

  String get _secondaryMetric {
    return switch (gameType) {
      GameType.aroundTheClock =>
        'Number $practiceRound',
      GameType.bobs27 =>
        'Score: $score',
      GameType.shanghai =>
        'Score: $score | Round $practiceRound/$totalRounds',
      GameType.catch40 =>
        'Score: $score | Max: 120',
      GameType.checkoutPractice => _checkoutRate(),
      _ => '',
    };
  }

  String _checkoutRate() {
    if (practiceAttempts == 0) return '$practiceSuccesses/$practiceAttempts — —';
    final rate = (practiceSuccesses / practiceAttempts * 100).round();
    return '$practiceSuccesses/$practiceAttempts — $rate%';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryColor = (gameType == GameType.bobs27 && score < 0)
            ? colorScheme.error
            : colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _targetLabel,
          style: AppTextStyles.scoreMedium(context).copyWith(
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _secondaryMetric,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: secondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
