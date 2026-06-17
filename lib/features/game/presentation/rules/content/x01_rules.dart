import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules x01Rules(AppLocalizations l10n) => GameRules(
      title: 'X01',
      tagline: l10n.rulesX01Tagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesX01ObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesX01HowB1,
            l10n.rulesX01HowB2,
            l10n.rulesX01HowB3,
            l10n.rulesX01HowB4,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingInOut,
          body: l10n.rulesX01InOutBody,
          bullets: [
            l10n.rulesX01InOutB1,
            l10n.rulesX01InOutB2,
            l10n.rulesX01InOutB3,
            l10n.rulesX01InOutB4,
            l10n.rulesX01InOutB5,
            l10n.rulesX01InOutB6,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesX01WinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingVariants,
          bullets: [
            l10n.rulesX01VariantsB1,
            l10n.rulesX01VariantsB2,
            l10n.rulesX01VariantsB3,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesX01TipsB1,
            l10n.rulesX01TipsB2,
            l10n.rulesX01TipsB3,
          ],
        ),
      ],
    );
