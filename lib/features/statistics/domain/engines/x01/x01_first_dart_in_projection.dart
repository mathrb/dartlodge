import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/segment_utils.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class X01FirstDartInProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01.firstDartIn',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'DartThrown', 'TurnStarted', 'LegCompleted'},
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _inAttempts = 0;
  int _inSuccesses = 0;
  bool _playerIsIn = false;
  bool _awaitingFirstDart = false;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _inAttempts = 0;
    _inSuccesses = 0;
    _playerIsIn = false;
    _awaitingFirstDart = false;
  }

  bool get _isActive => _context?.inStrategy != 'straight';

  bool _isValidInMultiplier(int multiplier) {
    final strategy = _context?.inStrategy ?? '';
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
        if (!_playerIsIn) _awaitingFirstDart = true;
      case 'DartThrown':
        if (!_awaitingFirstDart) return;
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _inAttempts++;
        final s = readSegmentFromPayload(event.payload);
        if (_isValidInMultiplier(s.multiplier)) {
          _inSuccesses++;
          _playerIsIn = true;
        }
        _awaitingFirstDart = false;
      case 'LegCompleted':
        _playerIsIn = false;
        _awaitingFirstDart = false;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // counters are cumulative; per-leg flags reset inside apply
  }

  @override
  Map<String, dynamic> snapshot() {
    if (!_isActive) return {};
    final rate =
        _inAttempts > 0 ? (_inSuccesses / _inAttempts * 100) : null;
    return {
      'firstDartInSuccessRate': rate,
      'inAttempts': _inAttempts,
      'inSuccesses': _inSuccesses,
    };
  }
}
