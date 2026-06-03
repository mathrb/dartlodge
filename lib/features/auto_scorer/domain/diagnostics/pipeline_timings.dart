/// Per-frame timing breakdown for the assist-mode pipeline (#377 §3 lag
/// investigation). Each tick is `capture → detect → track`; this records how
/// long each stage took so we can *attribute* perceived slowness to a stage
/// (still capture, on-device inference, or the tracker) rather than guess.
///
/// Pure data — surfaced only when the diagnostics HUD is enabled. `detect`
/// covers everything inside [DartDetector.detect] (our 800×800 preprocess +
/// the native inference round-trip); the "skip preprocessing" A/B toggle is how
/// we split those two without timing inside the platform plugin.
class PipelineTimings {
  /// `takePicture()` + reading the bytes back (the still-capture cost).
  final Duration capture;

  /// `DartDetector.detect()` end to end (preprocess + native inference).
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
