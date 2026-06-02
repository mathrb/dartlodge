// Correct Dart Use Case
// Replaces the value of a specific (not necessarily last) dart in an active
// game without forcing the user to re-enter the other darts of the turn.
//
// Strategy (see docs plan + issue #376): rather than hand-crafting correction
// events, reuse the proven mutators. Rewind by calling UndoLastDartUseCase back
// to the target dart, then re-throw the corrected dart followed by the original
// tail darts through the normal ProcessDart path — stopping if the turn ends or
// the game completes. This delegates bust / leg / game-completion / turn_score /
// CrazyTargetsRolled handling to the real processing path, and the resulting
// event log is replay-correct by construction.

import 'package:uuid/uuid.dart';

import '../entities/dart_throw.dart';
import '../models/game_config.dart';
import '../models/game_state.dart';
import '../repositories/game_event_repository.dart';
import '../../../../core/error/repository_exception.dart';
import 'undo_last_dart_use_case.dart';

/// Re-throws a dart through a game-type-specific ProcessDart use case.
/// X01 uses `ProcessDartUseCase.execute`; Cricket uses the distinct
/// `ProcessCricketDartUseCase.execute`; both share this shape.
typedef ProcessDartFn = Future<GameState> Function(
    GameState state, DartThrow dart);

class CorrectDartUseCase {
  final UndoLastDartUseCase _undo;
  final ProcessDartFn _processDart;
  final GameEventRepository _eventRepository;

  CorrectDartUseCase(this._undo, this._processDart, this._eventRepository);

  /// Replaces the dart recorded by [originalEventId] with the board hit
  /// `(segment, multiplier)` (segment = base number 0/1..20/25, multiplier
  /// 1/2/3). Returns the rebuilt [GameState].
  Future<GameState> execute(
    GameState currentState, {
    required String originalEventId,
    required int segment,
    required int multiplier,
  }) async {
    // 1. Guard: completed games are read-only.
    if (currentState.isComplete) {
      throw GameAlreadyCompleteException(currentState.gameId);
    }

    // 2. Load the log and build the live-dart view (same skip sets as
    //    UndoLastDartUseCase / replayEvents).
    final events = await _eventRepository.getEventsForGame(currentState.gameId);
    final correctedIds = <String>{};
    final supersededIds = <String>{};
    for (final e in events) {
      if (e.eventType != 'DartCorrected') continue;
      final origId = e.payload['original_event_id'];
      if (origId is String) correctedIds.add(origId);
      final superseded = e.payload['superseded_event_ids'];
      if (superseded is List) {
        for (final id in superseded) {
          if (id is String) supersededIds.add(id);
        }
      }
    }

    final liveDarts = [
      for (final e in events)
        if (e.eventType == 'DartThrown' &&
            !correctedIds.contains(e.eventId) &&
            !supersededIds.contains(e.eventId))
          e,
    ];

    // 3. Locate the target among live darts; capture the ordered tail.
    final targetIdx =
        liveDarts.indexWhere((e) => e.eventId == originalEventId);
    if (targetIdx == -1) {
      throw DartNotCorrectableException(currentState.gameId, originalEventId);
    }
    final tailSegments = [
      for (final e in liveDarts.sublist(targetIdx + 1))
        Segment.fromBoardHit(
          e.payload['segment'] as int,
          e.payload['multiplier'] as int,
        ).toCanonicalString(),
    ];
    final correctedSegment =
        Segment.fromBoardHit(segment, multiplier).toCanonicalString();

    // 4. Rewind: undo the tail darts and the target itself. Each undo removes
    //    the last live dart and performs its own turn-boundary supersession.
    var state = currentState;
    for (var i = 0; i < tailSegments.length + 1; i++) {
      state = await _undo.execute(state);
    }

    // 5. Re-throw the corrected dart, then the tail in order — stopping if the
    //    corrected dart (or a tail dart) ends the turn or completes the game,
    //    so a bust/win correctly discards the remaining darts.
    state = await _reThrow(state, correctedSegment);
    for (final seg in tailSegments) {
      if (state.isComplete || !state.turnActive) break;
      state = await _reThrow(state, seg);
    }
    return state;
  }

  Future<GameState> _reThrow(GameState state, String segment) {
    final competitor = state.competitors[state.currentTurnIndex];
    final dart = DartThrow(
      dartId: const Uuid().v4(),
      gameId: state.gameId,
      competitorId: competitor.competitorId,
      playerId: competitor.playerIds.isNotEmpty
          ? competitor.playerIds.first
          : 'sentinel',
      turnNumber: state.currentLegIndex,
      dartNumber: state.dartsThrownInTurn + 1,
      segment: segment,
      score: Segment.parse(segment).scoreValue,
    );
    return _processDart(state, dart);
  }
}
