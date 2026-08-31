import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pre_send_provider.g.dart';

const _kPreSendSkippedKey = 'auto_scorer_pre_send_skipped';

/// Whether the player has asked not to see the pre-send screen again (#744).
///
/// The screen explains what the export contains and how to get it to the
/// maintainer; a repeat sender already knows, so it is skippable — and once
/// skipped, export goes straight to the share sheet as it did before.
@Riverpod(keepAlive: true)
class AutoScorerPreSendSkipped extends _$AutoScorerPreSendSkipped {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kPreSendSkippedKey) ?? false;
  }

  Future<void> setSkipped(bool skipped) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kPreSendSkippedKey, skipped);
    state = AsyncData(skipped);
  }
}
