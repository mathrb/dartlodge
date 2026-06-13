import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';

/// Persists recorded auto-scorer [SessionTrace]s for later pure-Dart replay
/// (epic #488, sub-issue #490). Platform-agnostic contract; the file-backed
/// implementation lives in `data/` (mobile/desktop) and is stubbed on web
/// behind a `dart.library.io` guard so `flutter run -d chrome` still builds.
///
/// One trace per session, keyed by an opaque `sessionId` chosen by the caller.
/// Retention is bounded (keep the most recent N) so leaving recording on does
/// not grow without limit. Reading/exporting traces off the device is added in
/// sub-issue #492.
abstract class SessionTraceStore {
  /// False on the web stub — callers must not offer recording when so.
  bool get isSupported;

  /// Write [trace] under [sessionId] (overwrites any existing trace for it).
  Future<void> save(String sessionId, SessionTrace trace);

  /// Session ids currently stored, most-recent first.
  Future<List<String>> list();

  /// Delete the oldest sessions until at most [keepLast] remain.
  Future<void> enforceRetention({required int keepLast});

  /// Remove all stored traces.
  Future<void> clear();
}
