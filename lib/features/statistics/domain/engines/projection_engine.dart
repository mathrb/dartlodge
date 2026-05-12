import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

enum ProjectionScope { dart, turn, leg, match, career }

class ProjectionContext {
  final String playerId;
  final GameType gameType;
  final String inStrategy;
  final String outStrategy;
  final List<String> playerIds;
  // Games with a single competitor. Projections that should only count
  // multiplayer outcomes (e.g. legs won) skip events whose gameId is in this
  // set. Empty when the caller does not know or does not care.
  final Set<String> soloGameIds;

  const ProjectionContext({
    required this.playerId,
    required this.gameType,
    required this.inStrategy,
    required this.outStrategy,
    required this.playerIds,
    this.soloGameIds = const {},
  });
}

class ProjectionDescriptor {
  final String id;
  final Set<GameType> supportedGameTypes;
  final Set<String> consumedEventTypes;
  final ProjectionScope scope;

  const ProjectionDescriptor({
    required this.id,
    required this.supportedGameTypes,
    required this.consumedEventTypes,
    required this.scope,
  });
}

abstract class ProjectionEngine {
  ProjectionDescriptor get descriptor;
  void init(ProjectionContext context);
  void apply(GameEvent event);
  void reset(ProjectionScope scope);
  Map<String, dynamic> snapshot();
}
