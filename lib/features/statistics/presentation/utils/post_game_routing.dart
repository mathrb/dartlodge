import '../../../../core/utils/constants.dart';

/// Game types whose post-game and history-detail summaries consume the
/// X01-shaped chrome rendered by `GameSummarySectionWidget` (backed by
/// `gameStatsProvider`).
///
/// Every other type (shanghai + the four practice drills) reads from
/// `gameResultProvider` and renders either `ShanghaiSummaryWidget` or
/// `PracticeSummaryWidget`. Keeping the set in one place so the post-game
/// and history-detail screens can't drift (#255).
final gameStatsBackedTypes = <String>{
  GameType.x01.name,
  GameType.cricket.name,
  GameType.countUp.name,
};

bool isGameStatsBacked(String gameTypeName) =>
    gameStatsBackedTypes.contains(gameTypeName);
