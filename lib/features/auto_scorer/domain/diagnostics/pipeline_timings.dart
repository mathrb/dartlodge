/// Per-frame timing breakdown for the assist-mode pipeline (#377 §3 lag
/// investigation). Each tick is `capture → detect → track`; this records how
/// long each stage took so we can *attribute* perceived slowness to a stage
/// (still capture, on-device inference, or the tracker) rather than guess.
///
/// Pure data. On the YOLOView streaming path inference runs natively inside
/// the plugin, so only `track` is measured; `capture` and `detect` stay zero.
class PipelineTimings {
  /// Still-capture cost. Not measured on the YOLOView path.
  final Duration capture;

  /// On-device inference. Not measured on the YOLOView path (runs natively).
  final Duration detect;

  /// `DartTracker.processFrame()` — expected to be negligible.
  final Duration track;

  const PipelineTimings({
    this.capture = Duration.zero,
    this.detect = Duration.zero,
    this.track = Duration.zero,
  });

  Duration get total => capture + detect + track;

  PipelineTimings copyWith({Duration? capture, Duration? detect, Duration? track}) =>
      PipelineTimings(
        capture: capture ?? this.capture,
        detect: detect ?? this.detect,
        track: track ?? this.track,
      );

  @override
  String toString() =>
      'PipelineTimings(cap=${capture.inMilliseconds}ms, det=${detect.inMilliseconds}ms, '
      'trk=${track.inMilliseconds}ms, total=${total.inMilliseconds}ms)';
}
