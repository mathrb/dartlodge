import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/game_state.dart';
import '../../../../core/persistence/database_provider.dart';
import '../../../../core/utils/constants.dart';

part 'game_replay_provider.g.dart';

/// Loads a game from persistence and replays all recorded events to produce
/// the current [GameState]. Returns null when no game exists for [gameId].
///
/// Each active-game notifier delegates its [build] to this provider so the
/// fetch → initial-state → replay sequence lives in exactly one place.
@riverpod
Future<GameState?> loadedGameState(Ref ref, String gameId) async {
  // Capture all provider references synchronously before any async gaps,
  // so we don't call ref.read() after the provider has been disposed.
  final gameRepo = ref.read(gameRepositoryProvider);
  final eventRepo = ref.read(gameEventRepositoryProvider);
  final engines = {
    GameType.x01: ref.read(x01EngineProvider),
    GameType.cricket: ref.read(cricketEngineProvider),
    GameType.aroundTheClock: ref.read(aroundTheClockEngineProvider),
    GameType.bobs27: ref.read(bobs27EngineProvider),
    GameType.shanghai: ref.read(shanghaiEngineProvider),
    GameType.catch40: ref.read(catch40EngineProvider),
    GameType.checkoutPractice: ref.read(checkoutPracticeEngineProvider),
    GameType.countUp: ref.read(countUpEngineProvider),
  };

  final game = await gameRepo.getGame(gameId);
  if (game == null) return null;

  final engine = engines[game.gameType];
  if (engine == null) {
    throw UnsupportedError('No engine for: ${game.gameType}');
  }

  final competitors = await gameRepo.getCompetitors(gameId);
  final events = await eventRepo.getEventsForGame(gameId);

  // Build skip sets from DartCorrected events so undone darts and the
  // turn-boundary events that bracketed them aren't re-applied on cold load.
  // Without this, an undo that spans a turn boundary leaves a stale
  // TurnStarted in the log; replaying it shifts currentTurnIndex and any
  // later DartThrown gets attributed to the wrong competitor (issue #108).
  final correctedDartIds = <String>{};
  final supersededEventIds = <String>{};
  for (final e in events) {
    if (e.eventType != 'DartCorrected') continue;
    final origId = e.payload['original_event_id'];
    if (origId is String) correctedDartIds.add(origId);
    final superseded = e.payload['superseded_event_ids'];
    if (superseded is List) {
      for (final id in superseded) {
        if (id is String) supersededEventIds.add(id);
      }
    }
  }

  var gs = GameState.initial(game, competitors);
  for (final event in events) {
    if (event.eventType == 'DartThrown' &&
        correctedDartIds.contains(event.eventId)) {
      continue;
    }
    if (supersededEventIds.contains(event.eventId)) {
      continue;
    }
    gs = engine.apply(gs, event).state;
  }
  return gs;
}
