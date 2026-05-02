import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/engines/projection_engine.dart';

class ProjectionRunner {
  final List<ProjectionEngine> _engines;
  ProjectionContext? _context;

  ProjectionRunner(List<ProjectionEngine> engines)
      : _engines = List.unmodifiable(engines);

  void init(ProjectionContext context) {
    _context = context;
    for (final engine in _engines) {
      engine.init(context);
    }
  }

  void run(List<GameEvent> events) {
    // Sort by gameId first so events from different games stay contiguous —
    // local_sequence restarts at 1 per game, so ordering by it alone would
    // interleave games and corrupt projection state across game boundaries.
    final sorted = [...events]
      ..sort((a, b) {
        final byGame = a.gameId.compareTo(b.gameId);
        if (byGame != 0) return byGame;
        return a.localSequence.compareTo(b.localSequence);
      });

    for (final event in sorted) {
      // Before apply: TurnStarted resets turn scope
      if (event.eventType == 'TurnStarted') {
        for (final engine in _engines) engine.reset(ProjectionScope.turn);
      }

      // Apply to engines that consume this event type
      for (final engine in _engines) {
        if (engine.descriptor.consumedEventTypes.contains(event.eventType)) {
          engine.apply(event);
        }
      }

      // After apply: LegCompleted → reset leg; GameCompleted → reset match
      if (event.eventType == 'LegCompleted') {
        for (final engine in _engines) engine.reset(ProjectionScope.leg);
      } else if (event.eventType == 'GameCompleted') {
        for (final engine in _engines) engine.reset(ProjectionScope.match);
      }
    }
  }

  Map<String, Map<String, dynamic>> snapshot() => {
        for (final engine in _engines) engine.descriptor.id: engine.snapshot(),
      };

  void replayFrom(List<GameEvent> allEvents, int fromSequence) {
    final context = _context;
    if (context == null) throw StateError('init() must be called before replayFrom()');
    for (final engine in _engines) engine.init(context);
    final filtered = allEvents
        .where((e) => e.localSequence >= fromSequence)
        .toList();
    run(filtered);
  }
}
