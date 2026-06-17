import 'package:dart_lodge/l10n/gen/app_localizations.dart';

import 'content/around_the_clock_rules.dart';
import 'content/bobs27_rules.dart';
import 'content/catch40_rules.dart';
import 'content/checkout_practice_rules.dart';
import 'content/count_up_rules.dart';
import 'content/cricket_rules.dart';
import 'content/shanghai_rules.dart';
import 'content/x01_rules.dart';
import 'game_rules.dart';

/// Slug → rules builder. Rules content is localized, so each entry is a
/// builder that takes the active [AppLocalizations]; resolve via [rulesFor].
final Map<String, GameRules Function(AppLocalizations)> kGameRules = {
  'x01-301': x01Rules,
  'x01-501': x01Rules,
  'x01-701': x01Rules,
  'x01-901': x01Rules,
  'cricket-standard': cricketStandardRules,
  'cricket-no-score': cricketNoScoreRules,
  'cricket-cut-throat': cricketCutThroatRules,
  'cricket-random': cricketRandomRules,
  'cricket-crazy': cricketCrazyRules,
  'practice-atc': aroundTheClockRules,
  'practice-catch40': catch40Rules,
  'practice-bobs27': bobs27Rules,
  'practice-shanghai': shanghaiRules,
  'practice-170-checkout': checkoutPracticeRules,
  'practice-count-up': countUpRules,
};

GameRules? rulesFor(AppLocalizations l10n, String slug) =>
    kGameRules[slug]?.call(l10n);
