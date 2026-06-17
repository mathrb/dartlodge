import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

/// Localized relative-day label for [date], or `null` when it is [maxDays] or
/// more days in the past (the caller then formats an absolute date).
///
/// Returns "Today" for today (or any future skew), "Yesterday" for one day,
/// and a pluralized "N days ago" for 2..[maxDays]-1. Shared by the players card
/// and the history list so the wording and ICU plural live in one place.
String? relativeDayLabel(BuildContext context, DateTime date, {int maxDays = 7}) {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final local = date.toLocal();
  final diff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  if (diff <= 0) return l10n.commonRelativeToday;
  if (diff == 1) return l10n.commonRelativeYesterday;
  if (diff < maxDays) return l10n.commonRelativeDaysAgo(diff);
  return null;
}
