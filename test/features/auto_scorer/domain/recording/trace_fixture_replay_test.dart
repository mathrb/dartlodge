import 'package:dart_lodge/features/auto_scorer/domain/recording/session_replayer.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trace_fixtures.dart';

void main() {
  test('x01_two_turns fixture replays faithfully via loadTrace', () {
    final trace = loadTrace('x01_two_turns');

    final result = const SessionReplayer().replay(trace);
    expect(result.isFaithful, isTrue, reason: result.divergences.join('\n'));

    // Sanity: the fixture exercises real emissions across a recorded turn
    // advance, so this is a meaningful end-to-end check, not a vacuous one.
    final emissions = trace.lines
        .whereType<TraceFrame>()
        .expand((f) => f.outcome.newDarts)
        .where((d) => d.emitted)
        .length;
    expect(emissions, greaterThanOrEqualTo(3));
    expect(trace.lines.whereType<TrackerSignal>(), isNotEmpty);
  });
}
