import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01LegsProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.legs',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _legsPlayed = 0;
  int _legsWon = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _legsPlayed = 0;
    _legsWon = 0;
  }

  @override
  void apply(GameEvent event) {
    if (event.eventType != 'LegCompleted') return;
    // Solo games (one competitor) are practice / sandbox runs — exclude their
    // legs from the multiplayer-only legs played/won totals. See issue #106.
    if (_context?.soloGameIds.contains(event.gameId) ?? false) return;
    _legsPlayed++;
    final winnerId = event.payload['winner_player_id'] as String?;
    if (winnerId == _context?.playerId) _legsWon++;
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative lifetime stat — no reset
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'legsWon': _legsWon,
      'legsPlayed': _legsPlayed,
    };
  }
}
