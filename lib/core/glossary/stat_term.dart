import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// A statistics term that newcomers can tap to read a plain-language
/// definition (see #719). Kept UI-agnostic so it can be attached to any
/// stat-label render site.
enum StatTerm { ppr, mpr, checkoutPct, checkoutScore }

extension StatTermL10n on StatTerm {
  /// Short heading shown as the glossary dialog title.
  String title(AppLocalizations l10n) => switch (this) {
        StatTerm.ppr => l10n.glossaryPprTitle,
        StatTerm.mpr => l10n.glossaryMprTitle,
        StatTerm.checkoutPct => l10n.glossaryCheckoutPctTitle,
        StatTerm.checkoutScore => l10n.glossaryCheckoutScoreTitle,
      };

  /// Plain-language definition shown as the glossary dialog body.
  String body(AppLocalizations l10n) => switch (this) {
        StatTerm.ppr => l10n.glossaryPprBody,
        StatTerm.mpr => l10n.glossaryMprBody,
        StatTerm.checkoutPct => l10n.glossaryCheckoutPctBody,
        StatTerm.checkoutScore => l10n.glossaryCheckoutScoreBody,
      };
}
