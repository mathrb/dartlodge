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

  /// Build a `dartlodge-export-*.zip` payload: one image + one sidecar JSON per
  /// capture. The caller hands the bytes to the OS share sheet.
  Future<Uint8List> buildExportZip();

  /// Remove all stored captures.
  Future<void> clear();
}
