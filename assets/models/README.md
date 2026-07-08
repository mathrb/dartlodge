# Auto-scorer model assets

`dart_auto_scorer.tflite` is the on-device dart-detection model (#377/#378),
loaded via `kAutoScorerModelAsset`. It is produced from the trained `.pt` by the
**training repo** (`deep-darts-probe`), not here — see
[`docs/AUTO_SCORER_ENABLEMENT.md`](../../docs/AUTO_SCORER_ENABLEMENT.md) for the
export + bundle steps. To refresh it:

```bash
cd ~/git/deep-darts-probe
uv run --with "tensorflow-cpu==2.19.0" --with "tf-keras==2.19.0" \
  --with onnx2tf --with onnxslim --with onnxruntime --with sng4onnx \
  python dart-train/export_mobile.py models/dart_round<N>_withcal.pt
cp ~/git/deep-darts-probe/models/dart_round<N>_withcal_saved_model/dart_round<N>_withcal_float32.tflite \
   assets/models/dart_auto_scorer.tflite
```

Keep `kAutoScorerModelVersion` (in `dart_detector.dart`) in lock-step with the
bundled stem — it is stamped onto every training capture's `model_version`.

The current bundle is `dart_round25_withcal` (float32) — single net, classes
`{0:dart, 1:cal1, 2:cal2, 3:cal3, 4:cal4}`, imgsz 800, YOLO11n. It supersedes
R24; see the probe for R25's metrics (per-dart assist-mode segment accuracy on
the raw serve golden). The probe ranks rounds by **per-dart segment accuracy
(assist-mode) on the raw serve golden**, not mAP/recall. Until a round is
confirmed past the **88.9%** ship bar there is **no code-enforced emission
gate**: treat auto-scoring as assist / data-collection (#381). The app serves
the raw sensor frame as-is (no app-side rotation), so portrait-held detection
depends on the model being trained for that orientation (#393) — collect
portrait frames via the in-app capture button. The CoreML `.mlpackage` (iOS)
goes to `ios/Runner/` (gitignored).

Frames are preprocessed to 800×800 (**letterbox**: scale-to-fit + grey 114
padding) before inference, so the board's outer calibration points are never
cropped out. (Was a center-crop, which clipped edge cal points when the board
filled the frame — see #377 §3.) The probe trained at `imgsz 800`; for best
results training should letterbox to match (#393). A "Skip preprocessing" toggle
in settings bypasses our step to feed raw frames to the plugin's own native
letterbox (faster, near-equivalent input).

## Out-of-band model updates (#715)

On **Android**, the app can fetch an improved model at runtime and use it in
place of the bundled asset — no Play release — while staying safe: a downloaded
model is used only after a strict compatibility + integrity gate, and the
bundled asset is never deleted, so scoring can never break.

- **Manifest** — `model_manifest.json` at the repo root, committed on `main`,
  served over HTTPS from `raw.githubusercontent.com/mathrb/dartlodge/main/`. It
  points at the latest model and carries (snake_case keys) `contract`, `sha256`,
  `size_bytes`, `input_size`, `class_count`, `format`. The baseline commit
  points at the current
  bundled `dart_round25_withcal`, so an app on the shipped model is a clean
  no-op.
- **Binaries** — GitHub Releases of `mathrb/dartlodge` under a dedicated
  `model-*` tag prefix (e.g. `model-round26`), **never committed to git**. These
  tags do NOT trigger `release.yml` (it fires on `v*` only), so publishing a
  model never builds an APK/AAB.
- **Compatibility contract** — `kAutoScorerModelContract` (in `dart_detector.dart`).
  A model is accepted only when `manifest.contract == kAutoScorerModelContract`
  (strict), plus the sanity gate `inputSize == 800 && classCount == 5 &&
  format == 'tflite'`. **Bump the contract** whenever the class set/count, input
  size, preprocessing, or threshold semantics change — this forces a real Play
  release for those users and auto-invalidates any already-staged model (its
  persisted contract no longer matches → the resolver falls back to bundled and
  the stale file is quarantined).
- **Integrity + provenance** — the downloaded bytes must match `sha256` and
  `sizeBytes`, and `manifest.url` must live under the app-repo release prefix.
- **Lifecycle** — a silent background check at launch when auto-scoring is
  enabled, download only on an unmetered connection, applied at the **next**
  session (never a hot swap mid-game). A staged model that fails to load
  natively is quarantined (deleted) and the bundled model is used.
- **iOS** — OTA is Android-only: iOS uses a CoreML `.mlpackage` (in
  `ios/Runner/`), so a `.tflite` can't be swapped in there. The manifest's
  `format` field keeps a future iOS `.mlpackage` channel additive.

**Publishing a new model** (from the private `deep-darts-probe`, same boundary as
#393): export/bundle the `.tflite`, create a `model-<round>` release with it,
compute its SHA-256, then update `model_manifest.json` on `main`. The publishing
script lives in the probe repo (out of scope here).
