import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules aroundTheClockRules(AppLocalizations l10n) => GameRules(
      title: 'Around the Clock',
      tagline: l10n.rulesAtcTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesAtcObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesAtcHowB1,
            l10n.rulesAtcHowB2,
            l10n.rulesAtcHowB3,
            l10n.rulesAtcHowB4,
            l10n.rulesAtcHowB5,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesAtcWinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingVariants,
          bullets: [
            l10n.rulesAtcVariantsB1,
            l10n.rulesAtcVariantsB2,
            l10n.rulesAtcVariantsB3,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesAtcTipsB1,
            l10n.rulesAtcTipsB2,
          ],
        ),
      ],
    );
