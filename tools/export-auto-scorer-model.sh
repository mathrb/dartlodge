#!/usr/bin/env bash
# Export the auto-scorer YOLO model (.pt) to the on-device formats the
# ultralytics_yolo plugin loads: TFLite (Android) + CoreML (iOS). (#378 §2)
#
# WHY THIS IS A SCRIPT, NOT CI: the TFLite path drags in a heavy, version-
# sensitive toolchain (tensorflow + onnx2tf + tf_keras) and needs ~10 GB of
# free disk. It will NOT run in a constrained sandbox. Run it on a dev/ML box.
#
# Pins that actually work together (newer TF drops tf_keras and breaks onnx2tf):
#   tensorflow-cpu==2.19.0  tf-keras==2.19.0  onnx2tf  onnxslim  onnxruntime
#
# Usage:
#   tools/export-auto-scorer-model.sh /path/to/dart_round6_withcal.pt
#
# Then bundle the output and declare it:
#   cp <model>_float32.tflite assets/models/dart_auto_scorer.tflite
#   # add `assets/models/dart_auto_scorer.tflite` under `flutter: assets:` in pubspec.yaml
#   # (CoreML .mlpackage → ios/Runner/, but ios/ is gitignored — bundle per machine)
#
# The model must clear the §2 recall gate (dart recall ~0.95) before auto-EMISSION
# is enabled; below that the app still captures training data (#381).
set -euo pipefail

PT="${1:?usage: export-auto-scorer-model.sh <model.pt>}"
IMGSZ=800
VENV="$(mktemp -d)/export-venv"

command -v uv >/dev/null || { echo "needs 'uv' (https://docs.astral.sh/uv/)"; exit 1; }

echo "==> isolated venv: $VENV"
uv venv "$VENV" --python 3.12
PY="$VENV/bin/python"

echo "==> install pinned export toolchain (~heavy; needs ~10 GB free disk)"
uv pip install --python "$PY" \
  ultralytics onnx onnxslim onnxruntime sng4onnx \
  "tensorflow-cpu==2.19.0" "tf-keras==2.19.0" onnx2tf coremltools

echo "==> TFLite export"
TF_USE_LEGACY_KERAS=1 "$PY" - "$PT" "$IMGSZ" <<'PY'
import sys
from ultralytics import YOLO
pt, imgsz = sys.argv[1], int(sys.argv[2])
print("TFLite:", YOLO(pt).export(format="tflite", imgsz=imgsz))
PY

echo "==> CoreML export"
"$PY" - "$PT" "$IMGSZ" <<'PY'
import sys
from ultralytics import YOLO
pt, imgsz = sys.argv[1], int(sys.argv[2])
print("CoreML:", YOLO(pt).export(format="coreml", imgsz=imgsz, nms=False))
PY

echo "==> done. Outputs are next to $PT (look for *_float32.tflite and *.mlpackage)."
