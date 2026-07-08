import 'package:dart_lodge/features/auto_scorer/domain/detection/dart_detector.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/auto_scorer_model_manifest.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/resolved_model.dart';
import 'package:dart_lodge/features/auto_scorer/domain/model_update/staged_model_state.dart';

/// Whether the app may download + stage the model this [manifest] describes
/// (#715). Two gates, both must pass:
///
///  1. **Primary contract gate** — strict `manifest.contract ==
///     kAutoScorerModelContract`. An app only accepts a model built for the
///     exact I/O + scoring semantics it knows.
///  2. **Secondary sanity gate** (defense-in-depth) — the declared input size,
///     class count, and format match what this app feeds/decodes. Guards against
///     a well-formed but mis-declared manifest.
bool isManifestCompatible(AutoScorerModelManifest manifest) {
  if (manifest.contract != kAutoScorerModelContract) return false;
  return manifest.inputSize == 800 &&
      manifest.classCount == 5 &&
      manifest.format == 'tflite';
}

/// The bundled app model — the guaranteed fallback, used whenever a staged model
/// is unavailable/invalid. Shared so every fallback path resolves identically.
const ResolvedModel kBundledResolvedModel = ResolvedModel(
  path: kAutoScorerModelAsset,
  version: kAutoScorerModelVersion,
  origin: ModelOrigin.bundled,
);

/// Selects the effective model for a session (#715). Returns the [staged] model
/// only when EVERY condition holds; otherwise the [bundled] app asset, which is
/// never deleted and so is the guaranteed fallback:
///
///  - [isAndroid] — over-the-air is Android-only (iOS uses a CoreML
///    `.mlpackage`, so a downloaded `.tflite` would fail native load),
///  - a [staged] state is persisted,
///  - [stagedFilePresent] — its file actually exists on disk,
///  - `staged.contract == kAutoScorerModelContract` — it isn't stale w.r.t. a
///    contract bump shipped in a newer app version.
///
/// Callers stat the file and pass [stagedFilePresent] so this stays pure.
ResolvedModel selectModel({
  required StagedModelState? staged,
  required bool stagedFilePresent,
  required bool isAndroid,
  required String stagedPath,
}) {
  const bundled = kBundledResolvedModel;
  if (!isAndroid) return bundled;
  if (staged == null || !stagedFilePresent) return bundled;
  if (staged.contract != kAutoScorerModelContract) return bundled;
  return ResolvedModel(
    path: stagedPath,
    version: staged.version,
    origin: ModelOrigin.staged,
  );
}
