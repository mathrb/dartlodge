import 'package:dart_lodge/features/auto_scorer/domain/capture/capture_handle.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/corrected_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/capture/predicted_dart.dart';
import 'package:dart_lodge/features/auto_scorer/domain/entities/board_point.dart';

/// The coordinate space the stored capture image lives in, so the probe knows
/// how to overlay the sidecar's normalised coords and apply the serve-identical
/// transform (#2026-06-04 raw-capture brief). `raw` = the verbatim camera frame
/// (skip-preprocess / native inference path); `letterbox800` = our 800×800
/// letterbox (legacy preprocess path). Wire values are stable JSON strings.
enum FrameSpace {
  raw('raw'),
  letterbox800('letterbox_800');

  const FrameSpace(this.wire);

  /// Stable JSON value written to / read from the sidecar's `frame_space` key.
  final String wire;

  static FrameSpace fromWire(String value) => values.firstWhere(
        (s) => s.wire == value,
        // Pre-brief sidecars carry no frame_space and were always 800 letterbox.
        orElse: () => FrameSpace.letterbox800,
      );
}

/// The sidecar record stored alongside each captured frame (#381 §6).
///
/// Every detection — and especially every correction — is a labelled training
/// example. The JSON shape is the probe's ingest contract; do not add or rename
/// keys without the reciprocal `ddp-preprocess` change in the probe repo.
/// (The `frame_space` / `frame_width` / `frame_height` keys added by the
/// raw-capture brief need that reciprocal probe change to be consumed.)
class CaptureRecord {
  final List<PredictedDart> predictedDarts;
  final List<BoardPoint> calPoints;
  final List<CorrectedDart> correctedDarts;
  final String modelVersion;
  final String gameId;
  final CaptureHandle handle;
  final DateTime timestamp;
  final bool wasCorrected;

  /// Coordinate space + pixel dims of the stored image, so the probe can treat
  /// the coords correctly and re-derive any view. Defaults match a pre-brief
  /// 800×800 letterbox capture for backward-compatibility.
  final FrameSpace frameSpace;
  final int frameWidth;
  final int frameHeight;

  const CaptureRecord({
    required this.predictedDarts,
    required this.calPoints,
    required this.modelVersion,
    required this.gameId,
    required this.handle,
    required this.timestamp,
    this.correctedDarts = const [],
    this.wasCorrected = false,
    this.frameSpace = FrameSpace.letterbox800,
    this.frameWidth = 800,
    this.frameHeight = 800,
  });

  Map<String, dynamic> toJson() => {
        'predicted_darts': [for (final d in predictedDarts) d.toJson()],
        'cal_points': [
          for (final p in calPoints) {'x': p.x, 'y': p.y}
        ],
        'corrected_darts': [for (final d in correctedDarts) d.toJson()],
        'model_version': modelVersion,
        'game_id': gameId,
        'capture_handle': handle.key,
        'timestamp': timestamp.toIso8601String(),
        'was_corrected': wasCorrected,
        'frame_space': frameSpace.wire,
        'frame_width': frameWidth,
        'frame_height': frameHeight,
      };

  factory CaptureRecord.fromJson(Map<String, dynamic> json) => CaptureRecord(
        predictedDarts: [
          for (final d in (json['predicted_darts'] as List))
            PredictedDart.fromJson((d as Map).cast<String, dynamic>())
        ],
        calPoints: [
          for (final p in (json['cal_points'] as List))
            (x: ((p as Map)['x'] as num).toDouble(), y: (p['y'] as num).toDouble())
        ],
        correctedDarts: [
          for (final d in (json['corrected_darts'] as List? ?? const []))
            CorrectedDart.fromJson((d as Map).cast<String, dynamic>())
        ],
        modelVersion: json['model_version'] as String,
        gameId: json['game_id'] as String,
        handle: CaptureHandle.parse(json['capture_handle'] as String),
        timestamp: DateTime.parse(json['timestamp'] as String),
        wasCorrected: json['was_corrected'] as bool? ?? false,
        // Pre-brief sidecars: no frame_space / dims → 800×800 letterbox.
        frameSpace: FrameSpace.fromWire(json['frame_space'] as String? ?? ''),
        frameWidth: json['frame_width'] as int? ?? 800,
        frameHeight: json['frame_height'] as int? ?? 800,
      );

  /// Returns a copy with the user's correction applied: replaces
  /// [correctedDarts] and flips [wasCorrected] true. Keyed by [handle], so this
  /// survives the event-id churn that per-dart correction causes (#376 §3.1).
  CaptureRecord withCorrection(List<CorrectedDart> corrected) => CaptureRecord(
        predictedDarts: predictedDarts,
        calPoints: calPoints,
        correctedDarts: corrected,
        modelVersion: modelVersion,
        gameId: gameId,
        handle: handle,
        timestamp: timestamp,
        wasCorrected: true,
        frameSpace: frameSpace,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
}
