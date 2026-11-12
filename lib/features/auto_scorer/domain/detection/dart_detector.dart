/// Canonical bundled-model asset path (#377 §2). The TFLite/CoreML model is
/// produced from the probe's `.pt` by `deep-darts-probe`'s
/// `dart-train/export_mobile.py` and bundled here (see
/// `docs/AUTO_SCORER_ENABLEMENT.md`).
const String kAutoScorerModelAsset = 'assets/models/dart_auto_scorer.tflite';

/// Stem of the bundled model's source `.pt`, recorded as `model_version` on
/// every training capture so the probe can attribute each sample to the model
/// that produced its predictions. Matches the probe's `pre_annotate` stem
/// convention — bump this in lock-step with [kAutoScorerModelAsset].
const String kAutoScorerModelVersion = 'dart_round27_withcal';

/// The over-the-air (#715) model **compatibility contract** the app understands.
/// A downloaded model is accepted only when its manifest declares the exact same
/// contract number (strict `==`), so an app can never load a model whose I/O or
/// scoring semantics it wasn't built for.
///
/// **Bump this whenever any of these change** (they alter how the app feeds or
/// interprets the model, so an old app must NOT use a new-contract model):
///  - the class set / count (`{0:dart, 1:cal1..4}`),
///  - the input size (currently 800×800),
///  - the preprocessing (letterbox scale-to-fit + grey-114 padding),
///  - the confidence/IoU threshold semantics.
///
/// A bump auto-invalidates any already-staged model (its persisted contract no
/// longer matches → the resolver falls back to the bundled asset and the stale
/// file is quarantined), and forces a real Play release for those users.
const int kAutoScorerModelContract = 1;
