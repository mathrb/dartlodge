import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Web-guarded: the file-backed store (dart:io / path_provider) is swapped for a
// no-op stub on web so `flutter run -d chrome` still builds (#377 §8).
import 'package:dart_lodge/features/auto_scorer/data/recording/session_trace_stub.dart'
    if (dart.library.io) 'package:dart_lodge/features/auto_scorer/data/recording/session_trace_io.dart';

part 'session_recording_provider.g.dart';

const _kSessionRecordingKey = 'auto_scorer_record_sessions';

/// The session-recording opt-in (#490): persist the detection trace (detection
/// boxes, no photos) so a scoring bug can be replayed off-device. Default
/// **off** — off means zero trace files are written. A distinct provider from
/// [DataCollectionEnabled] (different pipeline), but since #686 a single
/// "Record for debugging & training" Settings toggle drives both together (see
/// `_setRecording`), so enabling recording also enables photo capture.
@Riverpod(keepAlive: true)
class SessionRecordingEnabled extends _$SessionRecordingEnabled {
  @override
  Future<bool> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return prefs.getBool(_kSessionRecordingKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_kSessionRecordingKey, enabled);
    state = AsyncData(enabled);
  }
}

/// The on-device session-trace store (file-backed on mobile, no-op on web).
/// Consumers gate on [SessionTraceStore.isSupported] before recording.
@Riverpod(keepAlive: true)
Future<SessionTraceStore> sessionTraceStore(Ref ref) =>
    openDefaultSessionTraceStore();
