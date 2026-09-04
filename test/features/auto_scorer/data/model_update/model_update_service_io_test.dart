@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_ports.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service_io.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/staged_model_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/auto_scorer_model_manifest.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/staged_model_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeConnectivity implements ConnectivityPort {
  bool unmetered;
  _FakeConnectivity(this.unmetered);
  @override
  Future<bool> isUnmetered() async => unmetered;
}

/// Serves a canned manifest + binary keyed by URL. Records the URLs requested.
class _FakeHttp implements ModelHttpClient {
  String? manifestBody;
  Uint8List? binary;
  int binaryCalls = 0;
  Object? throwOnBinary;

  @override
  Future<String> getString(Uri url) async {
    if (manifestBody == null) throw const HttpException('no manifest');
    return manifestBody!;
  }

  @override
  Future<Uint8List> getBytes(Uri url) async {
    binaryCalls++;
    if (throwOnBinary != null) throw throwOnBinary!;
    if (binary == null) throw const HttpException('no binary');
    return binary!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory baseDir;
  late _FakeConnectivity connectivity;
  late _FakeHttp http;

  setUp(() async {
    baseDir = await Directory.systemTemp.createTemp('model_update_io_test');
    connectivity = _FakeConnectivity(true);
    http = _FakeHttp();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (await baseDir.exists()) await baseDir.delete(recursive: true);
  });

  Future<ModelUpdateServiceIo> service({bool isAndroid = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return ModelUpdateServiceIo(
      baseDir: baseDir,
      store: StagedModelStore(prefs),
      isAndroid: isAndroid,
      connectivity: connectivity,
      http: http,
      manifestUrl: 'https://example.test/manifest.json',
    );
  }

  const staged = StagedModelState(
    version: 'dart_round26_withcal',
    contract: kAutoScorerModelContract,
    sha256: 'abc',
    sizeBytes: 100,
  );

  Future<void> stageFile(ModelUpdateServiceIo svc, StagedModelState s) async {
    await baseDir.create(recursive: true);
    await File(svc.stagedPathFor(s.version)).writeAsBytes([1, 2, 3]);
    await svc.store.write(s);
  }

  // --- resolve() ---

  group('resolve', () {
    test('no staged state → bundled', () async {
      final r = await (await service()).resolve();
      expect(r.origin, ModelOrigin.bundled);
      expect(r.path, kAutoScorerModelAsset);
      expect(r.version, kAutoScorerModelVersion);
    });

    test('staged + present + Android → staged', () async {
      final svc = await service();
      await stageFile(svc, staged);
      final r = await svc.resolve();
      expect(r.origin, ModelOrigin.staged);
      expect(r.path, svc.stagedPathFor(staged.version));
      expect(r.version, staged.version);
    });

    test('staged persisted but file missing → bundled', () async {
      final svc = await service();
      await svc.store.write(staged);
      expect((await svc.resolve()).origin, ModelOrigin.bundled);
    });

    test('staged contract mismatch → bundled', () async {
      final svc = await service();
      await stageFile(
        svc,
        const StagedModelState(
          version: 'dart_round99_withcal',
          contract: 999,
          sha256: 'abc',
          sizeBytes: 100,
        ),
      );
      expect((await svc.resolve()).origin, ModelOrigin.bundled);
    });

    test('staged + present but non-Android → bundled', () async {
      final svc = await service(isAndroid: false);
      await stageFile(svc, staged);
      expect((await svc.resolve()).origin, ModelOrigin.bundled);
    });
  });

  // --- checkAndStage() ---

  group('checkAndStage', () {
    final modelBytes = Uint8List.fromList(List.filled(200, 7));

    AutoScorerModelManifest manifest({
      String version = 'dart_round26_withcal',
      int contract = kAutoScorerModelContract,
      int inputSize = 800,
      int classCount = 5,
      String? sha,
      int? size,
      String url =
          '${kModelReleaseUrlPrefix}model-round26/dart_auto_scorer.tflite',
    }) =>
        AutoScorerModelManifest(
          schema: 1,
          contract: contract,
          modelVersion: version,
          url: url,
          sha256: sha ?? sha256.convert(modelBytes).toString(),
          sizeBytes: size ?? modelBytes.length,
          inputSize: inputSize,
          classCount: classCount,
        );

    void serve(AutoScorerModelManifest m, {Uint8List? binary}) {
      http.manifestBody = jsonEncode(m.toJson());
      http.binary = binary ?? modelBytes;
    }

    test('happy path stages + persists + is then resolved', () async {
      final svc = await service();
      serve(manifest());
      await svc.checkAndStage();

      expect(await File(svc.stagedPathFor('dart_round26_withcal')).exists(),
          isTrue);
      expect(svc.store.read()?.version, 'dart_round26_withcal');
      expect(svc.status, ModelUpdateStatus.updateReady);
      expect((await svc.resolve()).origin, ModelOrigin.staged);
    });

    test('hash mismatch does not stage', () async {
      final svc = await service();
      serve(manifest(sha: 'f' * 64));
      await svc.checkAndStage();
      expect(await File(svc.stagedPathFor('dart_round26_withcal')).exists(),
          isFalse);
      expect(svc.store.read(), isNull);
      expect(svc.status, ModelUpdateStatus.checkFailed);
    });

    test('size mismatch does not stage', () async {
      final svc = await service();
      serve(manifest(size: 999));
      await svc.checkAndStage();
      expect(svc.store.read(), isNull);
      expect(svc.status, ModelUpdateStatus.checkFailed);
    });

    // The gap #782 was filed for: the manifest fetch succeeds, the asset URL
    // does not. Silently swallowing it made a broken channel read as "up to
    // date" in settings.
    test('a failed asset download reports a failed check and stages nothing',
        () async {
      final svc = await service();
      serve(manifest());
      http.throwOnBinary = const HttpException('Unexpected status 404');
      await svc.checkAndStage();

      expect(http.binaryCalls, 1);
      expect(svc.store.read(), isNull);
      expect(await File(svc.stagedPathFor('dart_round26_withcal')).exists(),
          isFalse);
      expect(svc.status, ModelUpdateStatus.checkFailed);
      expect((await svc.resolve()).origin, ModelOrigin.bundled);
    });

    test('an unreachable manifest reports a failed check', () async {
      final svc = await service();
      http.manifestBody = null; // _FakeHttp throws on getString
      await svc.checkAndStage();
      expect(http.binaryCalls, 0);
      expect(svc.status, ModelUpdateStatus.checkFailed);
    });

    test('incompatible contract skips before download', () async {
      final svc = await service();
      serve(manifest(contract: 999));
      await svc.checkAndStage();
      expect(http.binaryCalls, 0);
      expect(svc.store.read(), isNull);
    });

    // A staged model from before an app contract bump is one selectModel will
    // never apply. If the manifest is also incompatible we return before the
    // quarantine block, so the settled status must not read the lingering store
    // entry as a pending update and promise "applies next session".
    test('an incompatible manifest does not promise a stale staged model',
        () async {
      final svc = await service();
      await stageFile(
          svc,
          const StagedModelState(
            version: 'dart_round26_withcal',
            contract: kAutoScorerModelContract + 1, // staged under an old app
            sha256: 'abc',
            sizeBytes: 100,
          ));
      serve(manifest(contract: 999));
      await svc.checkAndStage();

      expect(http.binaryCalls, 0);
      expect(svc.status, ModelUpdateStatus.upToDate);
      expect((await svc.resolve()).origin, ModelOrigin.bundled);
    });

    test('a staged entry whose file vanished is not a pending update',
        () async {
      final svc = await service();
      await svc.store.write(staged); // state only, no file on disk
      serve(manifest(version: kAutoScorerModelVersion));
      await svc.checkAndStage();

      expect(svc.status, ModelUpdateStatus.upToDate);
      expect((await svc.resolve()).origin, ModelOrigin.bundled);
    });

    test('non-release url is rejected', () async {
      final svc = await service();
      serve(manifest(url: 'https://evil.test/model.tflite'));
      await svc.checkAndStage();
      expect(http.binaryCalls, 0);
      expect(svc.store.read(), isNull);
    });

    test('metered connection skips download', () async {
      connectivity.unmetered = false;
      final svc = await service();
      serve(manifest());
      await svc.checkAndStage();
      expect(http.binaryCalls, 0);
      expect(svc.store.read(), isNull);
      // A deferral, not a failure: nothing is wrong, so the row must not cry
      // wolf. The next launch retries.
      expect(svc.status, ModelUpdateStatus.upToDate);
    });

    test('version equal to bundled baseline is a no-op', () async {
      final svc = await service();
      serve(manifest(version: kAutoScorerModelVersion));
      await svc.checkAndStage();
      expect(http.binaryCalls, 0);
      expect(svc.status, ModelUpdateStatus.upToDate);
    });

    test('already-staged version is a no-op', () async {
      final svc = await service();
      await stageFile(svc, staged); // staged version == round26
      serve(manifest()); // manifest also round26
      await svc.checkAndStage();
      expect(http.binaryCalls, 0);
      // A model is still pending, so the no-op must not flatten the status to
      // "up to date" and drop the "applies next session" hint.
      expect(svc.status, ModelUpdateStatus.updateReady);
    });

    test('a second check after a successful stage keeps update-ready',
        () async {
      final svc = await service();
      serve(manifest());
      await svc.checkAndStage();
      expect(svc.status, ModelUpdateStatus.updateReady);

      // Same manifest: the second run takes the already-staged no-op path.
      await svc.checkAndStage();
      expect(svc.status, ModelUpdateStatus.updateReady);
    });

    // The loop #785 was filed for: without the record this manifest looks like
    // a fresh update at every launch.
    test('a quarantined version is never downloaded again', () async {
      final svc = await service();
      await svc.store.writeQuarantined('dart_round26_withcal');
      serve(manifest()); // same version
      await svc.checkAndStage();

      expect(http.binaryCalls, 0);
      expect(svc.store.read(), isNull);
      expect(svc.status, ModelUpdateStatus.updateRejected);
    });

    test('a newer version clears the quarantine and stages normally', () async {
      final svc = await service();
      await svc.store.writeQuarantined('dart_round26_withcal');
      serve(manifest(version: 'dart_round27_withcal'));
      await svc.checkAndStage();

      // One bad model must not block the ones published after it.
      expect(svc.store.readQuarantined(), isNull);
      expect(svc.store.read()?.version, 'dart_round27_withcal');
      expect(svc.status, ModelUpdateStatus.updateReady);
    });

    test('a contract bump does not record the staged model as rejected',
        () async {
      final svc = await service();
      await stageFile(
          svc,
          const StagedModelState(
            version: 'dart_round26_withcal',
            contract: kAutoScorerModelContract + 1,
            sha256: 'abc',
            sizeBytes: 100,
          ));
      // The same version, republished for this app's contract, must still be
      // accepted: a contract bump is housekeeping, not a verdict on the model.
      serve(manifest());
      await svc.checkAndStage();

      expect(svc.store.readQuarantined(), isNull);
      expect(svc.store.read()?.version, 'dart_round26_withcal');
      expect(svc.status, ModelUpdateStatus.updateReady);
    });

    test('non-Android never downloads', () async {
      final svc = await service(isAndroid: false);
      serve(manifest());
      await svc.checkAndStage();
      expect(http.binaryCalls, 0);
    });

    test('staging a new version deletes the previous staged file', () async {
      final svc = await service();
      await stageFile(
        svc,
        const StagedModelState(
          version: 'dart_round20_withcal',
          contract: kAutoScorerModelContract,
          sha256: 'old',
          sizeBytes: 3,
        ),
      );
      serve(manifest()); // round26
      await svc.checkAndStage();
      expect(await File(svc.stagedPathFor('dart_round20_withcal')).exists(),
          isFalse);
      expect(await File(svc.stagedPathFor('dart_round26_withcal')).exists(),
          isTrue);
    });

    test('quarantines a stale-contract staged model before staging the new one',
        () async {
      final svc = await service();
      await stageFile(
        svc,
        const StagedModelState(
          version: 'dart_round20_withcal',
          contract: 999, // stale w.r.t. a contract bump
          sha256: 'old',
          sizeBytes: 3,
        ),
      );
      serve(manifest()); // round26, current contract
      await svc.checkAndStage();
      // Stale file gone, new one staged, state points at the new version.
      expect(await File(svc.stagedPathFor('dart_round20_withcal')).exists(),
          isFalse);
      expect(await File(svc.stagedPathFor('dart_round26_withcal')).exists(),
          isTrue);
      expect(svc.store.read()?.version, 'dart_round26_withcal');
    });

    test('sweeps stray .part files', () async {
      final svc = await service();
      await baseDir.create(recursive: true);
      final stray = File('${svc.stagedPathFor('leftover')}.part');
      await stray.writeAsBytes([9]);
      serve(manifest());
      await svc.checkAndStage();
      expect(await stray.exists(), isFalse);
    });
  });

  // --- quarantine() ---

  test('quarantine deletes the staged file and clears state', () async {
    final svc = await service();
    await stageFile(svc, staged);
    await svc.quarantine(staged.version);
    expect(await File(svc.stagedPathFor(staged.version)).exists(), isFalse);
    expect(svc.store.read(), isNull);
    expect((await svc.resolve()).origin, ModelOrigin.bundled);
    expect(svc.status, ModelUpdateStatus.updateRejected);
  });

  // #785: clearing the staged state alone leaves nothing to tell a rejected
  // version from one never seen, so the next launch would fetch it again.
  test('quarantine records the version, and the record outlives the store',
      () async {
    final svc = await service();
    await stageFile(svc, staged);
    await svc.quarantine(staged.version);
    expect(svc.store.readQuarantined(), staged.version);

    // A second store over the same prefs stands in for the next app launch.
    final reborn = StagedModelStore(await SharedPreferences.getInstance());
    expect(reborn.readQuarantined(), staged.version);
  });

  test('quarantine with remember: false leaves no record', () async {
    final svc = await service();
    await stageFile(svc, staged);
    await svc.quarantine(staged.version, remember: false);
    expect(svc.store.read(), isNull);
    expect(svc.store.readQuarantined(), isNull);
  });

  test('isSupported reflects the Android flag', () async {
    expect((await service()).isSupported, isTrue);
    expect((await service(isAndroid: false)).isSupported, isFalse);
  });
}
