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

The current bundle is `dart_round7_withcal` (float32) — single net, classes
`{0:dart, 1:cal1, 2:cal2, 3:cal3, 4:cal4}`, imgsz 800. Metrics: mAP50 0.95, cal
recall 0.94–1.00, **dart recall 0.747** — below the §2 ship bar (~0.95), so there
is **no code-enforced emission gate**: treat auto-scoring as assist /
data-collection (#381) until a later round clears the bar. The CoreML
`.mlpackage` (iOS) goes to `ios/Runner/` (gitignored).

Frames are preprocessed to 800×800 (center-crop) before inference, matching the
training parity (#377 §2). A "Skip preprocessing" toggle in settings can bypass
that to feed raw frames to the plugin's native resize (faster, but a different
input distribution than the model trained on).
