import 'package:dart_lodge/core/game/dart_input_sink.dart';
import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_scorer_providers.g.dart';

const _kUseAutoScoringKey = 'auto_scorer_use';

/// Master "Use auto-scoring" switch (#382 §5.1), default **off**. Distinct from
/// the data-collection opt-in (#381). Lives in `core/` because it is read both
/// by the auto_scorer feature (whether to run the camera) and the game board
/// (whether to offer the assist entry point) — a cross-feature concern.
@Riverpod(keepAlive: true)
class AutoScoringEnabled extends _$AutoScoringEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kUseAutoScoringKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kUseAutoScoringKey, enabled);
    state = AsyncData(enabled);
  }
}

/// Holds the [DartInputSink] of the currently active game board, so the
/// auto-scorer can emit detected darts without importing the game feature. The
/// board binds itself on entry and clears on exit.
@Riverpod(keepAlive: true)
class ActiveDartInputSink extends _$ActiveDartInputSink {
  @override
  DartInputSink? build() => null;

  void bind(DartInputSink? sink) => state = sink;
}

/// A monotonically increasing counter bumped by the game board whenever the
/// **turn advances** (manual next-turn). The auto-scorer listens so it can reset
/// the per-turn 3-dart cap in lock-step — without this, advancing via the
/// board's own next button (which can't reach the tracker) would wedge the cap
/// and silently block the next player's darts (#380 / #382 rework). Cross-feature
/// via `core/`, mirroring the sink bridge.
@Riverpod(keepAlive: true)
class ActiveTurnSignal extends _$ActiveTurnSignal {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}
