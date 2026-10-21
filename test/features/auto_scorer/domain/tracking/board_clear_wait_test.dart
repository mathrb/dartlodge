import 'package:dart_lodge/features/auto_scorer/domain/tracking/board_clear_wait.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presets map to 5 / 6 / 9 empty frames (#800)', () {
    expect(BoardClearWait.fast.frames, 5);
    expect(BoardClearWait.normal.frames, 6);
    expect(BoardClearWait.safe.frames, 9);
  });

  test('safe matches the conservative tracker default', () {
    expect(BoardClearWait.safe.frames,
        const DartTrackerConfig().emptyFramesToRebaseline);
  });

  group('emptyFramesToRebaselineFor', () {
    test('auto-advance on → the chosen preset', () {
      for (final wait in BoardClearWait.values) {
        expect(
          emptyFramesToRebaselineFor(autoAdvance: true, wait: wait),
          wait.frames,
        );
      }
    });

    test('auto-advance off → the default, whatever the preset', () {
      for (final wait in BoardClearWait.values) {
        expect(
          emptyFramesToRebaselineFor(autoAdvance: false, wait: wait),
          const DartTrackerConfig().emptyFramesToRebaseline,
        );
      }
    });
  });
}
