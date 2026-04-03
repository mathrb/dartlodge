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
  final game = await ref.read(gameRepositoryProvider).getGame(gameId);
  if (game == null) return null;

  final competitors =
      await ref.read(gameRepositoryProvider).getCompetitors(gameId);
  final events =
      await ref.read(gameEventRepositoryProvider).getEventsForGame(gameId);

  final engine = switch (game.gameType) {
    GameType.x01 => ref.read(x01EngineProvider),
    GameType.cricket => ref.read(cricketEngineProvider),
    GameType.aroundTheClock => ref.read(aroundTheClockEngineProvider),
    GameType.bobs27 => ref.read(bobs27EngineProvider),
    GameType.shanghai => ref.read(shanghaiEngineProvider),
    GameType.catch40 => ref.read(catch40EngineProvider),
    GameType.checkoutPractice => ref.read(checkoutPracticeEngineProvider),
    _ => throw UnsupportedError('No engine registered for game type: ${game.gameType}'),
  };

  var gs = GameState.initial(game, competitors);
  for (final event in events) {
    gs = engine.apply(gs, event).state;
  }
  return gs;
}
