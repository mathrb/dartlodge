import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'cricket_targets_mixin.dart';

/// Counts high-mark turns. Emits both ≥-N counters (`fiveMarkTurns` /
/// `sixMarkTurns` / `sevenMarkTurns` / `eightMarkTurns` / `nineMarkTurns`)
/// for the career stats panel and exact-N counters (`*Exact`) for the
/// per-game stats panel — see CLAUDE.md "Cricket mark-bucket field
/// overload".
class CricketMarkBucketsProjection extends ProjectionEngine
    with CricketTargetsTracker {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.markBuckets',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {
      'GameCreated',
      'CricketTargetsAssigned',
      'CrazyTargetsRolled',
      'DartThrown',
      'TurnEnded',
    },
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _fiveMarkTurns = 0;
  int _sixMarkTurns = 0;
  int _sevenMarkTurns = 0;
  int _eightMarkTurns = 0;
  int _nineMarkTurns = 0;
  int _turnMarks = 0;
  int _fiveMarkExact = 0;
  int _sixMarkExact = 0;
  int _sevenMarkExact = 0;
  int _eightMarkExact = 0;
  int _nineMarkExact = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _fiveMarkTurns = 0;
    _sixMarkTurns = 0;
    _sevenMarkTurns = 0;
    _eightMarkTurns = 0;
    _nineMarkTurns = 0;
    _turnMarks = 0;
    _fiveMarkExact = 0;
    _sixMarkExact = 0;
    _sevenMarkExact = 0;
    _eightMarkExact = 0;
    _nineMarkExact = 0;
    resetCricketTargets();
  }

  @override
  void apply(GameEvent event) {
    if (maybeApplyCricketTargets(event)) return;
    switch (event.eventType) {
      case 'DartThrown':
        // #638: dead-number-aware (records all competitors' hits, 0 marks on a
        // number closed by all). No player early-return.
        _turnMarks += cricketScopedMarksForDart(event, _context?.playerId);
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        // ≥-N counters for the career stats panel. Exact-N counters
        // below stay for per-game stats which surface the exact bucket.
        if (_turnMarks >= 9) _nineMarkTurns++;
        if (_turnMarks >= 8) _eightMarkTurns++;
        if (_turnMarks >= 7) _sevenMarkTurns++;
        if (_turnMarks >= 6) _sixMarkTurns++;
        if (_turnMarks >= 5) _fiveMarkTurns++;
        switch (_turnMarks) {
          case 5: _fiveMarkExact++;
          case 6: _sixMarkExact++;
          case 7: _sevenMarkExact++;
          case 8: _eightMarkExact++;
          case 9: _nineMarkExact++;
        }
        _turnMarks = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _turnMarks = 0;
    }
    if (scope == ProjectionScope.leg) {
      resetCricketClosureForLeg(); // #638
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    return {
      'fiveMarkTurns': _fiveMarkTurns,
      'sixMarkTurns': _sixMarkTurns,
      'sevenMarkTurns': _sevenMarkTurns,
      'eightMarkTurns': _eightMarkTurns,
      'nineMarkTurns': _nineMarkTurns,
      'fiveMarkExact': _fiveMarkExact,
      'sixMarkExact': _sixMarkExact,
      'sevenMarkExact': _sevenMarkExact,
      'eightMarkExact': _eightMarkExact,
      'nineMarkExact': _nineMarkExact,
    };
  }
}
