import 'dart:io';

import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// File-backed [SessionTraceStore] for mobile/desktop (#490). Conditionally
/// imported in place of the web stub; only ever loaded where `dart:io` exists.
///
/// Each session is one file in [baseDir]: `<sessionId>.jsonl`. [baseDir] is
/// injectable so tests run against a temp directory; production resolves it via
/// [openDefaultSessionTraceStore].
class FileSessionTraceStore implements SessionTraceStore {
  final Directory baseDir;

  FileSessionTraceStore(this.baseDir);

  @override
  bool get isSupported => true;

  File _file(String sessionId) =>
      File(p.join(baseDir.path, '$sessionId.jsonl'));

  @override
  Future<void> save(String sessionId, SessionTrace trace) async {
    await baseDir.create(recursive: true);
    await _file(sessionId).writeAsString(trace.toJsonl(), flush: true);
  }

  @override
  Future<SessionTrace?> read(String sessionId) async {
    final file = _file(sessionId);
    if (!await file.exists()) return null;
    return SessionTrace.fromJsonl(await file.readAsString());
  }

  /// `.jsonl` files in [baseDir], newest modification first.
  Future<List<File>> _traceFiles() async {
    if (!await baseDir.exists()) return [];
    final files = <File>[];
    await for (final entity in baseDir.list()) {
      if (entity is File && entity.path.endsWith('.jsonl')) files.add(entity);
    }
    files.sort((a, b) =>
        b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  @override
  Future<List<String>> list() async =>
      [for (final f in await _traceFiles()) p.basenameWithoutExtension(f.path)];

  @override
  Future<void> enforceRetention({required int keepLast}) async {
    final files = await _traceFiles();
    if (files.length <= keepLast) return;
    for (final stale in files.skip(keepLast)) {
      // Best-effort: a failed prune must not break recording.
      try {
        await stale.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> clear() async {
    for (final f in await _traceFiles()) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}

/// Production store rooted under the app-support dir, alongside captures.
Future<SessionTraceStore> openDefaultSessionTraceStore() async {
  final support = await getApplicationSupportDirectory();
  return FileSessionTraceStore(
      Directory(p.join(support.path, 'auto_scorer', 'sessions')));
}
