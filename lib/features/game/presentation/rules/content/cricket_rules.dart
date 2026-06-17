import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules cricketStandardRules(AppLocalizations l10n) => GameRules(
      title: 'Cricket — Standard',
      tagline: l10n.rulesCricketStdTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCricketStdObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCricketStdHowB1,
            l10n.rulesCricketStdHowB2,
            l10n.rulesCricketStdHowB3,
            l10n.rulesCricketStdHowB4,
            l10n.rulesCricketStdHowB5,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCricketStdWinningBody,
        ),
      ],
      relatedVariants: [
        RulesVariant(name: 'No Score', summary: l10n.rulesCricketStdVar1Summary),
        RulesVariant(name: 'Cut Throat', summary: l10n.rulesCricketStdVar2Summary),
      ],
    );

GameRules cricketNoScoreRules(AppLocalizations l10n) => GameRules(
      title: 'Cricket — No Score',
      tagline: l10n.rulesCricketNsTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCricketNsObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCricketNsHowB1,
            l10n.rulesCricketNsHowB2,
            l10n.rulesCricketNsHowB3,
            l10n.rulesCricketNsHowB4,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCricketNsWinningBody,
        ),
      ],
      relatedVariants: [
        RulesVariant(name: 'Standard', summary: l10n.rulesCricketNsVar1Summary),
        RulesVariant(name: 'Cut Throat', summary: l10n.rulesCricketNsVar2Summary),
      ],
    );

GameRules cricketCutThroatRules(AppLocalizations l10n) => GameRules(
      title: 'Cricket — Cut Throat',
      tagline: l10n.rulesCricketCtTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCricketCtObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCricketCtHowB1,
            l10n.rulesCricketCtHowB2,
            l10n.rulesCricketCtHowB3,
            l10n.rulesCricketCtHowB4,
            l10n.rulesCricketCtHowB5,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCricketCtWinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesCricketCtTipsB1,
            l10n.rulesCricketCtTipsB2,
          ],
        ),
      ],
      relatedVariants: [
        RulesVariant(name: 'Standard', summary: l10n.rulesCricketCtVar1Summary),
        RulesVariant(name: 'No Score', summary: l10n.rulesCricketCtVar2Summary),
      ],
    );

GameRules cricketCrazyRules(AppLocalizations l10n) => GameRules(
      title: 'Cricket — Crazy',
      tagline: l10n.rulesCricketCzTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCricketCzObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCricketCzHowB1,
            l10n.rulesCricketCzHowB2,
            l10n.rulesCricketCzHowB3,
            l10n.rulesCricketCzHowB4,
            l10n.rulesCricketCzHowB5,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCricketCzWinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesCricketCzTipsB1,
            l10n.rulesCricketCzTipsB2,
          ],
        ),
      ],
      relatedVariants: [
        RulesVariant(name: 'Standard', summary: l10n.rulesCricketCzVar1Summary),
        RulesVariant(name: 'Random', summary: l10n.rulesCricketCzVar2Summary),
      ],
    );

GameRules cricketRandomRules(AppLocalizations l10n) => GameRules(
      title: 'Cricket — Random',
      tagline: l10n.rulesCricketRdTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCricketRdObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCricketRdHowB1,
            l10n.rulesCricketRdHowB2,
            l10n.rulesCricketRdHowB3,
            l10n.rulesCricketRdHowB4,
            l10n.rulesCricketRdHowB5,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCricketRdWinningBody,
        ),
      ],
      relatedVariants: [
        RulesVariant(name: 'Standard', summary: l10n.rulesCricketRdVar1Summary),
        RulesVariant(name: 'Cut Throat', summary: l10n.rulesCricketRdVar2Summary),
      ],
    );
