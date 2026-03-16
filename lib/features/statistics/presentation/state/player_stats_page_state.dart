import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_stats_page_state.freezed.dart';

enum StatsTabIndex { x01, cricket, practice, others }

enum StatsTimeRange { last10, last100, all }

@freezed
abstract class PlayerStatsPageState with _$PlayerStatsPageState {
  const factory PlayerStatsPageState({
    @Default(StatsTabIndex.x01) StatsTabIndex activeTab,
    @Default(null) int? selectedStartingScore,
    @Default(StatsTimeRange.all) StatsTimeRange timeRange,
    @Default(false) bool showCheckoutOverlay,
  }) = _PlayerStatsPageState;

  factory PlayerStatsPageState.initial() => const PlayerStatsPageState();
}
