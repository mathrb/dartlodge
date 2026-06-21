import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import '../game_rules.dart';

GameRules checkoutPracticeRules(AppLocalizations l10n) => GameRules(
      title: 'Checkout',
      tagline: l10n.rulesCheckoutTagline,
      sections: [
        RulesSection(
          heading: l10n.rulesHeadingObjective,
          body: l10n.rulesCheckoutObjectiveBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingHowToPlay,
          bullets: [
            l10n.rulesCheckoutHowB1,
            l10n.rulesCheckoutHowB2,
            l10n.rulesCheckoutHowB3,
            l10n.rulesCheckoutHowB4,
            l10n.rulesCheckoutHowB5,
          ],
        ),
        RulesSection(
          heading: l10n.rulesHeadingWinning,
          body: l10n.rulesCheckoutWinningBody,
        ),
        RulesSection(
          heading: l10n.rulesHeadingTips,
          bullets: [
            l10n.rulesCheckoutTipsB1,
            l10n.rulesCheckoutTipsB2,
          ],
        ),
      ],
    );
