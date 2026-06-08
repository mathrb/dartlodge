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

The current bundle is `dart_round12a_withcal` (float32) — single net, classes
`{0:dart, 1:cal1, 2:cal2, 3:cal3, 4:cal4}`, imgsz 800, YOLO11n. It supersedes
R11b (86.5% assist-mode segment accuracy on the R7-independent golden); see the
probe for R12a's metrics. The probe ranks rounds by **per-dart segment accuracy
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
