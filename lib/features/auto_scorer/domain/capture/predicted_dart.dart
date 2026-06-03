/// A model-predicted dart tip: position (normalised 0–1 in the 800×800 frame)
/// and detector confidence. Stored verbatim in the capture sidecar so the
/// probe can re-ingest the raw prediction alongside any correction (#381).
class PredictedDart {
  final double x;
  final double y;
  final double conf;

  const PredictedDart({required this.x, required this.y, required this.conf});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'conf': conf};

  factory PredictedDart.fromJson(Map<String, dynamic> json) => PredictedDart(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        conf: (json['conf'] as num).toDouble(),
      );
}
