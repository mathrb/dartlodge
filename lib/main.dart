// Main entry point for the Darts App
// This file initializes the application and sets up the provider scope

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/persistence/persistence.dart';
import 'features/game/domain/repositories/game_repository.dart';
import 'features/game/domain/repositories/dart_throw_repository.dart';
import 'features/players/domain/repositories/player_repository.dart';

// Provider overrides for dependency injection
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  throw UnimplementedError('GameRepository must be overridden with concrete implementation');
});

final dartThrowRepositoryProvider = Provider<DartThrowRepository>((ref) {
  throw UnimplementedError('DartThrowRepository must be overridden with concrete implementation');
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  throw UnimplementedError('PlayerRepository must be overridden with concrete implementation');
});

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database and repositories
  final databaseHelper = DatabaseHelper.instance;
  final gameRepository = GameRepositoryImpl(databaseHelper);
  final dartThrowRepository = DartThrowRepositoryImpl(databaseHelper);
  final playerRepository = PlayerRepositoryImpl(databaseHelper);

  // Run the app with Riverpod provider scope and dependency overrides
  runApp(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(gameRepository),
        dartThrowRepositoryProvider.overrideWithValue(dartThrowRepository),
        playerRepositoryProvider.overrideWithValue(playerRepository),
      ],
      child: const DartsApp(),
    ),
  );
}