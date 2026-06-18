import '../models/game_state.dart';

/// Facts about the cricket dart just thrown between [prev] and [next], or null
/// if this state change isn't a single new dart.
///
/// Like `newestDartSegment`, this is gated on `dartsThrownInTurn` incrementing by
/// exactly one on the same competitor (so turn-end / undo / reset emissions are
/// ignored). The cricket board maps these facts to a [SoundCue] in the
/// presentation layer (this stays pure — no `core/sound` coupling):
/// - `marks` = marks the dart actually scored = the active competitor's
///   `marksPerNumber` total delta (0..3; Bull is a `marksPerNumber` key, so bull
///   marks count). Robust to the 3-mark cap, overflow, and all target modes.
/// - `scoredPoints` = the summed score of all competitors increased — true in
///   standard (thrower's own score) and cut-throat (opponents' score), false in
///   the no-score variant.
({int marks, bool scoredPoints})? cricketDartOutcome(
  GameState? prev,
  GameState? next,
) {
  if (prev == null || next == null) return null;
  if (next.currentTurnIndex != prev.currentTurnIndex) return null;
  if (next.dartsThrownInTurn != prev.dartsThrownInTurn + 1) return null;

  final marks = _marks(next.competitors[next.currentTurnIndex]) -
      _marks(prev.competitors[prev.currentTurnIndex]);
  final scoredPoints = _totalScore(next) != _totalScore(prev);
  return (marks: marks, scoredPoints: scoredPoints);
}

int _marks(CompetitorState c) =>
    c.marksPerNumber.values.fold(0, (a, v) => a + v);

int _totalScore(GameState s) =>
    s.competitors.fold(0, (a, c) => a + c.score);
