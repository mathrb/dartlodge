import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dart_throw.dart';
import '../../domain/engines/base_game_engine.dart';
import '../../domain/models/game_config.dart';
import '../../domain/models/game_state.dart';
import '../../domain/usecases/game_use_case_helpers.dart';
import '../state/active_practice_state.dart';
import '../../../../core/persistence/database_provider.dart';
import '../../../../core/utils/constants.dart';
import 'action_serializer.dart';
import 'game_replay_provider.dart';

part 'active_practice_provider.g.dart';

@riverpod
class ActivePracticeNotifier extends _$ActivePracticeNotifier {
  final ActionSerializer _serializer = ActionSerializer();

  @override
  Future<ActivePracticeState?> build(String gameId) async {
    final gs = await ref.read(loadedGameStateProvider(gameId).future);
    if (gs == null) return null;
    return ActivePracticeState(gameState: gs);
  }

  Future<void> processDart(String segment) =>
      _serializer.run(() => _processDartImpl(segment));

  Future<void> _processDartImpl(String segment) async {
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

    final isShanghai = gs.gameType == GameType.shanghai;
    final prevSuccesses = gs.competitors[gs.currentTurnIndex].practiceSuccesses;

    state = await AsyncValue.guard(() async {
      var newGs = await switch (gs.gameType) {
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

      // Catch-40: auto-advance to next turn on same target after 3 darts
      // (no checkout yet, < 6 darts on target). This keeps the button hidden.
      if (gs.gameType == GameType.catch40 &&
          !newGs.turnActive &&
          !newGs.isComplete &&
          newGs.catch40TargetRemaining != 0 &&
          newGs.catch40DartsOnTarget < 6) {
        newGs = await _advanceTurn(newGs);
      }

      final pendingGameWinnerId =
          newGs.isComplete ? newGs.winnerCompetitorId : null;

      final shanghaiBonus = isShanghai &&
          newGs.competitors[gs.currentTurnIndex].practiceSuccesses >
              prevSuccesses;

      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId: pendingGameWinnerId,
        showShanghaiBonus: shanghaiBonus,
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

  Future<void> undoDart() => _serializer.run(_undoDartImpl);

  Future<void> _undoDartImpl() async {
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

  /// Apply TurnEnded + TurnStarted events and persist them. Used for
  /// same-target auto-advance in Catch-40 and for the NEXT ROUND/TARGET button.
  Future<GameState> _advanceTurn(GameState gs) async {
    final engine = _engineFor(gs.gameType);
    int nextSeq =
        await ref.read(gameEventRepositoryProvider).getLatestSequence(gs.gameId) + 1;

    final currentCompetitor = gs.competitors[gs.currentTurnIndex];
    final actorId = currentCompetitor.playerIds.isNotEmpty
        ? currentCompetitor.playerIds.first
        : 'system';

    final turnEndedEvent = buildGameEvent(
      gameId: gs.gameId,
      eventType: 'TurnEnded',
      localSequence: nextSeq++,
      actorId: actorId,
      payload: {'competitor_id': currentCompetitor.competitorId},
    );

    var newGs = engine.apply(gs, turnEndedEvent).state;

    final nextCompetitor = newGs.competitors[newGs.currentTurnIndex];
    final nextActorId = nextCompetitor.playerIds.isNotEmpty
        ? nextCompetitor.playerIds.first
        : 'system';

    final turnStartedEvent = buildGameEvent(
      gameId: gs.gameId,
      eventType: 'TurnStarted',
      localSequence: nextSeq++,
      actorId: nextActorId,
      payload: {'competitor_id': nextCompetitor.competitorId},
    );

    newGs = engine.apply(newGs, turnStartedEvent).state;

    await ref
        .read(gameEventRepositoryProvider)
        .appendEvents([turnEndedEvent, turnStartedEvent]);

    return newGs;
  }

  GameEngine _engineFor(GameType type) => switch (type) {
    GameType.aroundTheClock => ref.read(aroundTheClockEngineProvider),
    GameType.bobs27 => ref.read(bobs27EngineProvider),
    GameType.shanghai => ref.read(shanghaiEngineProvider),
    GameType.catch40 => ref.read(catch40EngineProvider),
    GameType.checkoutPractice => ref.read(checkoutPracticeEngineProvider),
    _ => throw UnsupportedError('Unsupported practice game type: $type'),
  };

  /// Fills any unfilled dart slots in the current turn with MISS darts,
  /// persisting them as events. Stops early if the game completes.
  Future<GameState> _fillTurnWithMisses(GameState gs) async {
    var current = gs;
    while (current.dartsThrownInTurn < 3 && !current.isComplete) {
      final competitor = current.competitors[current.currentTurnIndex];
      final dart = DartThrow(
        dartId: const Uuid().v4(),
        gameId: current.gameId,
        competitorId: competitor.competitorId,
        playerId: competitor.playerIds.isNotEmpty
            ? competitor.playerIds.first
            : 'sentinel',
        turnNumber: current.currentLegIndex,
        dartNumber: current.dartsThrownInTurn + 1,
        segment: 'MISS',
        score: 0,
      );
      current = await switch (current.gameType) {
        GameType.aroundTheClock =>
          ref.read(processAroundTheClockDartUseCaseProvider).execute(current, dart),
        GameType.bobs27 =>
          ref.read(processBobs27DartUseCaseProvider).execute(current, dart),
        GameType.shanghai =>
          ref.read(processShanghaiDartUseCaseProvider).execute(current, dart),
        GameType.catch40 =>
          ref.read(processCatch40DartUseCaseProvider).execute(current, dart),
        GameType.checkoutPractice =>
          ref.read(processCheckoutPracticeDartUseCaseProvider).execute(current, dart),
        _ => throw UnsupportedError(
            'Unsupported practice game type: ${current.gameType}'),
      };
    }
    return current;
  }

  Future<void> startNextTurn() => _serializer.run(_startNextTurnImpl);

  Future<void> _startNextTurnImpl() async {
    final current = state.value;
    if (current == null) return;
    final gs = current.gameState;
    if (gs.isComplete) return;

    state = await AsyncValue.guard(() async {
      final filled = await _fillTurnWithMisses(gs);
      final newGs = filled.isComplete ? filled : await _advanceTurn(filled);
      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId:
            newGs.isComplete ? newGs.winnerCompetitorId : null,
        showShanghaiBonus: false,
      );
    });
  }

  void dismissGameModal() {
    state = state.whenData((s) => s?.copyWith(pendingGameWinnerId: null));
  }

  Future<void> endDrill() => _serializer.run(_endDrillImpl);

  Future<void> _endDrillImpl() async {
    final current = state.value;
    if (current == null) return;

    final gs = current.gameState;

    state = await AsyncValue.guard(() async {
      final newGs =
          await ref.read(endPracticeUseCaseProvider).execute(gs);
      return ActivePracticeState(
        gameState: newGs,
        pendingGameWinnerId: newGs.winnerCompetitorId,
      );
    });
  }
}
