import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01WinRateProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.winRate',
    supportedGameTypes: {GameType.x01},
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
    final winRate =
        _gamesPlayed > 0 ? (_gamesWon / _gamesPlayed) : 0.0;
    return {
      'winRate': winRate,
      'gamesWon': _gamesWon,
      'gamesPlayed': _gamesPlayed,
    };
  }
}
