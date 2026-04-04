import '../entities/game_event.dart';
import '../models/game_state.dart';
import '../../../../core/error/repository_exception.dart';
import '../../../../core/utils/constants.dart';
import 'package:uuid/uuid.dart';

/// Returns the player ID for the competitor currently throwing.
/// Throws [InvalidGameStateException] if the competitor is not found.
/// Returns 'system' if the competitor has no players.
String getCurrentPlayerId(GameState state, String competitorId) {
  final competitor = state.competitors.firstWhere(
    (c) => c.competitorId == competitorId,
    orElse: () => throw const InvalidGameStateException('Competitor not found'),
  );
  return competitor.playerIds.isNotEmpty ? competitor.playerIds.first : 'system';
}

/// Returns the player ID for the given competitor ID, or '' if null/not found.
/// Used for optional winner/context payloads where a missing ID is non-fatal.
String getPlayerIdForCompetitor(GameState state, String? competitorId) {
  if (competitorId == null) return '';
  final matches = state.competitors.where((c) => c.competitorId == competitorId);
  if (matches.isEmpty) return '';
  final competitor = matches.first;
  return competitor.playerIds.isNotEmpty ? competitor.playerIds.first : '';
}

GameEvent buildDartThrownEvent({
  required String gameId,
  required String dartId,
  required String competitorId,
  required String actorId,
  required int localSequence,
  required int segment,
  required int multiplier,
  int? score,
  String? playerId,
}) {
  return GameEvent(
    eventId: dartId,
    gameId: gameId,
    eventType: 'DartThrown',
    localSequence: localSequence,
    occurredAt: DateTime.now(),
    payload: {
      'competitor_id': competitorId,
      if (playerId != null) 'player_id': playerId,
      'segment': segment,
      'multiplier': multiplier,
      if (score != null) 'score': score,
      'input_method': 'manual',
    },
    synced: false,
    actorId: actorId,
    source: EventSource.client,
  );
}

GameEvent buildTurnEndedEvent({
  required String gameId,
  required String competitorId,
  required String playerId,
  required int localSequence,
  String actorId = 'system',
  String reason = 'normal',
}) {
  return GameEvent(
    eventId: const Uuid().v4(),
    gameId: gameId,
    eventType: 'TurnEnded',
    localSequence: localSequence,
    occurredAt: DateTime.now(),
    payload: {
      'competitor_id': competitorId,
      'player_id': playerId,
      'reason': reason,
    },
    synced: false,
    actorId: actorId,
    source: EventSource.client,
  );
}

GameEvent buildLegCompletedEvent({
  required String gameId,
  required String? winnerCompetitorId,
  required int localSequence,
  String? winnerPlayerId,
}) {
  return GameEvent(
    eventId: const Uuid().v4(),
    gameId: gameId,
    eventType: 'LegCompleted',
    localSequence: localSequence,
    occurredAt: DateTime.now(),
    payload: {
      'winner_competitor_id': winnerCompetitorId,
      if (winnerPlayerId != null) 'winner_player_id': winnerPlayerId,
    },
    synced: false,
    actorId: 'system',
    source: EventSource.client,
  );
}

GameEvent buildGameCompletedEvent({
  required String gameId,
  required String? winnerCompetitorId,
  required int localSequence,
  String? winnerPlayerId,
}) {
  return GameEvent(
    eventId: const Uuid().v4(),
    gameId: gameId,
    eventType: 'GameCompleted',
    localSequence: localSequence,
    occurredAt: DateTime.now(),
    payload: {
      'winner_id': winnerCompetitorId,
      if (winnerPlayerId != null) 'winner_player_id': winnerPlayerId,
    },
    synced: false,
    actorId: 'system',
    source: EventSource.client,
  );
}

GameEvent buildTurnStartedEvent({
  required String gameId,
  required String competitorId,
  required String playerId,
  required int localSequence,
  required int turnIndex,
  required int legIndex,
  int? startingScore,
  String actorId = 'system',
}) {
  return GameEvent(
    eventId: const Uuid().v4(),
    gameId: gameId,
    eventType: 'TurnStarted',
    localSequence: localSequence,
    occurredAt: DateTime.now(),
    payload: {
      'competitor_id': competitorId,
      'player_id': playerId,
      if (startingScore != null) 'starting_score': startingScore,
      'turn_index': turnIndex,
      'leg_index': legIndex,
    },
    synced: false,
    actorId: actorId,
    source: EventSource.client,
  );
}

/// Generic scaffolding helper — use when a typed event builder doesn't exist.
/// Handles UUID, timestamp, synced=false, and EventSource.client.
GameEvent buildGameEvent({
  required String gameId,
  required String eventType,
  required int localSequence,
  required String actorId,
  required Map<String, dynamic> payload,
}) {
  return GameEvent(
    eventId: const Uuid().v4(),
    gameId: gameId,
    eventType: eventType,
    localSequence: localSequence,
    occurredAt: DateTime.now(),
    payload: payload,
    synced: false,
    actorId: actorId,
    source: EventSource.client,
  );
}
