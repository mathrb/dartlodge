import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/dart_throw.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/statistics/domain/entities/game_stats.dart';
import 'package:dart_lodge/features/statistics/domain/entities/leg_stats_breakdown.dart';

part 'game_detail_state.freezed.dart';

@freezed
abstract class GameDetailState with _$GameDetailState {
  const factory GameDetailState({
    Game? game,
    @Default(<Competitor>[]) List<Competitor> competitors,
    @Default(<GameEvent>[]) List<GameEvent> events,
    @Default(<DartThrow>[]) List<DartThrow> darts,
    GameStats? gameStats,
    @Default(<LegStatsBreakdown>[]) List<LegStatsBreakdown> legStats,
  }) = _GameDetailState;

  factory GameDetailState.initial() => const GameDetailState();
}
