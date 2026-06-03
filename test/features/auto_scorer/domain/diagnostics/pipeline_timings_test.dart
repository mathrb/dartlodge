import 'package:dart_lodge/features/auto_scorer/domain/diagnostics/pipeline_timings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to all-zero', () {
    const t = PipelineTimings();
    expect(t.capture, Duration.zero);
    expect(t.detect, Duration.zero);
    expect(t.track, Duration.zero);
    expect(t.total, Duration.zero);
  });

  test('total sums the stages', () {
    const t = PipelineTimings(
      capture: Duration(milliseconds: 200),
      detect: Duration(milliseconds: 540),
      track: Duration(milliseconds: 1),
    );
    expect(t.total, const Duration(milliseconds: 741));
  });

  test('copyWith overrides only the given stage', () {
    const base = PipelineTimings(detect: Duration(milliseconds: 100));
    final withCapture = base.copyWith(capture: const Duration(milliseconds: 50));
    expect(withCapture.capture, const Duration(milliseconds: 50));
    expect(withCapture.detect, const Duration(milliseconds: 100));
    expect(withCapture.track, Duration.zero);
  });
}
