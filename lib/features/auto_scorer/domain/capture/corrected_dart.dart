/// A user-confirmed dart tip after per-dart correction (#376): its position
/// (normalised 0–1 in the detection frame) and the canonical [segment] the user
/// settled on. The probe loads these as pre-confirmed annotations (#381 §6).
class CorrectedDart {
  final double x;
  final double y;

  /// Canonical segment string (`'20'`, `'D20'`, `'T20'`, `'SB'`, `'DB'`,
  /// `'MISS'`).
  final String segment;

  const CorrectedDart({required this.x, required this.y, required this.segment});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'segment': segment};

  factory CorrectedDart.fromJson(Map<String, dynamic> json) => CorrectedDart(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        segment: json['segment'] as String,
      );
}
