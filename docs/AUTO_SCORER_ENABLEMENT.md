# Camera auto-scorer: how it is wired and how to ship a model

The on-device auto-scorer (epic #377) is part of every build: the model is
bundled at `assets/models/dart_auto_scorer.tflite`, and on Android it can be
replaced at runtime by an out-of-band (OTA) model (#715, see
[`assets/models/README.md`](../assets/models/README.md)). The feature is
opt-in — the **Use auto-scoring** switch is default-off and always labelled
beta. This page covers how a player turns it on, and how a new model gets from
the training repo into the app.

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
`imgsz 800`. The app does no preprocessing of its own: `YOLOView` hands the raw
camera analysis frame to the plugin, which letterboxes it natively to 800×800
(scale-to-fit + padding), so edge calibration points are never cropped. The
probe trained at `imgsz 800` — to match inference, training should letterbox
too (tracked in `#393`).

## 2. Ship it

There are two channels; a new round normally goes out through both.

**Bundled asset (every platform, needs an app release).** Copy the export over
the asset that `pubspec.yaml` already declares:

```bash
cp ~/git/deep-darts-probe/models/dart_round<N>_withcal_saved_model/dart_round<N>_withcal_float32.tflite \
   assets/models/dart_auto_scorer.tflite
```

Then bump `kAutoScorerModelVersion` (in `dart_detector.dart`) to the new stem,
and update the "current bundle" line in `assets/models/README.md`, in the same
PR. The `.tflite` is ~11 MB and committed to git. The CoreML `.mlpackage` (if
produced) goes to `ios/Runner/` (gitignored, per machine).

**OTA update (Android only, no app release).** Publish the `.tflite` as a
`model-<round>` GitHub Release and point `model_manifest.json` on `main` at it.
The manifest fields, the `kAutoScorerModelContract` compatibility gate and the
download lifecycle are documented in
[`assets/models/README.md`](../assets/models/README.md#out-of-band-model-updates-715).
Bump the contract (which forces a real app release) whenever the class set,
input size, preprocessing or threshold semantics change.

## 3. Camera permission

- **Android — nothing to do.** `ultralytics_yolo` declares
  `<uses-permission android:name="android.permission.CAMERA"/>` in its own
  manifest; Gradle merges it into the app.
- **iOS — one line.** After `flutter create --platforms=ios .`, add to
  `ios/Runner/Info.plist` (`ios/` is gitignored/scaffolded per machine):

  ```xml
  <key>NSCameraUsageDescription</key>
  <string>DartLodge uses the camera to automatically score your darts.</string>
  ```

## 4. Use it (and the recall caveat)

Settings → **Auto-scoring** → turn on **Use auto-scoring**. The same page holds
**Auto-advance turn when board is cleared** (with its **Board-clear wait**
preset) and **Record for debugging & training** (stores frames and the
detection stream for export).

With auto-scoring on, the X01, Cricket, Count-Up and practice boards switch to
a camera-first layout (`cameraFirst = autoScoringOn && cameraPreview != null`
in each board page; see `docs/rules/auto-scorer.md`). **Start camera** opens a
one-time aim view (skipped for the rest of the app run once completed; the
running preview's **Re-aim camera** button re-runs it), then the live `YOLOView` preview runs
on the board. Detected darts reach the game through the core `DartInputSink`
each board binds, with `input_method: 'camera'`.

**There is no code-enforced accuracy gate.** When the toggle is on and a model
is loaded, every detected dart is emitted. Per `#377` §2 the ship signal is the
model's real-board accuracy, not "the code works". The probe ranks rounds by
per-dart segment accuracy on the raw serve golden; the bundled round's score
(see `kAutoScorerModelVersion` in `dart_detector.dart`, then the probe for that
round's metrics) has not cleared the **88.9%** ship bar at 720p, so treat it as
**assist / data-collection only** — don't trust the emitted scores yet.

## Known gaps (deferred)

- **No mid-game on-screen master toggle.** §5.1 wants a quick board toggle to
  flip auto-scoring off mid-game. The overlay's **Stop auto-scoring** button
  stops detection on the board (covers the practical need); flipping the master
  pref still requires the Settings page.

### Improving the model (the data loop)

1. Play with **Record for debugging & training** on; the capture loop stores
   each frame + your per-dart corrections.
2. **Export recordings** from the settings page (share sheet →
   `dartlodge-export-<ts>.zip`).
3. In the probe: ingest the zip, annotate/retrain → `dart_round<N+1>_withcal.pt`,
   and **measure per-dart accuracy on a held-out set from your board**.
4. When it clears your bar, export it (section 1) and ship it (section 2): an OTA
   release for Android players now, and the bundled asset for the next app
   release.
