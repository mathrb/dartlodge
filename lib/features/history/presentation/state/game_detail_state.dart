import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:my_darts/features/game/domain/entities/competitor.dart';
import 'package:my_darts/features/game/domain/entities/dart_throw.dart';
import 'package:my_darts/features/game/domain/entities/game.dart';
import 'package:my_darts/features/game/domain/entities/game_event.dart';
import 'package:my_darts/features/statistics/domain/entities/game_stats.dart';

part 'game_detail_state.freezed.dart';

@freezed
abstract class GameDetailState with _$GameDetailState {
  const factory GameDetailState({
    Game? game,
    @Default(<Competitor>[]) List<Competitor> competitors,
    @Default(<GameEvent>[]) List<GameEvent> events,
    @Default(<DartThrow>[]) List<DartThrow> darts,
    GameStats? gameStats,
  }) = _GameDetailState;

  factory GameDetailState.initial() => const GameDetailState();
}
