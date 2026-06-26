import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'uncalibrated_notice_provider.g.dart';

const _kUncalibratedNoticeSeenKey = 'auto_scorer_uncalibrated_notice_seen';

/// Whether the user has acknowledged the one-time note shown when proceeding
/// past aiming WITHOUT calibration (markers not detected → auto-scoring off,
/// score by hand, frames help training). Default **false** so the note shows
/// the first time they continue uncalibrated; confirming sets it true so the
/// note never interrupts again. Mirrors [AutoScorerSetupTipsSeen].
@Riverpod(keepAlive: true)
class AutoScorerUncalibratedNoticeSeen
    extends _$AutoScorerUncalibratedNoticeSeen {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kUncalibratedNoticeSeenKey) ?? false;
  }

  Future<void> setSeen(bool seen) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kUncalibratedNoticeSeenKey, seen);
    state = AsyncData(seen);
  }
}
