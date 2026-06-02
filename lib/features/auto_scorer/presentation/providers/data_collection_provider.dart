import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Web-guarded: the file-backed store (dart:io / share_plus) is swapped for a
// no-op stub on web so `flutter run -d chrome` still builds (#377 §8).
import 'package:dart_lodge/features/auto_scorer/data/capture/capture_stub.dart'
    if (dart.library.io) 'package:dart_lodge/features/auto_scorer/data/capture/capture_io.dart';

part 'data_collection_provider.g.dart';

const _kCollectTrainingDataKey = 'auto_scorer_collect_training_data';

/// The "Collect training data" opt-in (#381 §6) — distinct from the "Use
/// auto-scoring" switch (#382). Default **off**: we never silently hoard board
/// photos. The Settings UI row that toggles this is added with the rest of the
/// auto-scorer Settings integration in #382; this is the persisted state +
/// gating the capture pipeline consults.
@Riverpod(keepAlive: true)
class DataCollectionEnabled extends _$DataCollectionEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kCollectTrainingDataKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kCollectTrainingDataKey, enabled);
    state = AsyncData(enabled);
  }
}

/// The on-device capture store (file-backed on mobile, no-op on web). Consumers
/// gate on [CaptureStore.isSupported] before offering capture/export.
@Riverpod(keepAlive: true)
Future<CaptureStore> captureStore(Ref ref) => openDefaultCaptureStore();
