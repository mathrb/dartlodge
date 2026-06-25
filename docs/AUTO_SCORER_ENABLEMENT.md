# Enabling the camera auto-scorer

The on-device auto-scorer (epic #377) ships **code-complete but disabled** — the
"Use auto-scoring" switch is default-off and labelled beta. These are the
operational steps to actually turn it on for a build. None of this is enforced
in code; it's a deploy checklist.

> Architecture note: the **model export lives in the training repo**
> (`deep-darts-probe`), not here. The Flutter app only *consumes* the produced
> `.tflite`. There is intentionally no TensorFlow/export toolchain in this repo.

## 1. Produce the model (`deep-darts-probe`)

The detector loads `assets/models/dart_auto_scorer.tflite`
(`kAutoScorerModelAsset`). Produce it from the trained `.pt` with the probe's
export module (`dart-train/export_mobile.py`):

```bash
cd ~/git/deep-darts-probe
export PATH="$HOME/.local/bin:$PATH"
uv run \
  --with "tensorflow-cpu==2.19.0" --with "tf-keras==2.19.0" \
  --with onnx2tf --with onnxslim --with onnxruntime --with sng4onnx \
  python dart-train/export_mobile.py models/dart_round<N>_withcal.pt
```

This writes
`models/dart_round<N>_withcal_saved_model/dart_round<N>_withcal_float32.tflite`
(Android). The TF /
`onnx2tf` / `tf_keras` toolchain is version-fragile and needs ~10 GB free disk;
the pins above are the known-good combo. (Add `--coreml` + `--with coremltools`
for the iOS `.mlpackage`.)

The model classes are `{0: dart, 1: cal1, 2: cal2, 3: cal3, 4: cal4}` at
`imgsz 800`. The app **letterboxes** frames to 800×800 (scale-to-fit + grey 114
pad) so edge calibration points aren't cropped (was a center-crop; see `#377`
§3). The probe trained at `imgsz 800` — to match inference, training should
letterbox too (tracked in `#393`).

## 2. Bundle it

```bash
cp ~/git/deep-darts-probe/models/dart_round<N>_withcal_saved_model/dart_round<N>_withcal_float32.tflite \
   assets/models/dart_auto_scorer.tflite
```

Then declare it in `pubspec.yaml` (only once the file exists — a declared-but-
missing asset breaks the build):

```yaml
flutter:
  assets:
    - assets/models/dart_auto_scorer.tflite
```

The `.tflite` is ~10–25 MB; committing it bloats every clone. For a solo build
that's fine; otherwise consider git-lfs or a build-time fetch. The CoreML
`.mlpackage` (if produced) goes to `ios/Runner/` (gitignored, per machine).

## 3. Camera permission

- **Android — nothing to do.** `camera_android_camerax` declares
  `<uses-permission android:name="android.permission.CAMERA"/>` in its own
  manifest; Gradle merges it into the app.
- **iOS — one line.** After `flutter create --platforms=ios .`, add to
  `ios/Runner/Info.plist` (`ios/` is gitignored/scaffolded per machine):

  ```xml
  <key>NSCameraUsageDescription</key>
  <string>DartLodge uses the camera to automatically score your darts.</string>
  ```

## 4. Use it (and the recall caveat)

Settings → **Camera auto-scoring** → turn on **Use auto-scoring** (and
**Collect training data** to harvest samples). On an X01/Cricket board, the
3-dot menu then shows **Auto-scoring**, which opens the camera capture page.
Detected darts are emitted into the game with `input_method: 'camera'`.

**There is no code-enforced accuracy gate.** When the toggle is on and a model
is loaded, every detected dart is emitted. Per `#377` §2 the ship signal is the
model's real-board accuracy, not "the code works". The probe ranks rounds by
per-dart segment accuracy on the raw serve golden; the bundled round's score
(see `kAutoScorerModelVersion` in `dart_detector.dart`, then the probe for that
round's metrics) has not cleared the **88.9%** ship bar at 720p, so treat it as
**assist / data-collection only** — don't trust the emitted scores yet.

## Known gaps (deferred)

Two spec items are intentionally not wired yet (functional audit, 2026-06-03):

- **Corrected frames aren't flagged in training data.** `CaptureStore.applyCorrection`
  exists but isn't called from the board's per-dart correction flow, so
  `was_corrected` / `corrected_darts` stay empty in exported sidecars. Wiring it
  is cross-feature and needs the capture turn-ordinal seeded from game state so
  handles align. Workaround: the **force-capture** button grabs missed/mis-scored
  frames directly, which covers the high-value cases.
- **No mid-game on-screen master toggle.** §5.1 wants a quick board toggle to
  flip auto-scoring off mid-game. The overlay's **Stop** button stops detection
  on the board (covers the practical need); flipping the master pref still
  requires the Settings page.

### Improving the model (the data loop)

1. Run with **Collect training data** on; the capture loop stores each frame +
   your per-dart corrections.
2. Export from the settings page (share sheet → `dartlodge-export-<ts>.zip`).
3. In the probe: ingest the zip, annotate/retrain → `dart_round<N+1>_withcal.pt`,
   and **measure dart recall on a held-out test set from your board**.
4. When recall clears your bar, re-export (step 1) and re-bundle (step 2).
