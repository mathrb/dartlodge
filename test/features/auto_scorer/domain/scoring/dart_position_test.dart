import 'package:dart_lodge/features/auto_scorer/domain/scoring/dart_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normaliseDartPosition', () {
    test('passes the canonical centre through unchanged (bull)', () {
      final p = normaliseDartPosition((x: 0.0, y: 0.0));
      expect(p, isNotNull);
      expect(p!.x, 0.0);
      expect(p.y, 0.0);
    });

    test('keeps a point on the double ring (radius 1.0) — "20 at top"', () {
      // The tracker already normalises to centre=0 / double-ring=1, so the
      // canonical position is returned verbatim.
      final p = normaliseDartPosition((x: 0.0, y: -1.0));
      expect(p, isNotNull);
      expect(p!.x, 0.0);
      expect(p.y, -1.0);
    });

    test('keeps a genuine miss just outside the double ring (r > 1.0)', () {
      // A miss is useful heatmap data — only true noise is dropped.
      final p = normaliseDartPosition((x: 1.2, y: 0.0));
      expect(p, isNotNull);
      expect(p!.x, 1.2);
      expect(p.y, 0.0);
    });

    test('keeps a point exactly at the noise threshold (r == 1.5)', () {
      final p = normaliseDartPosition((x: 1.5, y: 0.0));
      expect(p, isNotNull);
      expect(p!.x, 1.5);
    });

    test('drops detection noise past the threshold (r > 1.5) → null', () {
      expect(normaliseDartPosition((x: 1.6, y: 0.0)), isNull);
      expect(normaliseDartPosition((x: 0.0, y: -2.0)), isNull);
    });

    test('noise guard uses Euclidean radius, not per-axis', () {
      // (1.1, 1.1) has radius ~1.556 > 1.5 → noise, even though neither axis
      // alone exceeds the threshold.
      expect(normaliseDartPosition((x: 1.1, y: 1.1)), isNull);
      // (1.0, 1.0) has radius ~1.414 < 1.5 → kept.
      final kept = normaliseDartPosition((x: 1.0, y: 1.0));
      expect(kept, isNotNull);
      expect(kept!.x, 1.0);
      expect(kept.y, 1.0);
    });

    test('preserves off-axis quadrant signs', () {
      final p = normaliseDartPosition((x: -0.5, y: 0.5));
      expect(p, isNotNull);
      expect(p!.x, -0.5);
      expect(p.y, 0.5);
    });
  });
}
