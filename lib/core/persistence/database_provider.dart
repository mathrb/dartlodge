// Database Provider
// Contains Riverpod providers for database and repository access

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'drift/drift_helper.dart';
import 'drift/database.dart';
import 'drift/repositories/player_repository_drift.dart';
import 'drift/repositories/game_repository_drift.dart';
import 'drift/repositories/dart_throw_repository_drift.dart';
import 'drift/repositories/game_event_repository_drift.dart';
import 'drift/repositories/statistics_repository_drift.dart';
import '../../features/players/domain/repositories/player_repository.dart';
import '../../features/players/data/repositories/player_repository_impl.dart';
import '../../features/game/domain/repositories/game_repository.dart';
import '../../features/game/data/repositories/game_repository_impl.dart';
import '../../features/game/domain/repositories/dart_throw_repository.dart';
import '../../features/game/data/repositories/dart_throw_repository_impl.dart';
import '../../features/game/domain/repositories/game_event_repository.dart';
import '../../features/game/data/repositories/game_event_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/game/domain/engines/stateless_x01_engine.dart';
import '../../features/game/domain/engines/stateless_cricket_engine.dart';
import '../../features/game/domain/engines/stateless_around_the_clock_engine.dart';
import '../../features/game/domain/engines/stateless_bobs_27_engine.dart';
import '../../features/game/domain/engines/stateless_shanghai_engine.dart';
import '../../features/game/domain/engines/stateless_catch_40_engine.dart';
import '../../features/game/domain/engines/stateless_checkout_practice_engine.dart';
import '../../features/game/domain/usecases/process_dart_use_case.dart';
import '../../features/game/domain/usecases/process_cricket_dart_use_case.dart';
import '../../features/game/domain/usecases/process_practice_dart_use_case.dart';
import '../../features/game/domain/usecases/end_checkout_practice_use_case.dart';
import '../../features/game/domain/usecases/undo_last_dart_use_case.dart';
import '../../features/game/domain/usecases/create_game_use_case.dart';
import '../../features/game/domain/models/game_config.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

// Database provider - platform specific
@Riverpod(keepAlive: true)
Future<dynamic> database(Ref ref) async {
  if (kIsWeb) {
    // Use Drift for web
    return await DriftHelper.instance.database;
  } else {
    // Use SQLite for mobile
    return await DatabaseHelper.instance.database;
  }
}

@Riverpod(keepAlive: true)
PlayerRepository playerRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  
  if (kIsWeb) {
    return PlayerRepositoryDrift(db as AppDatabase);
  } else {
    return PlayerRepositoryImpl(db as Database);
  }
}

@Riverpod(keepAlive: true)
GameRepository gameRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  
  if (kIsWeb) {
    return GameRepositoryDrift(db as AppDatabase);
  } else {
    return GameRepositoryImpl(db as Database);
  }
}

@Riverpod(keepAlive: true)
DartThrowRepository dartThrowRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  
  if (kIsWeb) {
    return DartThrowRepositoryDrift(db as AppDatabase);
  } else {
    return DartThrowRepositoryImpl(db as Database);
  }
}

@Riverpod(keepAlive: true)
GameEventRepository gameEventRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  
  if (kIsWeb) {
    return GameEventRepositoryDrift(db as AppDatabase);
  } else {
    return GameEventRepositoryImpl(db as Database);
  }
}

@Riverpod(keepAlive: true)
StatisticsRepository statisticsRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  
  if (kIsWeb) {
    return StatisticsRepositoryDrift(db as AppDatabase);
  } else {
    return StatisticsRepositoryImpl(db as Database);
  }
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
    ref.watch(gameRepositoryProvider),
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
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(cricketEngineProvider),
    );

@Riverpod(keepAlive: true)
CreateGameUseCase createGameUseCase(Ref ref) {
  return CreateGameUseCase(
    ref.watch(gameRepositoryProvider),
    ref.watch(gameEventRepositoryProvider),
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
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(aroundTheClockEngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeBobs27LastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(bobs27EngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeShanghaiLastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(shanghaiEngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeCatch40LastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(catch40EngineProvider),
    );

@Riverpod(keepAlive: true)
UndoLastDartUseCase undoPracticeCheckoutPracticeLastDartUseCase(Ref ref) =>
    UndoLastDartUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
      ref.watch(dartThrowRepositoryProvider),
      ref.watch(checkoutPracticeEngineProvider),
    );

// Checkout practice exit use case
@Riverpod(keepAlive: true)
EndCheckoutPracticeUseCase endCheckoutPracticeUseCase(Ref ref) =>
    EndCheckoutPracticeUseCase(
      ref.watch(gameRepositoryProvider),
      ref.watch(gameEventRepositoryProvider),
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
    if (kIsWeb) {
      await DriftHelper.instance.clearAllData();
    } else {
      await DatabaseHelper.instance.clearAllData();
    }
  };
}
