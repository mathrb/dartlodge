import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules shanghaiRules(AppLocalizations l10n) => GameRules(
      title: 'Shanghai',
      tagline: l10n.rulesShanghaiTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesShanghaiObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesShanghaiHowB1,
            l10n.rulesShanghaiHowB2,
            l10n.rulesShanghaiHowB3,
            l10n.rulesShanghaiHowB4,
            l10n.rulesShanghaiHowB5,
            l10n.rulesShanghaiHowB6,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesShanghaiWinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesShanghaiTipsB1,
            l10n.rulesShanghaiTipsB2,
          ],
        ),
      ],
    );
