import 'dart:async';
import 'dart:io';

import 'package:dart_lodge/core/utils/screen_wakelock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  group('ScreenWakelock', () {
    tearDown(() => ScreenWakelock.platformToggle = WakelockPlus.toggle);

    test('forwards enable/disable to the platform', () async {
      final calls = <bool>[];
      ScreenWakelock.platformToggle = ({required bool enable}) async {
        calls.add(enable);
      };

      ScreenWakelock.enable();
      ScreenWakelock.disable();
      await Future<void>.delayed(Duration.zero);

      expect(calls, [true, false]);
    });

    // Regression: Mobile Safari rejects the Screen Wake Lock API with the bare
    // String 'NotAllowedError, Permission was denied'. Unawaited, that surfaced
    // as a fatal crash in Sentry (MY-DARTS-P) instead of being ignored.
    test('swallows a platform refusal instead of crashing the zone', () async {
      ScreenWakelock.platformToggle = ({required bool enable}) async {
        throw 'NotAllowedError, Permission was denied';
      };

      final uncaught = <Object>[];
      await runZonedGuarded(() async {
        ScreenWakelock.enable();
        ScreenWakelock.disable();
        await Future<void>.delayed(Duration.zero);
      }, (error, stack) => uncaught.add(error));

      expect(uncaught, isEmpty);
    });

    test('is the only caller of wakelock_plus in lib/', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('core/utils/screen_wakelock.dart')) continue;
        if (entity.readAsStringSync().contains('wakelock_plus')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Use ScreenWakelock — a bare WakelockPlus call is unawaited '
            'and crashes the app when the platform refuses (MY-DARTS-P).',
      );
    });
  });
}
