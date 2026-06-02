// Database Provider
// Contains Riverpod providers for database and repository access

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drift/drift_helper.dart';
import 'drift/database.dart';
import 'drift/repositories/player_repository_drift.dart';
import 'drift/repositories/game_repository_drift.dart';
import 'drift/repositories/dart_throw_repository_drift.dart';
import 'drift/repositories/game_event_repository_drift.dart';
import 'drift/repositories/statistics_repository_drift.dart';
import '../../features/players/domain/repositories/player_repository.dart';
import '../../features/players/domain/usecases/create_player_use_case.dart';
import '../../features/game/domain/repositories/game_repository.dart';
import '../../features/game/domain/repositories/dart_throw_repository.dart';
import '../../features/game/domain/repositories/game_event_repository.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/domain/usecases/compute_leg_stats_use_case.dart';
import '../../features/game/domain/engines/stateless_x01_engine.dart';
import '../../features/game/domain/engines/stateless_cricket_engine.dart';
import '../../features/game/domain/engines/stateless_around_the_clock_engine.dart';
import '../../features/game/domain/engines/stateless_bobs_27_engine.dart';
import '../../features/game/domain/engines/stateless_shanghai_engine.dart';
import '../../features/game/domain/engines/stateless_catch_40_engine.dart';
import '../../features/game/domain/engines/stateless_checkout_practice_engine.dart';
import '../../features/game/domain/engines/stateless_count_up_engine.dart';
import '../../features/game/domain/usecases/process_dart_use_case.dart';
import '../../features/game/domain/usecases/process_cricket_dart_use_case.dart';
import '../../features/game/domain/usecases/process_practice_dart_use_case.dart';
import '../../features/game/domain/usecases/end_practice_use_case.dart';
import '../../features/game/domain/usecases/get_game_result_use_case.dart';
import '../../features/game/domain/usecases/undo_last_dart_use_case.dart';
import '../../features/game/domain/usecases/correct_dart_use_case.dart';
import '../../features/game/domain/usecases/create_game_use_case.dart';
import '../../features/game/domain/models/game_config.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

@Riverpod(keepAlive: true)
Future<AppDatabase> database(Ref ref) => DriftHelper.instance.database;

@Riverpod(keepAlive: true)
PlayerRepository playerRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return PlayerRepositoryDrift(db);
}

@Riverpod(keepAlive: true)
CreatePlayerUseCase createPlayerUseCase(Ref ref) =>
    CreatePlayerUseCase(ref.watch(playerRepositoryProvider));

@Riverpod(keepAlive: true)
GameRepository gameRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return GameRepositoryDrift(db);
}

@Riverpod(keepAlive: true)
DartThrowRepository dartThrowRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return DartThrowRepositoryDrift(db);
}

@Riverpod(keepAlive: true)
GameEventRepository gameEventRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return GameEventRepositoryDrift(db);
}

@Riverpod(keepAlive: true)
ComputeLegStatsUseCase computeLegStatsUseCase(Ref ref) =>
    const ComputeLegStatsUseCase();

@Riverpod(keepAlive: true)
StatisticsRepository statisticsRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return StatisticsRepositoryDrift(db);
}

@Riverpod(keepAlive: true)
StatelessX01Engine x01Engine(Ref ref) {
  return StatelessX01Engine();
}

@Riverpod(keepAlive: true)
ProcessDartUseCase processDartUseCase(Ref ref) {
  return ProcessDartUseCase(
    ref.watch(gameRepositoryProvider),
    ref.watch(gameEventRepositoryProvider),
    ref.watch(dartThrowRepositoryProvider),
    ref.watch(x01EngineProvider),
  );
}

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoLastDartUseCase(Ref ref) {
  return UndoLastDartUseCase(
    ref.watch(gameEventRepositoryProvider),
    ref.watch(dartThrowRepositoryProvider),
    ref.watch(x01EngineProvider),
  );
}

@Riverpod(keepAlive: true)
StatelessCricketEngine cricketEngine(Ref ref) => StatelessCricketEngine();

@Riverpod(keepAlive: true)
ProcessCricketDartUseCase processCricketDartUseCase(Ref ref) =>
    ProcessCricketDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(cricketEngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoCricketLastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(cricketEngineProvider),
    );

// Per-dart correction (issue #376). Reuses the per-engine undo + ProcessDart
// mutators; the process step is injected as a function so X01's
// ProcessDartUseCase and Cricket's ProcessCricketDartUseCase share one class.
@Riverpod(keepAlive: true)
CorrectDartUseCase correctDartUseCase(Ref ref) => CorrectDartUseCase(
      ref.watch(undoLastDartUseCaseProvider),
      ref.watch(processDartUseCaseProvider).execute,
      ref.watch(gameEventRepositoryProvider),
    );

