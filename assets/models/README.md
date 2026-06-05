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

The current bundle is `dart_round11b_withcal` (float32) — single net, classes
`{0:dart, 1:cal1, 2:cal2, 3:cal3, 4:cal4}`, imgsz 800, YOLO11n, trained on the
666-frame center-crop arm + 141 raw app set (mosaic ON). The probe now ranks
rounds by **per-dart segment accuracy (assist-mode) on the raw serve golden**,
not mAP/recall: R11b scores **86.5%** on the R7-independent subset (87.3% full)
vs R7's 84.3%/84.9% — a real win, but still below the **88.9%** ship bar at 720p
(≈92% at 1080p). So there is still **no code-enforced emission gate**: treat
auto-scoring as assist / data-collection (#381) until a round clears the bar.
The CoreML `.mlpackage` (iOS) goes to `ios/Runner/` (gitignored).

Frames are preprocessed to 800×800 (**letterbox**: scale-to-fit + grey 114
padding) before inference, so the board's outer calibration points are never
cropped out. (Was a center-crop, which clipped edge cal points when the board
filled the frame — see #377 §3.) The probe trained at `imgsz 800`; for best
results training should letterbox to match (#393). A "Skip preprocessing" toggle
in settings bypasses our step to feed raw frames to the plugin's own native
letterbox (faster, near-equivalent input).
