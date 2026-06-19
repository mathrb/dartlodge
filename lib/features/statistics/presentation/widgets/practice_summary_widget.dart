import 'package:flutter/material.dart';

import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../../../../core/utils/stat_formatter.dart';
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
    final l10n = AppLocalizations.of(context);
    return switch (result) {
      AroundTheClockResult() => _AtcSummary(result: result as AroundTheClockResult),
      Catch40Result(:final competitorName, :final score, :final targetsCleared) =>
        PostGameHeroCard(
          headline: competitorName,
          subline: 'Catch 40',
          sideStats: [
            PostGameHeroStat(
              label: l10n.summaryScore.toUpperCase(),
              value: '$score / 120',
              emphasize: true,
            ),
            PostGameHeroStat(
              label: l10n.summaryTargets.toUpperCase(),
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
          badge: bustedToZero ? l10n.bobs27BustedBadge.toUpperCase() : null,
          headline: competitorName,
          subline: bustedToZero ? l10n.bobs27BustedSubline : "Bob's 27",
          muted: bustedToZero,
          sideStats: [
            PostGameHeroStat(
              label: l10n.summaryFinalScore.toUpperCase(),
              value: '$finalScore',
              emphasize: !bustedToZero,
              // Negative finals (drill ended on a missed double in the
              // late rounds) flagged in error colour to match the
              // in-game red treatment instead of green-celebrating
              // a negative score (#339).
              danger: finalScore < 0,
            ),
            PostGameHeroStat(
                label: l10n.summaryRound.toUpperCase(),
                // 21 rounds incl. the Double-Bull finale (#588).
                value: '$roundReached / 21'),
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
          l10n: l10n,
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
    required AppLocalizations l10n,
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
        ? (anySuccess ? l10n.summaryCheckedOut : l10n.summaryNotCheckedOut)
        : l10n.summaryNOfMCheckouts(successes, attempts);
    final badge = allCheckedOut ? 'CHECKED OUT' : null;
    final rate = attempts == 0
        ? null
        : StatFormatter.fmtPct(successes / attempts, decimals: 0);

    return PostGameHeroCard(
      badge: badge,
      headline: headline,
      subline: competitorName,
      muted: !anySuccess,
      sideStats: [
        PostGameHeroStat(
          label: l10n.summaryDarts.toUpperCase(),
          value: '$dartsThrown',
          emphasize: anySuccess,
        ),
        if (isSingleAttempt)
          PostGameHeroStat(
            label: l10n.summaryFrom.toUpperCase(),
            value: '$fromScore',
          )
        else
          PostGameHeroStat(
            label: l10n.summarySuccessRate.toUpperCase(),
            value: rate ?? '—',
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
    final l10n = AppLocalizations.of(context);
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

    // Abandoned drill (no winner, no darts thrown by any competitor)
    // used to render the first player as "winner" with 0/0 stats (#335).
    // Show a neutral "no winner" hero instead — the competitor breakdown
    // below (multi-player path) still surfaces the zeroed stats.
    final totalDartsAllCompetitors =
        competitors.fold<int>(0, (sum, c) => sum + c.totalDarts);
    final isAbandoned = winnerId == null && totalDartsAllCompetitors == 0;

    final hero = PostGameHeroCard(
      badge: isAbandoned
          ? l10n.summaryEndedEarly.toUpperCase()
          : (result.doublesOnly ? l10n.summaryDoublesOnly.toUpperCase() : null),
      headline: isAbandoned ? l10n.summaryNoWinner : lead.competitorName,
      subline: 'Around the Clock',
      muted: isAbandoned,
      sideStats: isAbandoned
          ? const <PostGameHeroStat>[]
          : [
              PostGameHeroStat(
                label: l10n.summaryTurns.toUpperCase(),
                value: '${lead.turnsCompleted}',
                emphasize: true,
              ),
              PostGameHeroStat(
                  label: l10n.summaryDarts.toUpperCase(),
                  value: '${lead.totalDarts}'),
            ],
    );

    if (isSolo) return hero;

    final columns = [
      for (final c in competitors)
        PostGameBreakdownColumn(
          name: c.competitorName,
          subtitle:
              c.competitorId == winnerId ? l10n.summaryWinner.toUpperCase() : null,
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
            row(l10n.summaryTurns, (c) => '${c.turnsCompleted}'),
            row(l10n.summaryDarts, (c) => '${c.totalDarts}'),
            row(l10n.summaryLastTargetHit, (c) => '${c.lastTargetHit}'),
            row(l10n.summaryFinished, (c) => c.finished ? l10n.commonYes : '—'),
          ],
        ),
      ],
    );
  }
}
