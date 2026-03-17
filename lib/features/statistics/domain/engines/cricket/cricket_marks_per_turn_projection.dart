import 'package:my_darts/core/utils/constants.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/engines/projection_engine.dart';

/// Computes Marks Per Turn (MPT) — the primary cricket metric.
/// A mark is one hit on a valid cricket target (15–20, Bull).
/// Throwing T20 = 3 marks; DB = 2 marks (Bull = 25 → 1 mark, but hit value
/// is determined by multiplier on segment value).
/// MPT = total marks / total turns.
class CricketMarksPerTurnProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'cricket.mpt',
    supportedGameTypes: {GameType.cricket},
    consumedEventTypes: {'DartThrown', 'TurnEnded'},
    scope: ProjectionScope.turn,
  );

  static const _cricketTargets = {15, 16, 17, 18, 19, 20, 25};

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _totalMarks = 0;
  int _totalTurns = 0;
  int _turnMarks = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _totalMarks = 0;
    _totalTurns = 0;
    _turnMarks = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final segment = event.payload['segment'] as String?;
        if (segment == null) return;
        final parsed = _parseSegment(segment);
        if (parsed != null && _cricketTargets.contains(parsed.numericValue)) {
          _turnMarks += parsed.multiplier;
        }
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _totalMarks += _turnMarks;
        _totalTurns++;
        _turnMarks = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _turnMarks = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    final mpt = _totalTurns > 0 ? _totalMarks / _totalTurns : 0.0;
    return {
      'marksPerTurn': mpt,
      'totalMarks': _totalMarks,
      'totalTurns': _totalTurns,
    };
  }
}

class _ParsedSegment {
  final int numericValue;
  final int multiplier;
  const _ParsedSegment(this.numericValue, this.multiplier);
}

_ParsedSegment? _parseSegment(String segment) {
  if (segment == 'DB') return const _ParsedSegment(25, 2);
  if (segment == 'SB') return const _ParsedSegment(25, 1);
  if (segment == 'MISS') return null;
  if (segment.startsWith('T')) {
    final n = int.tryParse(segment.substring(1));
    return n != null ? _ParsedSegment(n, 3) : null;
  }
  if (segment.startsWith('D')) {
    final n = int.tryParse(segment.substring(1));
    return n != null ? _ParsedSegment(n, 2) : null;
  }
  final n = int.tryParse(segment);
  return n != null ? _ParsedSegment(n, 1) : null;
}
