import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';

class GameSummaryCardWidget extends StatelessWidget {
  final Game game;
  final List<Competitor> competitors;
  final VoidCallback onTap;
  final GameStats? gameStats;

  const GameSummaryCardWidget({
    required this.game,
    required this.competitors,
    required this.onTap,
    this.gameStats,
    super.key,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) return '$diff days ago';
    return DateFormat('d MMM y').format(date);
  }

  static String gameTypeName(GameType type) {
    switch (type) {
      case GameType.x01:
        return 'X01';
      case GameType.cricket:
        return 'Cricket';
      case GameType.aroundTheClock:
        return 'Around the Clock';
      case GameType.killer:
        return 'Killer';
      case GameType.baseball:
        return 'Baseball';
      case GameType.golf:
        return 'Golf';
      case GameType.shanghai:
        return 'Shanghai';
      case GameType.scram:
        return 'Scram';
      case GameType.halveIt:
        return 'Halve It';
      case GameType.highScore:
        return 'High Score';
      case GameType.blindCricket:
        return 'Blind Cricket';
      case GameType.blindGolf:
        return 'Blind Golf';
      case GameType.blindKiller:
        return 'Blind Killer';
      case GameType.blindShanghai:
        return 'Blind Shanghai';
      case GameType.chaseTheDragon:
        return 'Chase the Dragon';
      case GameType.catch40:
        return 'Catch 40';
      case GameType.bobs27:
        return "Bob's 27";
      case GameType.checkoutPractice:
        return 'Checkout Practice';
    }
  }

  String _variantLabel(GameConfig config) {
    return config.maybeMap(
      x01: (c) => '${c.startingScore}',
      cricket: (c) => c.variant,
      aroundTheClock: (c) => c.variant,
      orElse: () => '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winner = game.winnerCompetitorId;

    final sorted = [...competitors]..sort((a, b) {
        if (a.competitorId == winner) return -1;
        if (b.competitorId == winner) return 1;
        return 0;
      });

    final statsByComp = {
      if (gameStats != null)
        for (final cs in gameStats!.byCompetitor) cs.competitorId: cs,
    };

    final variant = _variantLabel(game.config);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      gameTypeName(game.gameType),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (variant.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(variant, style: theme.textTheme.bodySmall),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(game.endTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...sorted.map((c) {
                final isWinner = c.competitorId == winner;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      if (isWinner)
                        const Icon(Icons.emoji_events,
                            size: 16, color: Colors.amber),
                      if (isWinner) const SizedBox(width: 4),
                      Text(
                        c.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isWinner
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (gameStats != null && sorted.length >= 2) ...[
                const SizedBox(height: 4),
                Text(
                  sorted.map((c) {
                    final stats = statsByComp[c.competitorId];
                    return stats?.legsWon.toString() ?? '0';
                  }).join(' – '),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
