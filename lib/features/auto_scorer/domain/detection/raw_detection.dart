/// One raw model detection: its class index and the **normalised** (0–1) centre
/// of its bounding box in the detection frame, plus confidence. The platform
/// detector produces these; [buildDetectionFrame] turns them into the tracker's
/// [DetectionFrame].
class RawDetection {
  final int classIndex;
  final double x;
  final double y;
  final double conf;

  const RawDetection({
    required this.classIndex,
    required this.x,
    required this.y,
    required this.conf,
  });
}
