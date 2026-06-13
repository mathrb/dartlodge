import 'dart:convert';

import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

/// A self-contained recorded session (epic #488, sub-issue #492): the
/// auto-scorer detection [trace] plus the correlated game data for the same
/// game — the [events] the darts produced, and the [game] / [competitors]
/// config needed to replay those events through the engine.
///
/// This is the **export artifact** (one JSON file shared off the device) and
/// the input the replay harness loads. It reuses the app's shared game-domain
/// entities (`GameEvent` / `Game` / `Competitor`) directly, exactly as the
/// statistics and history features do — they are the shared event/game model,
/// not another feature's private code.
class SessionBundle {
  final SessionTrace trace;
  final List<GameEvent> events;
  final Game game;
  final List<Competitor> competitors;

  const SessionBundle({
    required this.trace,
    required this.events,
    required this.game,
    required this.competitors,
  });

  Map<String, dynamic> toJson() => {
        // The trace is embedded as its own JSONL string (its canonical wire
        // form) rather than re-modelled, so the trace contract stays the single
        // source of truth.
        'trace': trace.toJsonl(),
        'events': [for (final e in events) e.toJson()],
        'game': game.toJson(),
        'competitors': [for (final c in competitors) c.toJson()],
      };

  factory SessionBundle.fromJson(Map<String, dynamic> json) => SessionBundle(
        trace: SessionTrace.fromJsonl(json['trace'] as String),
        events: [
          for (final e in (json['events'] as List))
            GameEvent.fromJson(e as Map<String, dynamic>)
        ],
        game: Game.fromJson(json['game'] as Map<String, dynamic>),
        competitors: [
          for (final c in (json['competitors'] as List))
            Competitor.fromJson(c as Map<String, dynamic>)
        ],
      );

  /// Serialise to the single-file export form.
  String toJsonString() => jsonEncode(toJson());

  factory SessionBundle.fromJsonString(String source) =>
      SessionBundle.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
