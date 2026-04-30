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
    final sorted = [...events]
      ..sort((a, b) => a.localSequence.compareTo(b.localSequence));

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
