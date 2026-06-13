import 'dart:io';

import 'package:dart_lodge/features/auto_scorer/domain/recording/session_bundle.dart';
import 'package:dart_lodge/features/game/domain/engines/event_replay.dart';
import 'package:dart_lodge/features/game/domain/engines/game_engine_factory.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';

/// Test-only replay harness for recorded auto-scorer sessions (#492). Lives in
/// `test/` because it bridges the auto-scorer trace with the **game engines**
/// (a deeper coupling than the shared game entities); the production code never
/// replays a session through an engine.

/// Load an exported session bundle fixture from
/// `test/fixtures/auto_scorer_sessions/<name>.json`.
SessionBundle loadBundle(String name) => SessionBundle.fromJsonString(
      File('test/fixtures/auto_scorer_sessions/$name.json').readAsStringSync(),
    );

/// Replay the bundle's game events through the matching engine to recover the
/// final [GameState] — for diagnosing "tracker right but score wrong" bugs.
/// Reuses the production-identical `replayEvents` fold + `GameEngineFactory`.
GameState replaySessionGameState(SessionBundle bundle) => replayEvents(
      initial: GameState.initial(bundle.game, bundle.competitors),
      events: bundle.events,
      engine: GameEngineFactory.createEngine(bundle.game.gameType),
    );
