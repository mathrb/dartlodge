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

This writes `models/dart_round<N>_withcal_float32.tflite` (Android). The TF /
`onnx2tf` / `tf_keras` toolchain is version-fragile and needs ~10 GB free disk;
the pins above are the known-good combo. (Add `--coreml` + `--with coremltools`
for the iOS `.mlpackage`.)

The model classes are `{0: dart, 1: cal1, 2: cal2, 3: cal3, 4: cal4}` at
`imgsz 800` — matching the in-app preprocessing parity (`#377` §2).

## 2. Bundle it

```bash
cp ~/git/deep-darts-probe/models/dart_round<N>_withcal_float32.tflite \
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

**There is no code-enforced recall gate.** When the toggle is on and a model is
loaded, every detected dart is emitted. Per `#377` §2 the ship signal is model
recall (~0.95 dart recall on your real board), not "the code works". The current
`dart_round6_withcal` is ~0.795, so treat it as **assist / data-collection
only** — don't trust the emitted scores yet.

### Improving the model (the data loop)

1. Run with **Collect training data** on; the capture loop stores each frame +
   your per-dart corrections.
2. Export from the settings page (share sheet → `dartlodge-export-<ts>.zip`).
3. In the probe: ingest the zip, annotate/retrain → `dart_round<N+1>_withcal.pt`,
   and **measure dart recall on a held-out test set from your board**.
4. When recall clears your bar, re-export (step 1) and re-bundle (step 2).
