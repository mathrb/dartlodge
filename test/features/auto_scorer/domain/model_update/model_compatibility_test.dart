import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/auto_scorer_model_manifest.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/model_compatibility.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/staged_model_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AutoScorerModelManifest manifest({
    int contract = kAutoScorerModelContract,
    int inputSize = 800,
    int classCount = 5,
    String format = 'tflite',
  }) =>
      AutoScorerModelManifest(
        schema: 1,
        contract: contract,
        modelVersion: 'dart_round26_withcal',
        url: 'https://example.test/model.tflite',
        sha256: 'a' * 64,
        sizeBytes: 100,
        inputSize: inputSize,
        classCount: classCount,
        format: format,
      );

  group('isManifestCompatible', () {
    test('accepts a matching contract + sane sanity fields', () {
      expect(isManifestCompatible(manifest()), isTrue);
    });

    test('rejects a mismatched contract', () {
      expect(isManifestCompatible(manifest(contract: 999)), isFalse);
    });

    test('rejects wrong input size', () {
      expect(isManifestCompatible(manifest(inputSize: 640)), isFalse);
    });

    test('rejects wrong class count', () {
      expect(isManifestCompatible(manifest(classCount: 4)), isFalse);
    });

    test('rejects a non-tflite format', () {
      expect(isManifestCompatible(manifest(format: 'mlpackage')), isFalse);
    });
  });

  group('selectModel', () {
    const stagedPath = '/data/models/dart_round26_withcal.tflite';
    StagedModelState staged({int contract = kAutoScorerModelContract}) =>
        StagedModelState(
          version: 'dart_round26_withcal',
          contract: contract,
          sha256: 'a' * 64,
          sizeBytes: 100,
        );

    void expectBundled(ResolvedModel r) {
      expect(r.origin, ModelOrigin.bundled);
      expect(r.path, kAutoScorerModelAsset);
      expect(r.version, kAutoScorerModelVersion);
    }

    test('no staged state → bundled', () {
      expectBundled(selectModel(
        staged: null,
        stagedFilePresent: false,
        isAndroid: true,
        stagedPath: stagedPath,
      ));
    });

    test('staged + present + Android → staged', () {
      final r = selectModel(
        staged: staged(),
        stagedFilePresent: true,
        isAndroid: true,
        stagedPath: stagedPath,
      );
      expect(r.origin, ModelOrigin.staged);
      expect(r.path, stagedPath);
      expect(r.version, 'dart_round26_withcal');
    });

    test('staged + present but iOS → bundled', () {
      expectBundled(selectModel(
        staged: staged(),
        stagedFilePresent: true,
        isAndroid: false,
        stagedPath: stagedPath,
      ));
    });

    test('staged contract mismatch → bundled', () {
      expectBundled(selectModel(
        staged: staged(contract: 999),
        stagedFilePresent: true,
        isAndroid: true,
        stagedPath: stagedPath,
      ));
    });

    test('staged file absent → bundled', () {
      expectBundled(selectModel(
        staged: staged(),
        stagedFilePresent: false,
        isAndroid: true,
        stagedPath: stagedPath,
      ));
    });
  });
}
