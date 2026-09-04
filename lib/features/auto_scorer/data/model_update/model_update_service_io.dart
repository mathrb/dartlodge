import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_io_adapters.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_ports.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/model_update_service.dart';
import 'package:dart_lodge/features/auto_scorer/data/model_update/staged_model_store.dart';
import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/auto_scorer_model_manifest.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/model_compatibility.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/staged_model_state.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The stable manifest URL. Committed on `main` and served over HTTPS from the
/// pinned raw GitHub host. Updated in place per model publication.
const String kDefaultModelManifestUrl =
    'https://raw.githubusercontent.com/mathrb/dartlodge/main/model_manifest.json';

/// Authenticity anchor for the binary: the manifest's `url` MUST live under this
/// prefix (a `model-*` release of the app repo). Combined with the SHA-256 check
/// this pins provenance even though the final byte stream is served from GitHub's
/// redirected CDN host.
const String kModelReleaseUrlPrefix =
    'https://github.com/mathrb/dartlodge/releases/download/';

/// Mobile/desktop [ModelUpdateService] (#715). Only ever loaded where `dart:io`
/// exists (conditionally imported in place of the web stub).
///
/// [baseDir] (the on-disk staging directory), the [StagedModelStore],
/// [isAndroid], the [ConnectivityPort], [ModelHttpClient], and [manifestUrl] are
/// all injected so the whole pipeline is unit-testable against a temp directory
/// + fakes without a real device or network.
class ModelUpdateServiceIo implements ModelUpdateService {
  final Directory baseDir;
  final StagedModelStore store;
  final bool isAndroid;
  final ConnectivityPort connectivity;
  final ModelHttpClient http;
  final String manifestUrl;

  ModelUpdateServiceIo({
    required this.baseDir,
    required this.store,
    required this.isAndroid,
    required this.connectivity,
    required this.http,
    this.manifestUrl = kDefaultModelManifestUrl,
  });

  ModelUpdateStatus _status = ModelUpdateStatus.upToDate;

  @override
  bool get isSupported => isAndroid;

  @override
  ModelUpdateStatus get status => _status;

  /// Absolute path a staged model of [version] would occupy.
  String stagedPathFor(String version) =>
      p.join(baseDir.path, '$version.tflite');

  File _partFile(String version) => File('${stagedPathFor(version)}.part');

  @override
  Future<ResolvedModel> resolve() async {
    final staged = store.read();
    final path = staged == null ? '' : stagedPathFor(staged.version);
    final present = staged != null && await File(path).exists();
    return selectModel(
      staged: staged,
      stagedFilePresent: present,
      isAndroid: isAndroid,
      stagedPath: path,
    );
  }

  /// What is on disk right now, with no network check: a recorded rejection, a
  /// staged model pending, or nothing to report.
  ///
  /// Serves two callers. [checkAndStage] assigns it at every non-failing exit
  /// so the status reflects this run rather than whatever the previous one left
  /// behind (#782); it must not be flattened to [ModelUpdateStatus.upToDate]
  /// there, because a second check in the same launch takes the "already
  /// staged" no-op path and that would erase the "applies next session" hint
  /// the user just earned. And the settings row reads it directly, so it stops
  /// stating a verdict when no check has run at all (#786) — which happens on
  /// every launch with auto-scoring switched off, since the launch check is
  /// gated on that switch.
  ///
  /// It asks [resolve] rather than testing `store.read() != null`, so the row
  /// can only promise an update the resolver would actually apply. A persisted
  /// entry is not enough on its own: the staged file may be gone, or the entry
  /// may predate a contract bump — and the incompatible-manifest exit returns
  /// before the quarantine block that would have cleared it.
  ///
  /// The rejection branch is unreachable from [checkAndStage]: every call site
  /// there sits after the quarantine block, which has either returned or
  /// cleared the record. It exists for the settings row, which has no such
  /// guarantee.
  @override
  Future<ModelUpdateStatus> restingStatus() async {
    if (store.readQuarantined() != null) return ModelUpdateStatus.updateRejected;
    return (await resolve()).origin == ModelOrigin.staged
        ? ModelUpdateStatus.updateReady
        : ModelUpdateStatus.upToDate;
  }

