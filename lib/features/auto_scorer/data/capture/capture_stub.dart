import 'dart:typed_data';

import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_record.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/retention_policy.dart';

/// Web stub for the capture store (#377 §8): the auto-scorer is invisible on
/// web, so this no-op keeps `flutter run -d chrome` building without pulling in
/// `dart:io` / `share_plus`. [isSupported] is false; callers must not surface
/// capture or export on web.
class _UnsupportedCaptureStore implements CaptureStore {
  const _UnsupportedCaptureStore();

  @override
  bool get isSupported => false;

  @override
  Future<void> save(CaptureRecord record, Uint8List frameBytes) async {}

  @override
  Future<void> applyCorrection(String gameId, CaptureHandle handle,
      List<CorrectedDart> corrected) async {}

  @override
  Future<List<CaptureRecord>> list() async => const [];

  @override
  Future<void> enforceRetention(RetentionPolicy policy) async {}

  @override
  Future<Uint8List> buildExportZip() async =>
      throw UnsupportedError('Capture export is not available on web.');

  @override
  Future<void> clear() async {}
}

Future<CaptureStore> openDefaultCaptureStore() async =>
    const _UnsupportedCaptureStore();

Future<void> shareCaptureZip(Uint8List zipBytes, String fileName) async {}
