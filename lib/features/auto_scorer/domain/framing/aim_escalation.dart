/// How long the aim view lets the player keep aiming before it explains itself
/// (#743, design S2.1).
///
/// Long enough that a normal aim — mount the phone, frame the board, wait for
/// the markers — is never interrupted; short enough that a setup the model
/// simply cannot read does not leave the player re-framing forever.
const Duration kAimExplainAfter = Duration(seconds: 10);

/// Whether the aim view should replace its one-line hint with the explanation
/// panel.
///
/// Purely presentational and time-based: it changes what is on screen, never
/// what the detector does or which actions are available. The confirm button
/// keeps its "Continue without auto-scoring" behaviour whether or not the panel
/// is up.
///
/// * [withoutRecognition] — how long the view has gone without the four
///   markers. The caller restarts it whenever recognition succeeds.
/// * [recognisedNow] — the four markers are present in the latest frame; the
///   panel gets out of the way immediately, because the problem it explains has
///   just solved itself.
/// * [keepAimingChosen] — the player took the panel's secondary action. It
///   holds until the next successful recognition, so the panel cannot nag every
///   [after] seconds; the caller clears it when recognition returns (see
///   [withoutRecognition]).
bool shouldExplainAim({
  required Duration withoutRecognition,
  required bool recognisedNow,
  required bool keepAimingChosen,
  Duration after = kAimExplainAfter,
}) {
  if (recognisedNow || keepAimingChosen) return false;
  return withoutRecognition >= after;
}
