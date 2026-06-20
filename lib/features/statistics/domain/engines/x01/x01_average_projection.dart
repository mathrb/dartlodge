import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';
import 'package:dart_lodge/features/statistics/domain/engines/x01/x01_bust_padding.dart';

class X01AverageProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_average',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {'DartThrown', 'TurnEnded'},
    scope: ProjectionScope.turn,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _totalScoredPoints = 0;
  int _totalDartsThrown = 0;
  int _turnScore = 0;
  int _dartsThisTurn = 0;
  // Extra darts the PDC convention adds for busted visits (#634): a busted
  // visit counts as a full 3-dart visit in the average DENOMINATOR even though
  // the event stream emitted fewer darts. Kept separate from `_totalDartsThrown`
  // so the raw dart count exposed in the snapshot is never inflated.
  int _bustPadDarts = 0;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _totalScoredPoints = 0;
    _totalDartsThrown = 0;
    _turnScore = 0;
    _dartsThisTurn = 0;
    _bustPadDarts = 0;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final seg = (event.payload['segment'] as num?)?.toInt();
        final mult = (event.payload['multiplier'] as num?)?.toInt();
        final score = (seg != null && mult != null)
            ? seg * mult
            : (event.payload['score'] as num?)?.toInt() ?? 0;
        _turnScore += score;
        _totalDartsThrown++;
        _dartsThisTurn++;
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        // Per docs/statistics/x01.projections.md §5.2:
        //   turn_score = turn_start_score - turn_end_score
        // Bust turns score 0; not-in (Double-In) turns also score 0
        // because the engine doesn't deduct the dart values when isIn is
        // false. The producer (ProcessDartUseCase) writes this delta as
        // `turn_score` on the TurnEnded payload (#318). Legacy events
        // that lack the field fall back to the dart-sum the projection
        // has historically accumulated — keeping old-game numbers as
        // they were before the fix.
        final delta = (event.payload['turn_score'] as num?)?.toInt();
        _totalScoredPoints += delta ?? _turnScore;
        // PDC convention (#634): a busted visit is a full 3-dart visit in the
        // average denominator. The event stream emits only the darts thrown
        // before the bust, so add the missing darts here (reason='bust').
        _bustPadDarts +=
            bustDartPadding(event.payload['reason'] as String?, _dartsThisTurn);
        _turnScore = 0;
        _dartsThisTurn = 0;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    if (scope == ProjectionScope.turn) {
      _turnScore = 0;
      _dartsThisTurn = 0;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    // Denominator pads busted visits to 3 darts (#634); `totalDartsThrown`
    // below stays the RAW count (consumers use it as an actual-darts figure).
    final avgDenominator = _totalDartsThrown + _bustPadDarts;
    final avg = avgDenominator > 0
        ? (_totalScoredPoints / avgDenominator * 3)
        : 0.0;
    return {
      'threeDartAverage': avg,
      'totalScoredPoints': _totalScoredPoints,
      // RAW darts actually thrown (consumers use this as an actual-darts count).
      'totalDartsThrown': _totalDartsThrown,
      // Average denominator: raw darts + busted-visit padding (#634). Callers
      // that recompute a three-dart average across players (per-game competitor
      // rollup, per-leg competitor) must divide by THIS, not the raw count.
      'avgDartsDenominator': avgDenominator,
    };
  }
}
