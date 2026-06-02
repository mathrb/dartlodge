import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// File-backed [CaptureStore] for mobile/desktop (#381). Conditionally imported
/// in place of the web stub; only ever loaded where `dart:io` exists.
///
/// Each capture is two files in [baseDir]: `<gameId>_<handle>.jpg` (the 800×800
/// frame) and `<gameId>_<handle>.json` (the sidecar). [baseDir] is injectable
/// so tests run against a temp directory; production resolves it via
/// [openDefaultCaptureStore].
class FileCaptureStore implements CaptureStore {
  final Directory baseDir;

  FileCaptureStore(this.baseDir);

  @override
  bool get isSupported => true;

  String _stem(String gameId, CaptureHandle handle) => '${gameId}_${handle.key}';

  File _frameFile(String stem) => File(p.join(baseDir.path, '$stem.jpg'));
  File _sidecarFile(String stem) => File(p.join(baseDir.path, '$stem.json'));

  @override
  Future<void> save(CaptureRecord record, Uint8List frameBytes) async {
    await baseDir.create(recursive: true);
    final stem = _stem(record.gameId, record.handle);
    await _frameFile(stem).writeAsBytes(frameBytes, flush: true);
    await _sidecarFile(stem)
        .writeAsString(jsonEncode(record.toJson()), flush: true);
  }

  @override
  Future<void> applyCorrection(String gameId, CaptureHandle handle,
      List<CorrectedDart> corrected) async {
    final file = _sidecarFile(_stem(gameId, handle));
    if (!await file.exists()) return;
    final record = CaptureRecord.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    await file.writeAsString(
        jsonEncode(record.withCorrection(corrected).toJson()),
        flush: true);
  }

  @override
  Future<List<CaptureRecord>> list() async {
    if (!await baseDir.exists()) return const [];
    final records = <CaptureRecord>[];
    await for (final entity in baseDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        records.add(CaptureRecord.fromJson(
            jsonDecode(await entity.readAsString()) as Map<String, dynamic>));
      }
    }
    return records;
  }

  @override
  Future<void> enforceRetention(RetentionPolicy policy) async {
    if (!await baseDir.exists()) return;
    final metas = <CaptureMeta>[];
    for (final record in await list()) {
      final stem = _stem(record.gameId, record.handle);
      final frame = _frameFile(stem);
      final sidecar = _sidecarFile(stem);
      final size = (await frame.exists() ? await frame.length() : 0) +
          (await sidecar.exists() ? await sidecar.length() : 0);
      metas.add(CaptureMeta(
        gameId: record.gameId,
        handle: record.handle,
        sizeBytes: size,
        timestamp: record.timestamp,
        wasCorrected: record.wasCorrected,
      ));
    }
    for (final meta in policy.selectForPruning(metas)) {
      final stem = _stem(meta.gameId, meta.handle);
      await _deleteIfExists(_frameFile(stem));
      await _deleteIfExists(_sidecarFile(stem));
    }
  }

  @override
  Future<Uint8List> buildExportZip() async {
    final archive = Archive();
    if (await baseDir.exists()) {
      await for (final entity in baseDir.list()) {
        if (entity is File &&
            (entity.path.endsWith('.json') || entity.path.endsWith('.jpg'))) {
          final bytes = await entity.readAsBytes();
          archive.addFile(
              ArchiveFile(p.basename(entity.path), bytes.length, bytes));
        }
      }
    }
    final encoded = ZipEncoder().encode(archive) ?? const <int>[];
    return Uint8List.fromList(encoded);
  }

  @override
  Future<void> clear() async {
    if (!await baseDir.exists()) return;
    await for (final entity in baseDir.list()) {
      if (entity is File &&
          (entity.path.endsWith('.json') || entity.path.endsWith('.jpg'))) {
        await entity.delete();
      }
    }
  }

  Future<void> _deleteIfExists(File f) async {
    if (await f.exists()) await f.delete();
  }
}

/// Resolve the default on-device capture store (under application support).
Future<CaptureStore> openDefaultCaptureStore() async {
  final support = await getApplicationSupportDirectory();
  return FileCaptureStore(Directory(p.join(support.path, 'auto_scorer', 'captures')));
}

/// Hand an export zip to the OS share sheet (#381 §6) — no photo-library
/// permission needed. Writes [zipBytes] to a temp file named [fileName] and
/// shares it.
Future<void> shareCaptureZip(Uint8List zipBytes, String fileName) async {
  final tmp = await getTemporaryDirectory();
  final file = File(p.join(tmp.path, fileName));
  await file.writeAsBytes(zipBytes, flush: true);
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: 'application/zip')],
    subject: 'DartLodge training data',
  ));
}