  @override
  Future<void> checkAndStage() async {
    if (!isAndroid) return;
    try {
      await _sweepPartials();
      final manifest = AutoScorerModelManifest.fromJson(
          jsonDecode(await http.getString(Uri.parse(manifestUrl)))
              as Map<String, dynamic>);

      // Ahead of the compatibility gate on purpose: a version already rejected
      // at native load must not be downloaded again, and the rejection is a
      // fact about that version whatever the manifest's contract says. Behind
      // the gate, an incompatible manifest would settle the status through
      // _settledStatus() and quietly replace "could not be used" with "up to
      // date", undoing for this state what #782 fixed for the others.
      //
      // The record is needed at all because quarantine clears the staged state:
      // without it the manifest looks like a fresh update at every launch and
      // the same asset is fetched, staged and rejected forever (#785). Any
      // other version clears it, so one bad model never blocks its successors.
      final quarantined = store.readQuarantined();
      if (quarantined != null) {
        // The record goes stale two ways. The manifest moves on to another
        // version, or a later app release promotes the rejected version into
        // the bundle: the rejection was a verdict on a downloaded artifact, and
        // the asset shipped inside the APK is not that artifact. Without the
        // second case the row would read "could not be used" forever while the
        // app happily ran that very version.
        if (quarantined == kAutoScorerModelVersion ||
            manifest.modelVersion != quarantined) {
          await store.clearQuarantined();
        } else {
          _status = ModelUpdateStatus.updateRejected;
          return;
        }
      }

      // Compatibility gate: contract + sanity fields must match this app.
      if (!isManifestCompatible(manifest)) {
        _status = await restingStatus();
        return;
      }

      // A contract bump in a newer app version leaves any previously-staged
      // model stale: selectModel already falls back to bundled, but proactively
      // quarantine it here so the stale file + state don't linger.
      var current = store.read();
      if (current != null && current.contract != kAutoScorerModelContract) {
        // remember: false — a contract bump makes the staged file unusable by
        // this app, but says nothing about the model itself. Recording it as
        // rejected would refuse the same version once it is republished for the
        // new contract.
        await quarantine(current.version, remember: false);
        current = null;
      }

      // Re-check no-op: already staged, or same as the bundled baseline.
      if (manifest.modelVersion == current?.version ||
          manifest.modelVersion == kAutoScorerModelVersion) {
        _status = await restingStatus();
        return;
      }

      // Provenance: the asset must be an app-repo release download.
      if (!manifest.url.startsWith(kModelReleaseUrlPrefix)) {
        _status = await restingStatus();
        return;
      }

      // Only download on an unmetered connection. A deferral, not a failure:
      // the check will run again at the next launch.
      if (!await connectivity.isUnmetered()) {
        _status = await restingStatus();
        return;
      }

      final bytes = await http.getBytes(Uri.parse(manifest.url));

      // Integrity: exact size + SHA-256 of the downloaded bytes. A mismatch
      // means the channel delivered the wrong bytes, so it is reported as a
      // failed check rather than silently swallowed.
      if (bytes.length != manifest.sizeBytes) {
        _status = ModelUpdateStatus.checkFailed;
        return;
      }
      if (sha256.convert(bytes).toString() != manifest.sha256.toLowerCase()) {
        _status = ModelUpdateStatus.checkFailed;
        return;
      }

      // Stage atomically: write to <version>.tflite.part on the same filesystem,
      // then rename into place. A crash mid-write leaves only a .part (swept next
      // run); the bundled asset is never touched.
      await baseDir.create(recursive: true);
      final part = _partFile(manifest.modelVersion);
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(stagedPathFor(manifest.modelVersion));

      // Drop the previously-staged model (only one is ever kept).
      if (current != null && current.version != manifest.modelVersion) {
        final prev = File(stagedPathFor(current.version));
        if (await prev.exists()) await prev.delete();
      }

      await store.write(StagedModelState(
        version: manifest.modelVersion,
        contract: manifest.contract,
        sha256: manifest.sha256,
        sizeBytes: manifest.sizeBytes,
      ));
      _status = ModelUpdateStatus.updateReady;
    } catch (_) {
      // Best-effort: any failure (offline, HTTP error, bad manifest, I/O error)
      // leaves the bundled model in place and never throws. It is recorded so
      // the settings row can say the check failed instead of claiming the model
      // is up to date (#782).
      _status = ModelUpdateStatus.checkFailed;
    }
  }

  @override
  Future<void> quarantine(String version, {bool remember = true}) async {
    final file = File(stagedPathFor(version));
    if (await file.exists()) await file.delete();
    await store.clear();
    if (!remember) return;
    await store.writeQuarantined(version);
    _status = ModelUpdateStatus.updateRejected;
  }

  /// Delete stray `*.part` files left by a killed/failed download.
  Future<void> _sweepPartials() async {
    if (!await baseDir.exists()) return;
    await for (final entity in baseDir.list()) {
      if (entity is File && entity.path.endsWith('.part')) {
        await entity.delete();
      }
    }
  }
}

Future<ModelUpdateService> openModelUpdateService(
    SharedPreferences prefs) async {
  final support = await getApplicationSupportDirectory();
  final baseDir = Directory(p.join(support.path, 'auto_scorer', 'models'));
  // Debug-only manifest URL override for local testing (a --dart-define in a
  // release build is ignored, so the pinned URL is always used in production).
  const override = String.fromEnvironment('MODEL_MANIFEST_URL');
  final manifestUrl =
      (!kReleaseMode && override.isNotEmpty) ? override : kDefaultModelManifestUrl;
  return ModelUpdateServiceIo(
    baseDir: baseDir,
    store: StagedModelStore(prefs),
    isAndroid: Platform.isAndroid,
    connectivity: ConnectivityPlusPort(),
    http: const HttpClientModelHttp(),
    manifestUrl: manifestUrl,
  );
}
