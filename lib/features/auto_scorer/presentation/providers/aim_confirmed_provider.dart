import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'aim_confirmed_provider.g.dart';

/// Whether the user has completed the full-screen aim step once during THIS app
/// run (#687). In-memory only (NOT persisted): a `keepAlive` provider lives for
/// the app-session lifetime and resets on restart — exactly the "skip setup for
/// the next consecutive game, but re-prompt after a relaunch (where the phone
/// was likely re-mounted)" semantics we want.
///
/// When true, [AutoScorerBoardOverlay] skips the aim view on the next camera
/// start and goes straight to the running preview. Scoring is unaffected: the
/// running preview re-derives the board transform live from each frame's
/// calibration points, so the aim step is only a positioning confidence gate.
/// The "Re-aim" button in the running preview re-runs it when the phone moved.
@Riverpod(keepAlive: true)
class AutoScorerAimConfirmed extends _$AutoScorerAimConfirmed {
  @override
  bool build() => false;

  void set(bool confirmed) => state = confirmed;
}
