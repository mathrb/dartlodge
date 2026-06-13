import 'dart:io';

import 'package:dart_lodge/features/auto_scorer/data/recording/session_trace_io.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/tracking/dart_tracker_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

SessionTrace _trace(String gameId) => SessionTrace(
      header: SessionTraceHeader(
        modelVersion: 'm',
        gameId: gameId,
        startedAt: DateTime.utc(2026, 6, 13),
      ),
      lines: const [TrackerSegment(instance: 0, config: DartTrackerConfig())],
    );

void main() {
  late Directory dir;
  late FileSessionTraceStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('session_trace_test');
    store = FileSessionTraceStore(dir);
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('isSupported is true', () {
    expect(store.isSupported, isTrue);
  });

  test('save writes <sessionId>.jsonl that round-trips', () async {
    await store.save('s1', _trace('g1'));

    final file = File(p.join(dir.path, 's1.jsonl'));
    expect(file.existsSync(), isTrue);
    final restored = SessionTrace.fromJsonl(file.readAsStringSync());
    expect(restored.header.gameId, 'g1');
  });

  test('read returns the saved trace, null for a missing id', () async {
    await store.save('s1', _trace('g1'));
    final got = await store.read('s1');
    expect(got, isNotNull);
    expect(got!.header.gameId, 'g1');
    expect(await store.read('nope'), isNull);
  });

  test('list returns session ids, newest first', () async {
    await store.save('old', _trace('g'));
    await store.save('mid', _trace('g'));
    await store.save('new', _trace('g'));
    // Force a deterministic modification order (createTempSync writes can tie).
    File(p.join(dir.path, 'old.jsonl'))
        .setLastModifiedSync(DateTime.utc(2026, 1, 1));
    File(p.join(dir.path, 'mid.jsonl'))
        .setLastModifiedSync(DateTime.utc(2026, 1, 2));
    File(p.join(dir.path, 'new.jsonl'))
        .setLastModifiedSync(DateTime.utc(2026, 1, 3));

    expect(await store.list(), ['new', 'mid', 'old']);
  });

  test('enforceRetention keeps the most recent N, prunes the rest', () async {
    for (var i = 0; i < 5; i++) {
      await store.save('s$i', _trace('g'));
      File(p.join(dir.path, 's$i.jsonl'))
          .setLastModifiedSync(DateTime.utc(2026, 1, i + 1));
    }

    await store.enforceRetention(keepLast: 2);

    expect(await store.list(), ['s4', 's3']);
  });

  test('enforceRetention is a no-op when under the cap', () async {
    await store.save('a', _trace('g'));
    await store.enforceRetention(keepLast: 20);
    expect(await store.list(), ['a']);
  });

  test('clear removes all traces', () async {
    await store.save('a', _trace('g'));
    await store.save('b', _trace('g'));
    await store.clear();
    expect(await store.list(), isEmpty);
  });

  test('list/enforceRetention/clear tolerate a missing directory', () async {
    final missing = FileSessionTraceStore(
        Directory(p.join(dir.path, 'does-not-exist')));
    expect(await missing.list(), isEmpty);
    await missing.enforceRetention(keepLast: 1); // no throw
    await missing.clear(); // no throw
  });
}
