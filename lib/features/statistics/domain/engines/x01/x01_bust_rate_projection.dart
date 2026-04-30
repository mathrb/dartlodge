import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01BustRateProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_bust_rate',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnEnded'},
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _totalTurns = 0;
  int _bustTurns = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _totalTurns = 0;
    _bustTurns = 0;
  }

  @override
  void apply(GameEvent event) {
    if (event.eventType != 'TurnEnded') return;
    final playerId = event.payload['player_id'] as String?;
    if (playerId != _context?.playerId) return;
    _totalTurns++;
    final reason = event.payload['reason'] as String?;
    if (reason == 'bust') _bustTurns++;
  }

  @override
  void reset(ProjectionScope scope) {
    // turn-scoped but tracks lifetime totals — no reset needed per turn
    // match-scope reset would reset everything; not declared so ignored
  }

  @override
  Map<String, dynamic> snapshot() {
    final bustRate =
        _totalTurns > 0 ? (_bustTurns / _totalTurns) : 0.0;
    return {
      'bustRate': bustRate,
      'bustTurns': _bustTurns,
      'totalTurns': _totalTurns,
    };
  }
}
