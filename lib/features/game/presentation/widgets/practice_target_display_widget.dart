import 'package:flutter/material.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/utils/constants.dart';
import 'hero_metric_widget.dart';

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
    this.catch40TargetRemaining = 0,
    this.currentPlayerName,
    this.heroSize = false,
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

  /// Remaining score needed to finish the current Catch 40 target. Shown
  /// as the large central number so the player sees exactly how much is
  /// left without mental arithmetic (#326). Equals the round's starting
  /// target at the beginning of the round and after a bust reset.
  final int catch40TargetRemaining;

  /// When non-null, renders a "<NAME>'S TURN" header above the target —
  /// surfaces whose turn it is in multi-player ATC/Shanghai games. Solo
  /// drills pass null and keep the previous target-only chrome (#276).
  final String? currentPlayerName;

  /// Camera-first (#445): render the primary value (`_targetLabel`) at the
  /// large, at-distance-readable hero size via [HeroMetricWidget]. Default false
  /// keeps the manual board's inline `scoreMedium` target unchanged.
  final bool heroSize;

  String get _targetLabel {
    // Catch 40: show how much is LEFT to finish the current target. This
    // updates as darts reduce remaining, so players see exactly what they
    // need to check out — no mental arithmetic (#326). After a bust the
    // engine resets remaining to the round's starting target, so the
    // display naturally reflects the reset too.
    if (gameType == GameType.catch40) return '$catch40TargetRemaining';
    final n = currentTarget;
    if (n == null) return '—';
    return switch (gameType) {
      GameType.bobs27 => 'D$n',
      _ => '$n',
    };
  }

  String _secondaryMetric(AppLocalizations l10n) {
    return switch (gameType) {
      GameType.aroundTheClock =>
        // The big number above already IS the target — labelling this
        // counter "Number" looked like a stale duplicate of the target.
        // It's actually the round (full rotation of all competitors), so
        // say that (#288).
        l10n.gamePracticeRound(practiceRound),
      GameType.bobs27 =>
        l10n.gamePracticeScore(score),
      GameType.shanghai =>
        l10n.gameShanghaiProgress(score, practiceRound, totalRounds ?? 0),
      GameType.catch40 =>
        l10n.gameCatch40Progress(60 + practiceRound, _catch40Visit(), score),
      GameType.checkoutPractice => _checkoutDartsThrown(l10n),
      _ => '',
    };
  }

  String _checkoutDartsThrown(AppLocalizations l10n) {
    // `practiceAttempts` here is the per-round dart count (#328). When a
    // target-successes quota is configured, surface success progress
    // alongside it ("Success 1/3 · 2 darts thrown") so the player can see
    // how close they are to completing the drill (#327). In ∞ mode
    // (totalRounds == null) just show the dart count, matching the
    // unbounded-attempts UX.
    final dartsLine = l10n.gameDartsThrown(practiceAttempts);
    final target = totalRounds;
    if (target == null) return dartsLine;
    return l10n.gameCheckoutSuccess(practiceSuccesses, target, dartsLine);
  }

  /// Catch 40 visit number (1 or 2). `catch40DartsOnTarget` runs 0..6 across
  /// a target; the second visit begins at dart 4 (index 3). After the 3rd
  /// dart of visit 1, the provider auto-advances to visit 2 keeping
  /// `dartsOnTarget` at 3 — so 3 is the first index of visit 2.
  int _catch40Visit() => catch40DartsOnTarget >= 3 ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final secondaryColor = (gameType == GameType.bobs27 && score < 0)
            ? colorScheme.error
            : colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currentPlayerName != null) ...[
          Text(
            l10n.gamePlayerTurn(currentPlayerName!.toUpperCase()),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        if (heroSize)
          HeroMetricWidget(
            value: _targetLabel,
            valueColor: colorScheme.primary,
          )
        else
          Text(
            _targetLabel,
            style: AppTextStyles.scoreMedium.copyWith(
              color: colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 8),
        Text(
          _secondaryMetric(l10n),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: secondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
