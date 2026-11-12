import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

/// Tracks whether one player's latest X01 visit finished the leg, so a
/// `LegCompleted` they win can be told apart from a leg decided by the round
/// cap (Table M in `docs/games/x01.transitions.md`: lowest remaining score
/// wins, no checkout).
///
/// Checkout statistics (highest / average checkout, checkout %, double-out
/// successes, the per-leg checkout score) are "tracked from the final scoring
/// dart in each leg" (`docs/statistics/x01.projections.md` §7.3). A cap leg has
/// no such dart, yet it emits the same `LegCompleted{winner_player_id}` as a
/// checkout. Feed every event of the scoped player's stream to [apply] and read
/// [lastVisitCheckedOut] when the player wins a leg.
///
/// A visit is judged from its own events only, so no event or schema change is
/// needed and existing logs replay correctly:
/// - the player's `TurnEnded` (appended before `LegCompleted` for a checkout)
///   is authoritative: not a bust, and `turn_score` equals the visit's
///   `TurnStarted.starting_score`. Without `turn_score` (pre-#318 events) the
///   darts of the visit must bring the remaining score to exactly 0;
/// - with no `TurnEnded` yet, the darts thrown decide the same way;
/// - a visit with no `TurnStarted` seed, or with no darts and no `TurnEnded`,
///   carries no evidence either way and still counts as a checkout, as before
///   this tracker existed.
class X01FinishTracker {
  X01FinishTracker(this.playerId);

  /// The player whose visits are tracked; other players' events are ignored.
  final String? playerId;

  int? _startingScore;
  int? _remaining;
  int _dartsThisVisit = 0;
  bool _dartBusted = false;
  bool? _turnEndedVerdict;

  /// `TurnStarted.starting_score` of the player's latest visit, or null before
  /// the first one. This is the checkout value when [lastVisitCheckedOut].
  int? get lastVisitStartingScore => _startingScore;

  /// Whether the player's latest visit took the remaining score to 0.
  bool get lastVisitCheckedOut {
    final verdict = _turnEndedVerdict;
    if (verdict != null) return verdict;
    if (_startingScore == null || _dartsThisVisit == 0) return true;
    return !_dartBusted && _remaining == 0;
  }

  void reset() {
    _startingScore = null;
    _remaining = null;
    _dartsThisVisit = 0;
    _dartBusted = false;
    _turnEndedVerdict = null;
  }

  void apply(GameEvent event) {
    final payload = event.payload;
    switch (event.eventType) {
      case 'TurnStarted':
        if (payload['player_id'] != playerId) return;
        _startingScore = (payload['starting_score'] as num?)?.toInt();
        _remaining = _startingScore;
        _dartsThisVisit = 0;
        _dartBusted = false;
        _turnEndedVerdict = null;
      case 'DartThrown':
        if (payload['player_id'] != playerId) return;
        _dartsThisVisit++;
        if (payload['bust'] == true) _dartBusted = true;
        final remaining = _remaining;
        if (remaining != null) {
          _remaining = remaining - ((payload['score'] as num?)?.toInt() ?? 0);
        }
      case 'TurnEnded':
        if (payload['player_id'] != playerId) return;
        final start = _startingScore;
        // Without a TurnStarted seed the visit cannot be judged.
        if (start == null) return;
        final turnScore = (payload['turn_score'] as num?)?.toInt();
        final busted = payload['reason'] == 'bust' || _dartBusted;
        _turnEndedVerdict =
            !busted &&
            start > 0 &&
            (turnScore != null ? turnScore == start : _remaining == 0);
    }
  }
}
