import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/presentation/widgets/auto_scorer_yolo_view_io.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the pure stream-map parsing helpers extracted when the
/// YOLOView preview moved from `onResult` to `onStreamingData` (#426) — so the
/// streaming map could also carry the un-annotated original frame. The widget
/// itself is device-only, but these helpers are pure and CI-verifiable.

Map<String, dynamic> _detection(String className, double conf, double cx) => {
      'classIndex': 0,
      'className': className,
      'confidence': conf,
      'boundingBox': {'left': 0.0, 'top': 0.0, 'right': 10.0, 'bottom': 10.0},
      'normalizedBox': {
        'left': cx - 0.01,
        'top': 0.49,
        'right': cx + 0.01,
        'bottom': 0.51,
      },
    };

void main() {
  group('resultsFromStreamData', () {
    test('parses valid detections and skips malformed ones', () {
      final data = <String, dynamic>{
        'detections': [
          _detection('cal1', 0.9, 0.5),
          // Malformed: missing 'confidence' — must be skipped, not crash.
          {
            'classIndex': 1,
            'className': 'dart',
            'boundingBox': {'left': 0.0, 'top': 0.0, 'right': 1.0, 'bottom': 1.0},
            'normalizedBox': {'left': 0.0, 'top': 0.0, 'right': 1.0, 'bottom': 1.0},
          },
          _detection('dart', 0.7, 0.3),
        ],
      };

      final results = resultsFromStreamData(data);

      expect(results, hasLength(2));
      expect(results[0].className, 'cal1');
      expect(results[0].confidence, closeTo(0.9, 1e-9));
      expect(results[1].className, 'dart');
      // normalizedBox center.dx == cx
      expect(results[1].normalizedBox.center.dx, closeTo(0.3, 1e-9));
    });

    test('returns empty when detections key is absent', () {
      expect(resultsFromStreamData(<String, dynamic>{}), isEmpty);
    });

    test('returns empty when detections is not a list', () {
      expect(
          resultsFromStreamData(<String, dynamic>{'detections': 'nope'}), isEmpty);
    });
  });

  group('rawFrameFromStreamData', () {
    test('returns the original-image bytes when present', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final out = rawFrameFromStreamData(<String, dynamic>{'originalImage': bytes});
      expect(out, same(bytes));
    });

    test('returns null when the key is absent', () {
      expect(rawFrameFromStreamData(<String, dynamic>{}), isNull);
    });

    test('returns null when the value is not bytes', () {
      expect(
          rawFrameFromStreamData(<String, dynamic>{'originalImage': 'x'}), isNull);
    });
  });
}
