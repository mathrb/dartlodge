import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/segment_utils.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01DoubleOutProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.doubleOut',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'TurnStarted', 'DartThrown', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _doubleAttempts = 0;
  int _doubleSuccesses = 0;

  // Score remaining BEFORE the next dart in the current turn, for the player
  // this projection is scoped to. Seeded from `TurnStarted.starting_score`,
  // decremented by each `DartThrown.score`. Null between turns or before the
  // first `TurnStarted`. `buildDartThrownEvent` does NOT include a
  // `remaining_after` field, so reconstructing locally is the only way to
  // know whether a dart was thrown at a checkout-range remaining. See #185.
  int? _currentTurnRemaining;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _doubleAttempts = 0;
    _doubleSuccesses = 0;
    _currentTurnRemaining = null;
  }

  bool get _isActive => _context?.outStrategy != 'straight';

  bool _isDoubleAttemptMultiplier(int multiplier) {
    final strategy = _context?.outStrategy ?? '';
    if (strategy == 'double') return multiplier == 2;
    if (strategy == 'master') return multiplier == 2 || multiplier == 3;
    return false;
  }

  @override
  void apply(GameEvent event) {
    if (!_isActive) return;
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final start = (event.payload['starting_score'] as num?)?.toInt();
        _currentTurnRemaining = start;
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final remaining = _currentTurnRemaining;
        // Without a TurnStarted seed we cannot tell whether the dart was
        // thrown at a checkout-range remaining; skip rather than guess.
        // Mirrors the X01 first-nine PPR projection's TurnStarted dependency.
        if (remaining == null) return;
        final score = (event.payload['score'] as num?)?.toInt() ?? 0;
        if (remaining <= 50) {
          final s = readSegmentFromPayload(event.payload);
          if (_isDoubleAttemptMultiplier(s.multiplier)) _doubleAttempts++;
        }
        _currentTurnRemaining = remaining - score;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId) _doubleSuccesses++;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // Per-turn remaining is reseeded on the next TurnStarted, so explicit
    // clearing isn't required for correctness — but doing so on leg/match
    // resets makes the engine robust if the runner ever feeds events out of
    // turn-bounded order.
    if (scope == ProjectionScope.leg || scope == ProjectionScope.match) {
      _currentTurnRemaining = null;
    }
    // doubleAttempts / doubleSuccesses are cumulative lifetime stats —
    // no reset across leg/match/turn.
  }

  @override
  Map<String, dynamic> snapshot() {
    if (!_isActive) return {};
    final rate = _doubleAttempts > 0
        ? (_doubleSuccesses / _doubleAttempts * 100)
        : null;
    return {
      'doubleOutSuccessRate': rate,
      'doubleAttempts': _doubleAttempts,
      'doubleSuccesses': _doubleSuccesses,
    };
  }
}
