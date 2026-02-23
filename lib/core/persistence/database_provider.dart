// Database Provider
// Contains Riverpod providers for database and repository access

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
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

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Database> database(Ref ref) async {
  return await DatabaseHelper.instance.database;
}

@Riverpod(keepAlive: true)
PlayerRepository playerRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return PlayerRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
GameRepository gameRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return GameRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
DartThrowRepository dartThrowRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return DartThrowRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
GameEventRepository gameEventRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return GameEventRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
StatisticsRepository statisticsRepository(Ref ref) {
  final db = ref.watch(databaseProvider).requireValue;
  return StatisticsRepositoryImpl(db);
}

@Riverpod(keepAlive: true)
StatelessX01Engine x01Engine(Ref ref) {
  return StatelessX01Engine();
}

@Riverpod(keepAlive: true)
ProcessDartUseCase processDartUseCase(Ref ref) {
  return ProcessDartUseCase(
    ref.watch(gameEventRepositoryProvider),
    ref.watch(dartThrowRepositoryProvider),
  );
}
