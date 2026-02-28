// Database Provider
// Contains Riverpod providers for database and repository access

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
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
import '../../features/game/domain/usecases/process_dart_use_case.dart';
import '../../features/game/domain/usecases/create_game_use_case.dart';

part 'database_provider.g.dart';

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
CreateGameUseCase createGameUseCase(Ref ref) {
  return CreateGameUseCase(
    ref.watch(gameRepositoryProvider),
    ref.watch(gameEventRepositoryProvider),
  );
}
