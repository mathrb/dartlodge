import 'package:flutter/material.dart';
import '../../domain/models/game_state.dart';

class PlayerScoreSectionWidget extends StatelessWidget {
  const PlayerScoreSectionWidget({
    required this.gameState,
    super.key,
  });

  final GameState gameState;

  String _ppr(CompetitorState cs) {
    final dartsThrown = cs.dartThrows.length;
    if (dartsThrown == 0) return '0.0';
    final totalReduction = gameState.startingScore - cs.score;
    return ((totalReduction / dartsThrown) * 3).toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final active = gameState.competitors[gameState.currentTurnIndex];
    final inactive = [
      for (int i = 0; i < gameState.competitors.length; i++)
        if (i != gameState.currentTurnIndex) gameState.competitors[i],
    ];

    return Container(
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActivePlayerTile(competitor: active, ppr: _ppr(active)),
          if (inactive.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InactivePlayersRow(competitors: inactive, pprOf: _ppr),
          ],
        ],
      ),
    );
  }
}

class _ActivePlayerTile extends StatelessWidget {
  const _ActivePlayerTile({required this.competitor, required this.ppr});
  final CompetitorState competitor;
  final String ppr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${competitor.score}',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          competitor.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'PPR: $ppr',
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

class _InactivePlayersRow extends StatelessWidget {
  const _InactivePlayersRow({
    required this.competitors,
    required this.pprOf,
  });
  final List<CompetitorState> competitors;
  final String Function(CompetitorState) pprOf;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < competitors.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: _InactivePlayerTile(competitor: competitors[i])),
        ],
      ],
    );
  }
}

class _InactivePlayerTile extends StatelessWidget {
  const _InactivePlayerTile({required this.competitor});
  final CompetitorState competitor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${competitor.score}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9E9E9E),
          ),
        ),
        Text(
          competitor.name,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9E9E9E),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