@Riverpod(keepAlive: true)
CorrectDartUseCase correctCricketDartUseCase(Ref ref) => CorrectDartUseCase(
      ref.watch(undoCricketLastDartUseCaseProvider),
      ref.watch(processCricketDartUseCaseProvider).execute,
      ref.watch(gameEventRepositoryProvider),
    );

@Riverpod(keepAlive: true)
CreateGameUseCase createGameUseCase(Ref ref) {
  return CreateGameUseCase(
    ref.watch(gameRepositoryProvider),
    ref.watch(gameEventRepositoryProvider),
    ref.watch(playerRepositoryProvider),
  );
}

// Practice engines
@Riverpod(keepAlive: true)
StatelessAroundTheClockEngine aroundTheClockEngine(Ref ref) =>
    StatelessAroundTheClockEngine();

@Riverpod(keepAlive: true)
StatelessBobs27Engine bobs27Engine(Ref ref) => StatelessBobs27Engine();

@Riverpod(keepAlive: true)
StatelessShanghaiEngine shanghaiEngine(Ref ref) => StatelessShanghaiEngine();

@Riverpod(keepAlive: true)
StatelessCatch40Engine catch40Engine(Ref ref) => StatelessCatch40Engine();

@Riverpod(keepAlive: true)
StatelessCheckoutPracticeEngine checkoutPracticeEngine(Ref ref) =>
    StatelessCheckoutPracticeEngine();

@Riverpod(keepAlive: true)
StatelessCountUpEngine countUpEngine(Ref ref) => StatelessCountUpEngine();

/// Count-up reuses the X01-shaped ProcessDartUseCase: DartThrown is purely
/// additive (no bust, no leg-end mid-dart), so the same scaffolding works.
/// Game-end detection happens on TurnEnded inside the count-up engine — see
/// ActiveCountUpNotifier._startNextTurn for the surrounding orchestration.
@Riverpod(keepAlive: true)
ProcessDartUseCase processCountUpDartUseCase(Ref ref) => ProcessDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(countUpEngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoCountUpLastDartUseCase(Ref ref) => UndoLastDartUseCase(
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(countUpEngineProvider),
    );

// ProcessPracticeDartUseCase providers — one per practice game type
@Riverpod(keepAlive: true)
ProcessPracticeDartUseCase processAroundTheClockDartUseCase(Ref ref) =>
    ProcessPracticeDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(aroundTheClockEngineProvider),
    );

@Riverpod(keepAlive: true)
ProcessPracticeDartUseCase processBobs27DartUseCase(Ref ref) =>
    ProcessPracticeDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(bobs27EngineProvider),
    );

@Riverpod(keepAlive: true)
ProcessPracticeDartUseCase processShanghaiDartUseCase(Ref ref) =>
    ProcessPracticeDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(shanghaiEngineProvider),
    );

@Riverpod(keepAlive: true)
ProcessPracticeDartUseCase processCatch40DartUseCase(Ref ref) =>
    ProcessPracticeDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(catch40EngineProvider),
    );

@Riverpod(keepAlive: true)
ProcessPracticeDartUseCase processCheckoutPracticeDartUseCase(Ref ref) =>
    ProcessPracticeDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(checkoutPracticeEngineProvider),
    );

// UndoLastDartUseCase providers — one per practice game type
@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeAroundTheClockLastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(aroundTheClockEngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeBobs27LastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(bobs27EngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeShanghaiLastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(shanghaiEngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeCatch40LastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(catch40EngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeCheckoutPracticeLastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(checkoutPracticeEngineProvider),
    );

// Practice drill exit use case ("End Drill") — works for every practice type
@Riverpod(keepAlive: true)
EndPracticeUseCase endPracticeUseCase(Ref ref) =>
    EndPracticeUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
    );

// Post-game result use case for practice drills + Shanghai. Consumed by
// `gameResultProvider` in `core/providers/statistics_providers.dart`.
@Riverpod(keepAlive: true)
GetGameResultUseCase getGameResultUseCase(Ref ref) => GetGameResultUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(aroundTheClockEngineProvider),
      ref.watch(catch40EngineProvider),
      ref.watch(bobs27EngineProvider),
      ref.watch(shanghaiEngineProvider),
      ref.watch(checkoutPracticeEngineProvider),
    );

/// Persists the last-used [GameConfig] per game category ('x01' or 'cricket').
/// Used by VariantSelectionPage to show a "Last Used" quick-start tile.
@Riverpod(keepAlive: true)
class LastGameConfig extends _$LastGameConfig {
  static const _keyPrefix = 'last_config_';

  @override
  Future<GameConfig?> build(String category) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final raw = prefs.getString('$_keyPrefix$category');
    if (raw == null) return null;
    try {
      return GameConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(GameConfig config) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final json = jsonEncode(config.toJson());
    await prefs.setString('$_keyPrefix$category', json);
    state = AsyncData(config);
  }
}

@riverpod
Future<void> Function() clearAllData(Ref ref) {
  return () async {
    await DriftHelper.instance.clearAllData();
  };
}
