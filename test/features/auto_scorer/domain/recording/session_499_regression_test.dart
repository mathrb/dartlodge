import 'package:dart_lodge/features/auto_scorer/domain/recording/session_replayer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/tracker_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_replay_harness.dart';

/// Regression for #499: a transient empty-board reading (a dart-detection
/// flicker / brief darts-only occlusion, cals still visible) was treated as a
/// real pull — clearing the baseline (premature turn advance) and re-emitting
/// the same physical dart (double count) when it reappeared.
///
/// The fixture `single_dart_d11_flicker.json` is a real device session
/// (epic #488) on an essentially static single-dart board. As recorded (with
/// the old `empty_frames_to_rebaseline: 3`, ≈1s at 3 Hz) it produced 4 spurious
/// `rebaselined` frames — each followed by a `turn_advanced` — and twice
/// re-emitted the same dart as `D11`. Its embedded tracker config has been
/// edited to the fixed default (K=9, ≈3s) so a replay exercises the fix; the
/// `SessionReplayer` rebuilds the tracker from that embedded config.
void main() {
  test('#499: the fixed clear window kills the false clears + re-emissions', () {
    final bundle = loadBundle('single_dart_d11_flicker');
    final result = const SessionReplayer().replay(bundle.trace);

    // The recorded outcomes are the buggy ones; the fixed tracker must diverge.
    expect(result.isFaithful, isFalse,
        reason: 'the K=9 replay must differ from the K=3 buggy recording');

    final replayedPhases = [for (final f in result.frames) f.replayed.status.phase];
    final replayedEmissions = [
      for (final f in result.frames) ...f.replayed.newDarts
    ];

    // Core of the fix: no transient empty reading on a still-calibrated board
    // is ever escalated to a board-clear.
    expect(replayedPhases, isNot(contains(TrackerPhase.rebaselined)),
        reason: 'a transient empty board must not be treated as a pull (#499)');

    // The spurious D11 was the double-count signature of the re-emission after
    // a false clear — it must no longer appear.
    expect(
      replayedEmissions.where((e) => e.emitted).map((e) => e.segment),
      isNot(contains('D11')),
      reason: 'the same physical dart must not be re-emitted as a double',
    );
  });
}
