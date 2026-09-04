// The settings-side contribution counter (#742), and what it reports when the
// capture store cannot be read (#790).
//
// The failure has to be carried as a value: letting `list()` throw does NOT
// surface as `AsyncError` here — the provider is disposed while still loading
// and never emits, so the tile stayed on "Counting…" for good. These tests pin
// the three outcomes the UI renders: a count, a hard zero, and "unreadable".

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/capture_count_provider.dart';
import 'package:dart_lodge/features/auto_scorer/presentation/providers/data_collection_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore implements CaptureStore {
  _FakeStore({required this.isSupported, this.records, this.fails = false});

  @override
  final bool isSupported;
  final List<CaptureRecord>? records;
  final bool fails;

  @override
  Future<List<CaptureRecord>> list() async {
    if (fails) throw Exception('directory unreadable');
    return records ?? const [];
  }

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

CaptureRecord _record(int dart) => CaptureRecord(
      gameId: 'g1',
      handle: CaptureHandle(turnOrdinal: 1, dartInTurnOrdinal: dart),
      timestamp: DateTime.utc(2026),
      modelVersion: 'm',
      predictedDarts: const [],
      calPoints: const [],
    );

Future<int?> read(CaptureStore store) async {
  final container = ProviderContainer(overrides: [
    captureStoreProvider.overrideWith((ref) async => store),
  ]);
  addTearDown(container.dispose);
  final sub = container.listen(captureCountProvider, (_, __) {});
  addTearDown(sub.close);
  return container.read(captureCountProvider.future);
}

void main() {
  test('counts what the store holds', () async {
    expect(
        await read(_FakeStore(
            isSupported: true, records: [_record(1), _record(2), _record(3)])),
        3);
  });

  test('reports zero on a platform with no store at all', () async {
    // Web: the store is a no-op stub, so there is genuinely nothing stored.
    expect(await read(_FakeStore(isSupported: false)), 0);
  });

  test('reports "unknown", not zero, when the store cannot be read', () async {
    // The distinction the tile depends on: a failed read must not be shown as
    // "no photos yet" (a lie) nor as a count still running (#790).
    expect(await read(_FakeStore(isSupported: true, fails: true)), isNull);
  });
}
