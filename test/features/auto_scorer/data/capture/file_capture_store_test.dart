import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_lodge/features/auto_scorer/data/capture/capture_io.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late FileCaptureStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('capture_test');
    store = FileCaptureStore(dir);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  CaptureRecord record(int turn, {String gameId = 'g1', bool corrected = false}) =>
      CaptureRecord(
        predictedDarts: const [PredictedDart(x: 0.5, y: 0.5, conf: 0.9)],
        calPoints: const [
          (x: 0.5, y: 0.2),
          (x: 0.5, y: 0.8),
          (x: 0.2, y: 0.5),
          (x: 0.8, y: 0.5),
        ],
        modelVersion: 'v1',
        gameId: gameId,
        handle: CaptureHandle(turnOrdinal: turn, dartInTurnOrdinal: 1),
        timestamp: DateTime.utc(2026, 6, turn),
        wasCorrected: corrected,
      );

  Uint8List frame(int n) => Uint8List.fromList(List.filled(n, 7));

  test('save then list round-trips the sidecar', () async {
    await store.save(record(1), frame(10));
    final all = await store.list();
    expect(all, hasLength(1));
    expect(all.single.gameId, 'g1');
    expect(all.single.handle.key, 't1-d1');
  });

  test('re-saving the same handle overwrites rather than duplicating', () async {
    await store.save(record(1), frame(10));
    await store.save(record(1), frame(20));
    expect(await store.list(), hasLength(1));
  });

  test('applyCorrection updates the matching capture by handle', () async {
    await store.save(record(1), frame(10));
    await store.applyCorrection('g1',
        const CaptureHandle(turnOrdinal: 1, dartInTurnOrdinal: 1),
        const [CorrectedDart(x: 0.6, y: 0.4, segment: 'T20')]);
    final updated = (await store.list()).single;
    expect(updated.wasCorrected, isTrue);
    expect(updated.correctedDarts.single.segment, 'T20');
  });

  test('applyCorrection is a no-op for an unknown handle', () async {
    await store.save(record(1), frame(10));
    await store.applyCorrection('g1',
        const CaptureHandle(turnOrdinal: 9, dartInTurnOrdinal: 9), const []);
    expect((await store.list()).single.wasCorrected, isFalse);
  });

  test('buildExportZip contains one image + one sidecar per capture', () async {
    await store.save(record(1), frame(10));
    await store.save(record(2), frame(10));
    final zip = await store.buildExportZip();
    final archive = ZipDecoder().decodeBytes(zip);
    final names = archive.files.map((f) => f.name).toSet();
    expect(names, containsAll(<String>{
      'g1_t1-d1.jpg',
      'g1_t1-d1.json',
      'g1_t2-d1.jpg',
      'g1_t2-d1.json',
    }));
  });

  test('enforceRetention prunes oldest un-corrected over the cap', () async {
    await store.save(record(1), frame(400)); // oldest
    await store.save(record(2), frame(400));
    await store.save(record(3, corrected: true), frame(400));
    // Cap below total (3×~400+sidecars) so at least the oldest is pruned.
    await store.enforceRetention(const RetentionPolicy(maxBytes: 900));
    final remaining = (await store.list()).map((r) => r.handle.key).toSet();
    expect(remaining, isNot(contains('t1-d1')), reason: 'oldest pruned');
    expect(remaining, contains('t3-d1'), reason: 'corrected kept');
  });

  test('clear removes everything', () async {
    await store.save(record(1), frame(10));
    await store.clear();
    expect(await store.list(), isEmpty);
  });
}
