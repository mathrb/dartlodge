import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules catch40Rules(AppLocalizations l10n) => GameRules(
      title: 'Catch 40',
      tagline: l10n.rulesCatch40Tagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCatch40ObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCatch40HowB1,
            l10n.rulesCatch40HowB2,
            l10n.rulesCatch40HowB3,
            l10n.rulesCatch40HowB4,
            l10n.rulesCatch40HowB5,
            l10n.rulesCatch40HowB6,
            l10n.rulesCatch40HowB7,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCatch40WinningBody,
        ),
      ],
    );
