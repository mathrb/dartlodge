import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules countUpRules(AppLocalizations l10n) => GameRules(
      title: 'Count-Up',
      tagline: l10n.rulesCountUpTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCountUpObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCountUpHowB1,
            l10n.rulesCountUpHowB2,
            l10n.rulesCountUpHowB3,
            l10n.rulesCountUpHowB4,
            l10n.rulesCountUpHowB5,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCountUpWinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesCountUpTipsB1,
            l10n.rulesCountUpTipsB2,
          ],
        ),
      ],
    );
