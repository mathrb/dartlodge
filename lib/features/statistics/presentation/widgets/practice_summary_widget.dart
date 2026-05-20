import 'package:flutter/material.dart';

import '../../../../core/widgets/post_game_hero_card_widget.dart';
import '../../../game/domain/models/game_result.dart';

/// Post-game summary for the four practice drills — Around the Clock,
/// Catch 40, Bob's 27, 170 Checkout — switching per variant. Solo drills
/// have no winner/PPR/checkout% semantics, so this widget intentionally
/// renders only the per-variant hero card (no forced common stats /
/// breakdown table; see #230).
class PracticeSummaryWidget extends StatelessWidget {
  const PracticeSummaryWidget({super.key, required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      AroundTheClockResult(:final competitorName, :final turnsToComplete,
          :final totalDarts, :final doublesOnly) =>
        PostGameHeroCard(
          badge: doublesOnly ? 'DOUBLES ONLY' : null,
          headline: competitorName,
          subline: 'Around the Clock',
          sideStats: [
            PostGameHeroStat(
              label: 'TURNS',
              value: '$turnsToComplete',
              emphasize: true,
            ),
            PostGameHeroStat(label: 'DARTS', value: '$totalDarts'),
          ],
        ),
      Catch40Result(:final competitorName, :final score, :final targetsCleared) =>
        PostGameHeroCard(
          headline: competitorName,
          subline: 'Catch 40',
          sideStats: [
            PostGameHeroStat(
              label: 'SCORE',
              value: '$score / 120',
              emphasize: true,
            ),
            PostGameHeroStat(
              label: 'TARGETS',
              value: '$targetsCleared / 40',
            ),
          ],
        ),
      Bobs27Result(
        :final competitorName,
        :final finalScore,
        :final roundReached,
        :final bustedToZero,
      ) =>
        PostGameHeroCard(
          badge: bustedToZero ? 'BUSTED' : null,
          headline: competitorName,
          subline: bustedToZero ? "Bob's 27 — drill ended" : "Bob's 27",
          muted: bustedToZero,
          sideStats: [
            PostGameHeroStat(
              label: 'FINAL SCORE',
              value: '$finalScore',
              emphasize: !bustedToZero,
            ),
            PostGameHeroStat(label: 'ROUND', value: '$roundReached / 20'),
          ],
        ),
      CheckoutPracticeResult(
        :final competitorName,
        :final checkedOut,
        :final dartsThrown,
        :final fromScore,
        :final remainingScore,
      ) =>
        PostGameHeroCard(
          badge: checkedOut ? 'CHECKED OUT' : null,
          headline:
              checkedOut ? 'Checked out!' : 'Not checked out',
          subline: competitorName,
          muted: !checkedOut,
          sideStats: [
            PostGameHeroStat(
              label: 'DARTS',
              value: '$dartsThrown',
              emphasize: checkedOut,
            ),
            PostGameHeroStat(
              label: 'FROM → REMAINING',
              value: '$fromScore → $remainingScore',
            ),
          ],
        ),
      ShanghaiResult() => const SizedBox.shrink(),
    };
  }
}
