import 'package:dart_lodge/core/sound/sound_cue.dart';
import 'package:dart_lodge/core/sound/sound_port.dart';
import 'package:dart_lodge/core/sound/sound_port_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('soundPortProvider', () {
    test('defaults to a no-op SoundPort', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final port = container.read(soundPortProvider);
      expect(port, isA<SoundPort>());
    });

    test('default port calls are safe no-ops', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final port = container.read(soundPortProvider);
      expect(() => port.play(SoundCue.bust), returnsNormally);
      expect(() => port.dartThrown('T20'), returnsNormally);
      expect(() => port.dartThrown('MISS'), returnsNormally);
    });
  });
}
