import 'package:flutter/material.dart';

import '../../../../core/widgets/post_game_hero_card_widget.dart';
import '../../../../core/widgets/post_game_stats_breakdown_widget.dart';
import '../../../game/domain/models/game_result.dart';

/// Post-game summary for the four practice drills — Around the Clock,
/// Catch 40, Bob's 27, 170 Checkout — switching per variant. Solo drills
/// render only the per-variant hero card (no forced common stats /
/// breakdown table; see #230). Around the Clock allows multiple
/// competitors (`maxPlayers == null`) — it renders the winner up top and
/// a per-player breakdown below so non-winners aren't hidden (#279).
class PracticeSummaryWidget extends StatelessWidget {
  const PracticeSummaryWidget({super.key, required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return switch (result) {
      AroundTheClockResult() => _AtcSummary(result: result as AroundTheClockResult),
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
        :final attempts,
        :final successes,
        :final dartsThrown,
        :final fromScore,
      ) =>
        _buildCheckoutHero(
          competitorName: competitorName,
          attempts: attempts,
          successes: successes,
          dartsThrown: dartsThrown,
          fromScore: fromScore,
        ),
      ShanghaiResult() => const SizedBox.shrink(),
    };
  }

  /// Multi-attempt aware checkout-practice hero.
  ///
  /// Single-attempt session (`attempts == 1`) keeps the original chrome —
  /// "Checked out!" / "Not checked out" — so the ∞-mode one-and-done flow
  /// reads the same as before.
  ///
  /// Multi-attempt session shows a success-rate fraction and percentage so
  /// users see all of their attempts, not just the last one (#316).
  Widget _buildCheckoutHero({
    required String competitorName,
    required int attempts,
    required int successes,
    required int dartsThrown,
    required int fromScore,
  }) {
    final isSingleAttempt = attempts <= 1;
    final allCheckedOut = successes > 0 && successes == attempts;
    final anySuccess = successes > 0;

    final headline = isSingleAttempt
        ? (anySuccess ? 'Checked out!' : 'Not checked out')
        : '$successes of $attempts checkouts';
    final badge = allCheckedOut ? 'CHECKED OUT' : null;
    final rate = attempts == 0 ? 0 : (successes * 100 / attempts).round();

    return PostGameHeroCard(
      badge: badge,
      headline: headline,
      subline: competitorName,
      muted: !anySuccess,
      sideStats: [
        PostGameHeroStat(
          label: 'DARTS',
          value: '$dartsThrown',
          emphasize: anySuccess,
        ),
        if (isSingleAttempt)
          PostGameHeroStat(
            label: 'FROM',
            value: '$fromScore',
          )
        else
          PostGameHeroStat(
            label: 'SUCCESS RATE',
            value: '$rate%',
            emphasize: anySuccess,
          ),
      ],
    );
  }
}

class _AtcSummary extends StatelessWidget {
  const _AtcSummary({required this.result});

  final AroundTheClockResult result;

  @override
  Widget build(BuildContext context) {
    final competitors = result.competitors;
    final winnerId = result.winnerCompetitorId;
    final winner = winnerId == null
        ? null
        : competitors
            .where((c) => c.competitorId == winnerId)
            .firstOrNull;
    // Solo drills keep the original hero-only chrome so single-player ATC
    // looks the same as before #279. A completed solo drill has
    // `winnerCompetitorId` set to that lone competitor's id, so checking
    // `winnerId == null` here would render a 1-column breakdown instead of
    // the hero — `competitors.length == 1` is the correct discriminant.
    final isSolo = competitors.length == 1;
    final lead = winner ?? (competitors.isNotEmpty ? competitors.first : null);

    if (lead == null) return const SizedBox.shrink();

    final hero = PostGameHeroCard(
      badge: result.doublesOnly ? 'DOUBLES ONLY' : null,
      headline: lead.competitorName,
      subline: 'Around the Clock',
      sideStats: [
        PostGameHeroStat(
          label: 'TURNS',
          value: '${lead.turnsCompleted}',
          emphasize: true,
        ),
        PostGameHeroStat(label: 'DARTS', value: '${lead.totalDarts}'),
      ],
    );

    if (isSolo) return hero;

    final columns = [
      for (final c in competitors)
        PostGameBreakdownColumn(
          name: c.competitorName,
          subtitle: c.competitorId == winnerId ? 'WINNER' : null,
          emphasize: c.competitorId == winnerId,
        ),
    ];
    PostGameBreakdownRow row(String category, String Function(AtcCompetitorResult) cell) {
      return PostGameBreakdownRow(
        category: category,
        values: [for (final c in competitors) cell(c)],
        highlights: [for (final c in competitors) c.competitorId == winnerId],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hero,
        const SizedBox(height: 16),
        PostGameStatsBreakdown(
          columns: columns,
          rows: [
            row('Turns', (c) => '${c.turnsCompleted}'),
            row('Darts', (c) => '${c.totalDarts}'),
            row('Last target hit', (c) => '${c.lastTargetHit}'),
            row('Finished', (c) => c.finished ? 'Yes' : '—'),
          ],
        ),
      ],
    );
  }
}
