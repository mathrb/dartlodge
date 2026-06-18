import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port.dart';
import 'package:dart_lodge/core/sound/sound_port_provider.dart';
import 'package:dart_lodge/core/utils/app_theme.dart';
import 'package:dart_lodge/features/achievements/domain/achievements_registry.dart';
import 'package:dart_lodge/features/achievements/domain/unlocked_achievement.dart';
import 'package:dart_lodge/features/achievements/presentation/providers/achievement_watcher_provider.dart';
import 'package:dart_lodge/features/achievements/presentation/widgets/achievement_notification_host.dart';
import 'package:dart_lodge/l10n/gen/app_localizations.dart';
import 'package:dart_lodge/l10n/supported_locales.dart';

class _SpySoundPort implements SoundPort {
  final List<SoundCue> cues = [];
  @override
  void play(SoundCue cue) => cues.add(cue);
  @override
  void dartThrown(String segment) {}
}

class _FakeWatcher extends AchievementWatcher {
  _FakeWatcher(this._stream);
  final Stream<List<UnlockedAchievement>> _stream;
  @override
  Stream<List<UnlockedAchievement>> build() => _stream;
}

UnlockedAchievement _unlock(String id) => UnlockedAchievement(
      achievement: kAchievements.firstWhere((a) => a.id == id),
      playerId: 'p1',
    );

void main() {
  late StreamController<List<UnlockedAchievement>> controller;
  late _SpySoundPort sound;
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  setUp(() {
    controller = StreamController<List<UnlockedAchievement>>.broadcast();
    sound = _SpySoundPort();
  });
  tearDown(() => controller.close());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(ProviderScope(
        overrides: [
          achievementWatcherProvider.overrideWith(() => _FakeWatcher(controller.stream)),
          soundPortProvider.overrideWith((ref) => sound),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light(),
          scaffoldMessengerKey: messengerKey,
          home: const Scaffold(body: SizedBox.shrink()),
          builder: (context, child) => AchievementNotificationHost(
            messengerKey: messengerKey,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ));

  testWidgets('a single unlock shows a toast and plays the sound once',
      (tester) async {
    await pump(tester);
    controller.add([_unlock('first_180')]);
    await tester.pump(); // process the listener
    await tester.pump(); // let the SnackBar animate in

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('First 180'), findsOneWidget);
    expect(sound.cues, [SoundCue.achievementUnlock]);
  });

  testWidgets('a batch queues toasts (one at a time) and plays the sound once',
      (tester) async {
    await pump(tester);
    controller.add([_unlock('first_180'), _unlock('big_fish')]);
    await tester.pump();
    await tester.pump();

    // ScaffoldMessenger shows one at a time; the first is visible.
    expect(find.textContaining('First 180'), findsOneWidget);
    expect(find.textContaining('Big Fish'), findsNothing);
    // Sound played once for the whole batch.
    expect(sound.cues, [SoundCue.achievementUnlock]);

    // Dismiss the first → the queued second animates in (deterministic).
    messengerKey.currentState!.hideCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.textContaining('Big Fish'), findsOneWidget);
    expect(sound.cues, [SoundCue.achievementUnlock]); // still once

    // Clear the second before the test ends (drain its auto-dismiss timer).
    messengerKey.currentState!.hideCurrentSnackBar();
    await tester.pumpAndSettle();
  });

  testWidgets('an empty emission shows nothing and plays nothing',
      (tester) async {
    await pump(tester);
    controller.add(const []);
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
    expect(sound.cues, isEmpty);
  });
}
