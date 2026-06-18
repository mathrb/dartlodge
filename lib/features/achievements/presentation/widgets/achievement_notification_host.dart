import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port_provider.dart';
import 'package:dart_lodge/features/achievements/presentation/achievement_l10n.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/achievement_watcher_provider.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';

/// Global, always-mounted notification host (#521/#527): listens to the
/// [achievementWatcherProvider] and, per game completion, plays the unlock sound
/// once and shows a self-dismissing "🏆 …" snackbar per newly-unlocked
/// achievement. `ScaffoldMessenger` queues the snackbars natively (one at a
/// time, no stacking).
///
/// Mounted via `MaterialApp.router`'s `builder` so it sits below the app's
/// `Localizations` + `ScaffoldMessenger`. Listening here also activates the
/// keepAlive watcher for the app lifetime (no separate activation needed). The
/// snackbars are shown through the app-level [messengerKey] so they survive
/// route changes.
class AchievementNotificationHost extends ConsumerWidget {
  const AchievementNotificationHost({
    super.key,
    required this.messengerKey,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read l10n synchronously in build (context is valid here) and capture it —
    // the ref.listen callback fires async, where `context` may be deactivated.
    // A locale change rebuilds this host, refreshing the captured l10n.
    final l10n = AppLocalizations.of(context);
    ref.listen(achievementWatcherProvider, (prev, next) {
      final unlocks = next.value;
      if (next is! AsyncData || unlocks == null || unlocks.isEmpty) return;

      final messenger = messengerKey.currentState;
      if (messenger == null) return;

      // Once per batch — a catch-up completion can unlock several at once.
      ref.read(soundPortProvider).play(SoundCue.achievementUnlock);

      for (final u in unlocks) {
        messenger.showSnackBar(SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(
            l10n.achievementUnlockedBanner(achievementTitle(l10n, u.achievement)),
          ),
        ));
      }
    });
    return child;
  }
}
