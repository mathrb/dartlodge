import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';

/// Persists captured frames + sidecars and exports them for the training loop
/// (#381). The interface is platform-agnostic; the file-backed implementation
/// lives in `data/` (mobile) and is stubbed on web behind a `kIsWeb` guard so
/// `flutter run -d chrome` still builds (#377 §8).
///
/// `dart:typed_data` is core Dart, so this stays a pure `domain/` contract.
abstract class CaptureStore {
  /// False on the web stub — callers must not offer capture/export when so.
  bool get isSupported;

  /// Store [frameBytes] (the 800×800 frame) and its [record] sidecar, keyed by
  /// `(record.gameId, record.handle)`. Overwrites any existing capture for the
  /// same key (re-detection of the same dart slot).
  Future<void> save(CaptureRecord record, Uint8List frameBytes);

  /// Update the capture for [gameId]/[handle] with the user's [corrected] darts
  /// (sets `was_corrected`). No-op if no matching capture exists.
  Future<void> applyCorrection(
      String gameId, CaptureHandle handle, List<CorrectedDart> corrected);

  /// All stored capture sidecars.
  Future<List<CaptureRecord>> list();

  /// Delete captures until total storage is within [policy].
  Future<void> enforceRetention(RetentionPolicy policy);

  /// Stream a `dartlodge-export-*.zip` to [destPath]: one image + one sidecar
  /// JSON per capture, with flat names. Reports fractional [onProgress] (0..1)
  /// as files are added. Bounded memory — does not assemble the archive in RAM
  /// (#468) — so it stays within the heap regardless of capture-folder size. The
  /// caller hands [destPath] to the OS share sheet.
  ///
  /// [extraFiles] are in-memory text entries embedded verbatim at their given
  /// `archivePath` (#686 single-zip export — used to add recorded session
  /// bundles under `sessions/`). The capture frames/sidecars stay at the zip
  /// root with flat names, so the `dartlodge-export-*.zip` ingest contract is
  /// unchanged; consumers that only read root `*.jpg`/`*.json` ignore the extras.
  Future<void> writeExportZip(String destPath,
      {void Function(double)? onProgress,
      List<({String archivePath, String content})> extraFiles = const []});

  /// Remove all stored captures.
  Future<void> clear();
}
