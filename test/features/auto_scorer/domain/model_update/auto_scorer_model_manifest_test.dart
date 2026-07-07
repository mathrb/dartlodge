import 'dart:convert';
import 'dart:io';

import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/auto_scorer_model_manifest.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/model_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> sampleJson() => {
        'schema': 1,
        'contract': 1,
        'model_version': 'dart_round26_withcal',
        'url': 'https://github.com/mathrb/dartlodge/releases/download/'
            'model-round26/dart_auto_scorer.tflite',
        'sha256': 'a' * 64,
        'size_bytes': 10727799,
        'input_size': 800,
        'class_count': 5,
        'format': 'tflite',
      };

  test('round-trips toJson/fromJson', () {
    final parsed = AutoScorerModelManifest.fromJson(sampleJson());
    expect(parsed.schema, 1);
    expect(parsed.contract, 1);
    expect(parsed.modelVersion, 'dart_round26_withcal');
    expect(parsed.sizeBytes, 10727799);
    expect(parsed.inputSize, 800);
    expect(parsed.classCount, 5);
    expect(parsed.format, 'tflite');
    expect(parsed.toJson(), sampleJson());
  });

  test('defaults missing format to tflite', () {
    final json = sampleJson()..remove('format');
    expect(AutoScorerModelManifest.fromJson(json).format, 'tflite');
  });

  test('tolerates unknown keys', () {
    final json = sampleJson()..['future_field'] = 'ignored';
    expect(AutoScorerModelManifest.fromJson(json).modelVersion,
        'dart_round26_withcal');
  });

  test('accepts numeric fields provided as doubles', () {
    final json = sampleJson()
      ..['size_bytes'] = 10727799.0
      ..['input_size'] = 800.0;
    final parsed = AutoScorerModelManifest.fromJson(json);
    expect(parsed.sizeBytes, 10727799);
    expect(parsed.inputSize, 800);
  });

  test('throws on a missing load-bearing key', () {
    final json = sampleJson()..remove('url');
    expect(() => AutoScorerModelManifest.fromJson(json), throwsA(anything));
  });

  // Guards the real on-disk manifest against key-casing / field drift: it must
  // parse with fromJson and clear the compatibility gate, otherwise the OTA
  // check silently no-ops (the service swallows the parse error).
  test('the committed model_manifest.json parses and is compatible', () {
    final file = File('model_manifest.json');
    expect(file.existsSync(), isTrue,
        reason: 'model_manifest.json missing at repo root');
    final manifest = AutoScorerModelManifest.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
    expect(manifest.contract, kAutoScorerModelContract);
    expect(isManifestCompatible(manifest), isTrue);
  });
}
