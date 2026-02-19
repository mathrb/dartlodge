// Active Game Provider
// Riverpod notifier for managing the active game state

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/game_state.dart';
import '../../domain/entities/dart_throw.dart';
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
    
    // In a real implementation, we would reconstruct the GameState from events
    // For now, we return null to avoid errors until reconstruction is implemented
    return null;
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
