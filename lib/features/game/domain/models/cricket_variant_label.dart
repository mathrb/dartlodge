/// Title Case label for a cricket game's `scoring × targetMode` pair.
///
/// The shared rule (see `docs/rules/cricket.md`):
///   - fixed targets → the scoring alone ("Standard", "Cut Throat",
///     "No Score");
///   - random/crazy + standard scoring → just the mode ("Random", "Crazy");
///   - random/crazy + other scoring → "Mode · Scoring" ("Crazy · Cut Throat").
///
/// The names are darts jargon and stay English in every locale, like the
/// X01 In/Out strategy names. The history list keeps its own lowercase
/// variant of the same rule (`game_summary_card_widget.dart`).
String cricketVariantLabel({
  required String scoring,
  required String targetMode,
}) {
  final scoringLabel = switch (scoring) {
    'cut-throat' => 'Cut Throat',
    'no-score' => 'No Score',
    _ => 'Standard',
  };
  final modeLabel = switch (targetMode) {
    'random' => 'Random',
    'crazy' => 'Crazy',
    _ => null,
  };
  if (modeLabel == null) return scoringLabel;
  return scoring == 'standard' ? modeLabel : '$modeLabel · $scoringLabel';
}
