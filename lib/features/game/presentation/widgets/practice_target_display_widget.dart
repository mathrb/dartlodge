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
    this.catch40DartsOnTarget = 0,
    this.currentPlayerName,
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

  /// Number of darts already thrown at the current Catch 40 target across
  /// both visits (0–6). Drives the "Visit 1/2" / "Visit 2/2" caption so the
  /// player knows whether they're still on their first 3 darts or their
  /// final 3 (#324). Engine resets this to 0 when the target advances; the
  /// provider's `_advanceTurn` between visits preserves it.
  final int catch40DartsOnTarget;

  /// When non-null, renders a "<NAME>'S TURN" header above the target —
  /// surfaces whose turn it is in multi-player ATC/Shanghai games. Solo
  /// drills pass null and keep the previous target-only chrome (#276).
  final String? currentPlayerName;

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
        // The big number above already IS the target — labelling this
        // counter "Number" looked like a stale duplicate of the target.
        // It's actually the round (full rotation of all competitors), so
        // say that (#288).
        'Round $practiceRound',
      GameType.bobs27 =>
        'Score: $score',
      GameType.shanghai =>
        'Score: $score | Round $practiceRound/$totalRounds',
      GameType.catch40 => 'Score: $score | Visit ${_catch40Visit()}/2',
      GameType.checkoutPractice => _checkoutDartsThrown(),
      _ => '',
    };
  }

  String _checkoutDartsThrown() {
    return '$practiceAttempts darts thrown';
  }

  /// Catch 40 visit number (1 or 2). `catch40DartsOnTarget` runs 0..6 across
  /// a target; the second visit begins at dart 4 (index 3). After the 3rd
  /// dart of visit 1, the provider auto-advances to visit 2 keeping
  /// `dartsOnTarget` at 3 — so 3 is the first index of visit 2.
  int _catch40Visit() => catch40DartsOnTarget >= 3 ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryColor = (gameType == GameType.bobs27 && score < 0)
            ? colorScheme.error
            : colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentPlayerName != null) ...[
          Text(
            "${currentPlayerName!.toUpperCase()}'S TURN",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          _targetLabel,
          style: AppTextStyles.scoreMedium.copyWith(
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
