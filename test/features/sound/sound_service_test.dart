import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port_provider.dart';
import 'package:dart_lodge/features/sound/domain/sound_player.dart';
import 'package:dart_lodge/core/sound/sound_settings_provider.dart';
import 'package:dart_lodge/features/sound/presentation/providers/sound_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSoundPlayer implements SoundPlayer {
  final List<String> played = [];

  @override
  Future<void> preload(Iterable<String> assets) async {}

  @override
  Future<void> play(String asset) async => played.add(asset);

  @override
  Future<void> dispose() async {}
}

/// Builds a container whose `soundPortProvider` is the real [SoundService]
/// (over [fake]) and whose `sound_enabled` preference is [enabled].
Future<(ProviderContainer, _FakeSoundPlayer)> _harness(bool enabled) async {
  SharedPreferences.setMockInitialValues({'sound_enabled': enabled});
  final fake = _FakeSoundPlayer();
  final container = ProviderContainer(
    overrides: [
      soundPortProvider.overrideWith((ref) => SoundService(ref, fake)),
    ],
  );
  // Settle the async settings build so the gate reads the real bool (not null).
  await container.read(soundEnabledProvider.future);
  return (container, fake);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService', () {
    test('dartThrown maps a scoring segment to the hit asset', () async {
      final (container, fake) = await _harness(true);
      addTearDown(container.dispose);

      container.read(soundPortProvider).dartThrown('T20');

      expect(fake.played, ['sounds/dartHit.mp3']);
    });

    test('dartThrown maps MISS to the miss asset', () async {
      final (container, fake) = await _harness(true);
      addTearDown(container.dispose);

      container.read(soundPortProvider).dartThrown('MISS');

      expect(fake.played, ['sounds/dartMiss.wav']);
    });

    test('play(bust) maps to the bust asset', () async {
      final (container, fake) = await _harness(true);
      addTearDown(container.dispose);

      container.read(soundPortProvider).play(SoundCue.bust);

      expect(fake.played, ['sounds/bust.wav']);
    });

    test('play(achievementUnlock) maps to the achievement asset', () async {
      final (container, fake) = await _harness(true);
      addTearDown(container.dispose);

      container.read(soundPortProvider).play(SoundCue.achievementUnlock);

      expect(fake.played, ['sounds/achievement.wav']);
    });

    test('plays nothing when sound is disabled (gate)', () async {
      final (container, fake) = await _harness(false);
      addTearDown(container.dispose);

      container.read(soundPortProvider)
        ..dartThrown('T20')
        ..dartThrown('MISS')
        ..play(SoundCue.bust);

      expect(fake.played, isEmpty);
    });
  });
}
