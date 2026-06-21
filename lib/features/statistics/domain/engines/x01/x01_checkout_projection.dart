import 'package:dart_lodge/core/utils/checkout_table.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

/// X01 checkout %: successes / attempts.
///
/// An ATTEMPT is a visit in which the player threw at least one dart from a
/// single-dart finish position for the game's out strategy (#637 — PDC
/// "darts/visits thrown at a double" convention, reusing the shared
/// [isOnAFinish] predicate). This replaces the old "every visit that began
/// ≤170" proxy, which over-counted setup-only visits, bogey numbers
/// (169/168/166/165/163/162/159), and the non-finishing visits of a
/// multi-visit leg.
///
/// `remaining` is reconstructed per visit from `TurnStarted.starting_score`
/// minus each `DartThrown.score` (mirrors [X01DoubleOutProjection]; the dart
/// events carry no `remaining_after`, #185). The check runs BEFORE subtracting
/// each dart's score, so a dart thrown from a finish position that then busts
/// still counts as an attempt. The attempt is tallied on the player's
/// `TurnEnded` (always emitted, including for the leg-winning visit, which the
/// producer appends before `LegCompleted`) so each visit is counted exactly
/// once. A SUCCESS is a `LegCompleted` won by the player.
class X01CheckoutProjection extends ProjectionEngine {
  static const _kDescriptor = ProjectionDescriptor(
    id: 'x01_checkout',
    supportedGameTypes: {GameType.x01},
    consumedEventTypes: {
      'TurnStarted',
      'DartThrown',
      'TurnEnded',
      'LegCompleted',
    },
    scope: ProjectionScope.leg,
  );

  @override
  ProjectionDescriptor get descriptor => _kDescriptor;

  ProjectionContext? _context;
  int _checkoutAttempts = 0;
  int _successfulCheckouts = 0;

  // Score remaining BEFORE the next dart of the current visit; seeded from
  // `TurnStarted.starting_score`, decremented per `DartThrown.score`. Null
  // between visits / before the first seed.
  int? _currentTurnRemaining;
  // Whether the current visit has thrown at least one dart from a finish
  // position — i.e. this visit is a checkout attempt.
  bool _threwAtFinish = false;

  @override
  void init(ProjectionContext context) {
    _context = context;
    _checkoutAttempts = 0;
    _successfulCheckouts = 0;
    _currentTurnRemaining = null;
    _threwAtFinish = false;
  }

  @override
  void apply(GameEvent event) {
    switch (event.eventType) {
      case 'TurnStarted':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        _currentTurnRemaining =
            (event.payload['starting_score'] as num?)?.toInt();
        _threwAtFinish = false;
      case 'DartThrown':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        final remaining = _currentTurnRemaining;
        // Without a TurnStarted seed we cannot judge the position; skip.
        if (remaining == null) return;
        if (isOnAFinish(remaining, _context?.outStrategy ?? 'double')) {
          _threwAtFinish = true;
        }
        final score = (event.payload['score'] as num?)?.toInt() ?? 0;
        _currentTurnRemaining = remaining - score;
      case 'TurnEnded':
        final playerId = event.payload['player_id'] as String?;
        if (playerId != _context?.playerId) return;
        if (_threwAtFinish) _checkoutAttempts++;
        _threwAtFinish = false;
        _currentTurnRemaining = null;
      case 'LegCompleted':
        final winnerId = event.payload['winner_player_id'] as String?;
        if (winnerId == _context?.playerId) _successfulCheckouts++;
    }
  }

  @override
  void reset(ProjectionScope scope) {
    // cumulative career stat — attempts/successes never reset. Clear the
    // per-visit scratch on leg/match boundaries for robustness if the runner
    // ever feeds events out of turn-bounded order.
    if (scope == ProjectionScope.leg || scope == ProjectionScope.match) {
      _currentTurnRemaining = null;
      _threwAtFinish = false;
    }
  }

  @override
  Map<String, dynamic> snapshot() {
    final checkoutPercentage = _checkoutAttempts > 0
        ? (_successfulCheckouts / _checkoutAttempts * 100)
        : null;
    return {
      'checkoutPercentage': checkoutPercentage,
      'checkoutAttempts': _checkoutAttempts,
      'successfulCheckouts': _successfulCheckouts,
    };
  }
}
