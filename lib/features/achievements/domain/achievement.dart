import 'package:dart_lodge/features/achievements/domain/achievement_metric.dart';

/// How an [Achievement] is presented — a one-shot badge or a tiered counter.
/// A presentation hint only (badge vs progress bar); the unlock itself is driven
/// by [Achievement.threshold] in the evaluator, not by this kind.
enum AchievementKind { binary, counter }

/// A single achievement definition (#521/#523). Pure domain: no Flutter / DB.
///
/// Identified by its catalogue [id] (slug, e.g. `'first_180'`). The unlock bar is
/// [threshold] (`null` ⇒ 1, applied by the evaluator). Counters always set it;
/// binaries are usually `null` (unlock on the first occurrence) — the exception
/// is `big_fish`, a binary on `highestCheckout` carrying an explicit `170`,
/// because its metric is a magnitude, not a count.
///
/// [titleKey] / [descriptionKey] are **l10n keys** (resolved via
/// `AppLocalizations` in the presentation layer, SI-5) — the domain stays
/// dependency-free.
class Achievement {
  const Achievement({
    required this.id,
    required this.kind,
    required this.metric,
    this.threshold,
    required this.titleKey,
    required this.descriptionKey,
  });

  final String id;
  final AchievementKind kind;
  final AchievementMetric metric;
  final int? threshold;
  final String titleKey;
  final String descriptionKey;
}
