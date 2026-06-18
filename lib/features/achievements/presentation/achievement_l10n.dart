import 'package:dart_lodge/features/achievements/domain/achievement.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Resolves an [Achievement]'s l10n title/description keys to localized strings
/// (#526). The domain stores opaque key strings (it can't depend on
/// `AppLocalizations`); Dart has no reflection, so we map id → generated getter
/// explicitly. The `_` fallback returns the raw key — `achievements_registry_test`
/// + `achievement_l10n_test` guarantee every id is covered.
String achievementTitle(AppLocalizations l10n, Achievement a) => switch (a.id) {
      'first_180' => l10n.achievementFirst180Title,
      'big_fish' => l10n.achievementBigFishTitle,
      'first_win' => l10n.achievementFirstWinTitle,
      'nine_darter' => l10n.achievementNineDarterTitle,
      'darts_1000' => l10n.achievementDarts1000Title,
      'darts_10000' => l10n.achievementDarts10000Title,
      'darts_50000' => l10n.achievementDarts50000Title,
      'count_180_10' => l10n.achievementCount18010Title,
      'count_180_50' => l10n.achievementCount18050Title,
      'count_180_100' => l10n.achievementCount180100Title,
      'games_501_100' => l10n.achievementGames501100Title,
      'games_501_500' => l10n.achievementGames501500Title,
      'wins_10' => l10n.achievementWins10Title,
      'wins_50' => l10n.achievementWins50Title,
      'wins_100' => l10n.achievementWins100Title,
      _ => a.titleKey,
    };

String achievementDescription(AppLocalizations l10n, Achievement a) =>
    switch (a.id) {
      'first_180' => l10n.achievementFirst180Description,
      'big_fish' => l10n.achievementBigFishDescription,
      'first_win' => l10n.achievementFirstWinDescription,
      'nine_darter' => l10n.achievementNineDarterDescription,
      'darts_1000' => l10n.achievementDarts1000Description,
      'darts_10000' => l10n.achievementDarts10000Description,
      'darts_50000' => l10n.achievementDarts50000Description,
      'count_180_10' => l10n.achievementCount18010Description,
      'count_180_50' => l10n.achievementCount18050Description,
      'count_180_100' => l10n.achievementCount180100Description,
      'games_501_100' => l10n.achievementGames501100Description,
      'games_501_500' => l10n.achievementGames501500Description,
      'wins_10' => l10n.achievementWins10Description,
      'wins_50' => l10n.achievementWins50Description,
      'wins_100' => l10n.achievementWins100Description,
      _ => a.descriptionKey,
    };
