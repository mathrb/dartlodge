// Active Game Provider
// Riverpod notifier for managing the active game state

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/game_state.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/competitor.dart';
import '../../domain/usecases/process_dart_use_case.dart';
import '../../../../core/persistence/database_provider.dart';

part 'active_game_provider.g.dart';

@riverpod
class ActiveGame extends _$ActiveGame {
  @override
  Future<GameState?> build() async {
    final gameRepository = ref.watch(gameRepositoryProvider);
    final activeGame = await gameRepository.getActiveGame();
    
    if (activeGame == null) return null;

    // Get competitors for the game
    final competitors = await gameRepository.getCompetitors(activeGame.gameId);
    
    // Get all events for the game
    final gameEventRepository = ref.watch(gameEventRepositoryProvider);
    final events = await gameEventRepository.getEventsForGame(activeGame.gameId);
    
    if (events.isEmpty) return null;

    // Reconstruct game state by replaying all events
    final engine = ref.watch(x01EngineProvider);
    var state = GameState.initial(activeGame, competitors);
    
    for (final event in events) {
      state = engine.apply(state, event);
    }
    
    return state;
  }

  Future<void> processDart(DartThrow dartThrow) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final useCase = ProcessDartUseCase(
        ref.read(gameEventRepositoryProvider),
        ref.read(dartThrowRepositoryProvider),
      );
      
      return await useCase.execute(currentState, dartThrow);
    });
  }
}
