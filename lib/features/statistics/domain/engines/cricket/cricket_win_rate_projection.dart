import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// Career-level win rate for cricket games.
class CricketWinRateProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.winRate',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'GameCompleted'},
    scope: ProjectionScope.match,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _gamesPlayed = 0;
  int _gamesWon = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _gamesPlayed = 0;
    _gamesWon = 0;
  }

  @override
  void apply(GameEvent event) {
    if (event.eventType != 'GameCompleted') return;
    _gamesPlayed++;
    final winnerId = event.payload['winner_player_id'] as String?;
    if (winnerId == _context?.playerId) _gamesWon++;
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative lifetime stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    final winRate = _gamesPlayed > 0 ? (_gamesWon / _gamesPlayed) : 0.0;
    return {
      'winRate': winRate,
      'gamesWon': _gamesWon,
      'gamesPlayed': _gamesPlayed,
    };
  }
}
