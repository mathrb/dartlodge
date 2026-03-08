import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/entities/game_event.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../state/active_practice_state.dart';
import '../../../../core/persistence/database_provider.dart';
import '../../../../core/utils/constants.dart';

part 'active_practice_provider.g.dart';

@riverpod
class ActivePracticeNotifier extends _$ActivePracticeNotifier {
  @override
  Future<ActivePracticeState?> build(String gameId) async {
    final game = await ref.read(gameRepositoryProvider).getGame(gameId);
    if (game == null) return null;

    final competitors =
        await ref.read(gameRepositoryProvider).getCompetitors(gameId);
    final events =
        await ref.read(gameEventRepositoryProvider).getEventsForGame(gameId);

    final engine = switch (game.gameType) {
      GameType.aroundTheClock => ref.read(aroundTheClockEngineProvider),
      GameType.bobs27 => ref.read(bobs27EngineProvider),
      GameType.shanghai => ref.read(shanghaiEngineProvider),
      GameType.catch40 => ref.read(catch40EngineProvider),
      GameType.checkoutPractice => ref.read(checkoutPracticeEngineProvider),
      _ => throw UnsupportedError(
          'Unsupported practice game type: ${game.gameType}'),
    };

    var gs = GameState.initial(game, competitors);
    for (final event in events) {
      gs = engine.apply(gs, event).state;
    }

    return ActivePracticeState(gameState: gs);
  }

  Future<void> processDart(String segment) async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;
    final competitor = gs.competitors[gs.currentTurnIndex];

    final dart = DartThrow(
      dartId: const Uuid().v4(),
      gameId: gs.gameId,
      competitorId: competitor.competitorId,
      playerId: competitor.playerIds.isNotEmpty
          ? competitor.playerIds.first
          : 'sentinel',
      turnNumber: gs.currentLegIndex,
      dartNumber: gs.dartsThrownInTurn + 1,
      segment: segment,
      score: Segment.parse(segment).scoreValue,
    );

    state = await AsyncValue.guard(() async {
      final newGs = await switch (gs.gameType) {
        GameType.aroundTheClock =>
          ref.read(processAroundTheClockDartUseCaseProvider).execute(gs, dart),
        GameType.bobs27 =>
          ref.read(processBobs27DartUseCaseProvider).execute(gs, dart),
        GameType.shanghai =>
          ref.read(processShanghaiDartUseCaseProvider).execute(gs, dart),
        GameType.catch40 =>
          ref.read(processCatch40DartUseCaseProvider).execute(gs, dart),
        GameType.checkoutPractice =>
          ref.read(processCheckoutPracticeDartUseCaseProvider).execute(gs, dart),
        _ => throw UnsupportedError(
            'Unsupported practice game type: ${gs.gameType}'),
      };

      final pendingGameWinnerId =
          newGs.isComplete ? newGs.winnerCompetitorId : null;

      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId: pendingGameWinnerId,
      );
    });
  }

  bool get canUndo {
    final s = state.value;
    if (s == null) return false;
    final gs = s.gameState;
    return gs.dartsThrownInTurn > 0 ||
        gs.competitors.any((c) => c.dartThrows.isNotEmpty);
  }

  Future<void> undoDart() async {
    if (!canUndo) return;
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;

    state = await AsyncValue.guard(() async {
      final newGs = await switch (gs.gameType) {
        GameType.aroundTheClock =>
          ref.read(undoPracticeAroundTheClockLastDartUseCaseProvider).execute(gs),
        GameType.bobs27 =>
          ref.read(undoPracticeBobs27LastDartUseCaseProvider).execute(gs),
        GameType.shanghai =>
          ref.read(undoPracticeShanghaiLastDartUseCaseProvider).execute(gs),
        GameType.catch40 =>
          ref.read(undoPracticeCatch40LastDartUseCaseProvider).execute(gs),
        GameType.checkoutPractice =>
          ref.read(undoPracticeCheckoutPracticeLastDartUseCaseProvider).execute(gs),
        _ => throw UnsupportedError(
            'Unsupported practice game type: ${gs.gameType}'),
      };
      return ActivePracticeState(gameState: newGs);
    });
  }

  GameEngine _engineFor(GameType type) => switch (type) {
    GameType.aroundTheClock => ref.read(aroundTheClockEngineProvider),
    GameType.bobs27 => ref.read(bobs27EngineProvider),
    GameType.shanghai => ref.read(shanghaiEngineProvider),
    GameType.catch40 => ref.read(catch40EngineProvider),
    GameType.checkoutPractice => ref.read(checkoutPracticeEngineProvider),
    _ => throw UnsupportedError('Unsupported practice game type: $type'),
  };

  Future<void> startNextTurn() async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete) return;

    state = await AsyncValue.guard(() async {
      final engine = _engineFor(gs.gameType);
      int nextSeq =
          await ref.read(gameEventRepositoryProvider).getLatestSequence(gs.gameId) + 1;

      final currentCompetitor = gs.competitors[gs.currentTurnIndex];
      final actorId = currentCompetitor.playerIds.isNotEmpty
          ? currentCompetitor.playerIds.first
          : 'system';

      final turnEndedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: gs.gameId,
        eventType: 'TurnEnded',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': currentCompetitor.competitorId},
        synced: false,
        actorId: actorId,
        source: EventSource.client,
      );

      var newGs = engine.apply(gs, turnEndedEvent).state;

      final nextCompetitor = newGs.competitors[newGs.currentTurnIndex];
      final nextActorId = nextCompetitor.playerIds.isNotEmpty
          ? nextCompetitor.playerIds.first
          : 'system';

      final turnStartedEvent = GameEvent(
        eventId: const Uuid().v4(),
        gameId: gs.gameId,
        eventType: 'TurnStarted',
        localSequence: nextSeq++,
        occurredAt: DateTime.now(),
        payload: {'competitor_id': nextCompetitor.competitorId},
        synced: false,
        actorId: nextActorId,
        source: EventSource.client,
      );

      newGs = engine.apply(newGs, turnStartedEvent).state;

      await ref
          .read(gameEventRepositoryProvider)
          .appendEvents([turnEndedEvent, turnStartedEvent]);

      return ActivePracticeState(gameState: newGs);
    });
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }

  Future<void> endDrill() async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;
    if (gs.gameType != GameType.checkoutPractice) return;

    state = await AsyncValue.guard(() async {
      final newGs =
          await ref.read(endCheckoutPracticeUseCaseProvider).execute(gs);
      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId: newGs.winnerCompetitorId,
      );
    });
  }
}
