import 'package:flutter/material.dart';
import 'package:my_darts/core/utils/cricket_segment_utils.dart';
import '../../domain/models/game_state.dart';

class CricketScoreSidebarWidget extends StatelessWidget {
  const CricketScoreSidebarWidget({
    required this.gameState,
    super.key,
  });

  final GameState gameState;

  String _mpr(CompetitorState cs) {
    final rounds = cs.dartThrows.length ~/ 3;
    if (rounds == 0) return '0.0';
    final totalMarks =
        cs.dartThrows.fold(0, (sum, s) => sum + cricketMarksForSegment(s));
    return (totalMarks / rounds).toStringAsFixed(1);
  }

  String? _leaderId(List<CompetitorState> competitors) {
    if (competitors.isEmpty) return null;
    if (gameState.cricketVariant == 'cutthroat') {
      return competitors.reduce((a, b) => a.score <= b.score ? a : b).competitorId;
    }
    return competitors.reduce((a, b) => a.score >= b.score ? a : b).competitorId;
  }

  @override
  Widget build(BuildContext context) {
    final competitors = gameState.competitors;
    final leaderId = _leaderId(competitors);
    final isCutthroat = gameState.cricketVariant == 'cutthroat';

    return Container(
      color: const Color(0xFF2C2C2C),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < competitors.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            if (i == gameState.currentTurnIndex)
              _ActivePanel(
                competitor: competitors[i],
                mpr: _mpr(competitors[i]),
                isLeader: competitors[i].competitorId == leaderId,
                isCutthroat: isCutthroat,
              )
            else
              _InactivePanel(
                competitor: competitors[i],
                mpr: _mpr(competitors[i]),
                isLeader: competitors[i].competitorId == leaderId,
                isCutthroat: isCutthroat,
              ),
          ],
        ],
      ),
    );
  }
}

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    required this.competitor,
    required this.mpr,
    required this.isLeader,
    required this.isCutthroat,
  });

  final CompetitorState competitor;
  final String mpr;
  final bool isLeader;
  final bool isCutthroat;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${competitor.score}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (isCutthroat) ...[
                const SizedBox(width: 6),
                const Text(
                  'Against',
                  style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                ),
              ],
              if (isLeader) ...[
                const SizedBox(width: 8),
                Icon(Icons.star, color: accentColor, size: 22),
              ],
            ],
          ),
          Text(
            competitor.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'MPR: $mpr',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}

class _InactivePanel extends StatelessWidget {
  const _InactivePanel({
    required this.competitor,
    required this.mpr,
    required this.isLeader,
    required this.isCutthroat,
  });

  final CompetitorState competitor;
  final String mpr;
  final bool isLeader;
  final bool isCutthroat;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${competitor.score}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                    if (isCutthroat) ...[
                      const SizedBox(width: 4),
                      const Text(
                        'Against',
                        style: TextStyle(fontSize: 11, color: Color(0xFF757575)),
                      ),
                    ],
                    if (isLeader) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, color: Color(0xFF9E9E9E), size: 16),
                    ],
                  ],
                ),
                Text(
                  competitor.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'MPR: $mpr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
