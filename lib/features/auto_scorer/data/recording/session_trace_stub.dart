import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';

/// Web stub for the session-trace store (#490): the auto-scorer is invisible on
/// web, so this no-op keeps `flutter run -d chrome` building without pulling in
/// `dart:io` / `path_provider`. [isSupported] is false; callers must not start
/// recording on web.
class _UnsupportedSessionTraceStore implements SessionTraceStore {
  const _UnsupportedSessionTraceStore();

  @override
  bool get isSupported => false;

  @override
  Future<void> save(String sessionId, SessionTrace trace) async {}

  @override
  Future<SessionTrace?> read(String sessionId) async => null;

  @override
  Future<List<String>> list() async => const [];

  @override
  Future<void> enforceRetention({required int keepLast}) async {}

  @override
  Future<void> clear() async {}
}

Future<SessionTraceStore> openDefaultSessionTraceStore() async =>
    const _UnsupportedSessionTraceStore();

Future<String> writeSessionExport(String sessionId, String json) async => '';

Future<void> shareSessionFile(String path) async {}
