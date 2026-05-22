import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/constants.dart';

part 'player_stats_page_state.freezed.dart';

enum StatsTabIndex { x01, cricket, practice, others }

enum StatsTimeRange { last10, last100, all }

@freezed
abstract class PlayerStatsPageState with _$PlayerStatsPageState {
  const factory PlayerStatsPageState({
    @Default(StatsTabIndex.x01) StatsTabIndex activeTab,
    @Default(null) int? selectedStartingScore,
    @Default(null) String? selectedCricketVariant,
    // Cricket target-mode cohort filter. Defaults to `'fixed'` so existing
    // career stats continue to render the canonical 15..20+Bull board.
    // Random/Crazy cohorts are kept separate at the loader level (see
    // `StatisticsRepository.getPlayerStats(cricketTargetMode: ...)`); the
    // Cricket tab now exposes a segmented selector so the user can switch
    // between cohorts (#260).
    @Default('fixed') String selectedCricketTargetMode,
    @Default(GameType.aroundTheClock) GameType selectedPracticeGameType,
    @Default(StatsTimeRange.all) StatsTimeRange timeRange,
  }) = _PlayerStatsPageState;

  factory PlayerStatsPageState.initial() => const PlayerStatsPageState();
}
