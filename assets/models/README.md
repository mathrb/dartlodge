# Auto-scorer model assets

The on-device dart-detection model (#378) is **not committed** — it is produced
from the probe's trained `.pt` by `tools/export-auto-scorer-model.sh` and dropped
here as `dart_auto_scorer.tflite` (Android/TFLite). The CoreML `.mlpackage` goes
to `ios/Runner/` (gitignored — bundle per machine).

The detector loads `assets/models/dart_auto_scorer.tflite` (see
`kAutoScorerModelAsset`). Once the file is here, declare it under `flutter:
assets:` in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/dart_auto_scorer.tflite
```

The model is exported from `deep-darts-probe/models/dart_round<N>_withcal.pt`
(single net: classes `{0:dart, 1:cal1, 2:cal2, 3:cal3, 4:cal4}`, imgsz 800).
Auto-**emission** stays gated until a model clears the §2 recall bar (dart
recall ~0.95); current round6 recall is ~0.795, so the app captures training
data (#381) but does not yet auto-emit.
