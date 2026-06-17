import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules bobs27Rules(AppLocalizations l10n) => GameRules(
      title: "Bob's 27",
      tagline: l10n.rulesBobs27Tagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesBobs27ObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesBobs27HowB1,
            l10n.rulesBobs27HowB2,
            l10n.rulesBobs27HowB3,
            l10n.rulesBobs27HowB4,
            l10n.rulesBobs27HowB5,
            l10n.rulesBobs27HowB6,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesBobs27WinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesBobs27TipsB1,
            l10n.rulesBobs27TipsB2,
          ],
        ),
      ],
    );
