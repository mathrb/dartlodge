import 'package:dart_lodge/features/auto_scorer/domain/recording/session_trace.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

/// One tracker emission aligned (by order) with the camera `DartThrown` the game
/// recorded for it. [matches] when both sides agree on `(baseNumber,
/// multiplier)` — a mismatch flags a bug on the emission→game path.
class CorrelatedDart {
  final int index;
  final int trackerBaseNumber;
  final int trackerMultiplier;
  final String trackerSegment;
  final int gameBaseNumber;
  final int gameMultiplier;

  const CorrelatedDart({
    required this.index,
    required this.trackerBaseNumber,
    required this.trackerMultiplier,
    required this.trackerSegment,
    required this.gameBaseNumber,
    required this.gameMultiplier,
  });

  bool get matches =>
      trackerBaseNumber == gameBaseNumber &&
      trackerMultiplier == gameMultiplier;

  @override
  String toString() => 'dart $index: tracker '
      '$trackerSegment ($trackerBaseNumber×$trackerMultiplier) vs game '
      '($gameBaseNumber×$gameMultiplier)${matches ? '' : ' MISMATCH'}';
}

/// The alignment between the tracker's emitted darts and the game's camera
/// `DartThrown` events.
class CameraCorrelation {
  /// Pairs in order, up to the shorter of the two sequences.
  final List<CorrelatedDart> darts;

  /// Emitted darts the tracker reported (the trace, `emitted == true`).
  final int trackerEmittedCount;

  /// Camera-sourced `DartThrown` events the game recorded (originals; corrected
  /// darts keep their original event in the log, which is what the tracker
  /// emitted).
  final int gameCameraCount;

  const CameraCorrelation({
    required this.darts,
    required this.trackerEmittedCount,
    required this.gameCameraCount,
  });

  /// Same number of darts on both sides AND every pair agrees.
  bool get isAligned =>
      trackerEmittedCount == gameCameraCount && darts.every((d) => d.matches);

  List<CorrelatedDart> get mismatches => [
        for (final d in darts) if (!d.matches) d,
      ];
}

/// Correlate the tracker's emitted darts (from [trace]) with the camera
/// `DartThrown` events the game recorded (from [events]) — the Nth emission ↔
/// the Nth camera dart. Localises a divergence: a count mismatch (dropped/extra
/// dart) or a `(baseNumber, multiplier)` mismatch (the game recorded something
/// other than what the tracker emitted).
CameraCorrelation correlateCameraDarts(
    SessionTrace trace, List<GameEvent> events) {
  final emitted = <RecordedEmission>[
    for (final line in trace.lines)
      if (line is TraceFrame)
        for (final d in line.outcome.newDarts)
          if (d.emitted) d,
  ];

  final cameraDarts = <GameEvent>[
    for (final e in events)
      if (e.eventType == 'DartThrown' && e.payload['input_method'] == 'camera')
        e,
  ];

  final n = emitted.length < cameraDarts.length
      ? emitted.length
      : cameraDarts.length;
  final darts = <CorrelatedDart>[
    for (var i = 0; i < n; i++)
      CorrelatedDart(
        index: i,
        trackerBaseNumber: emitted[i].baseNumber,
        trackerMultiplier: emitted[i].multiplier,
        trackerSegment: emitted[i].segment,
        gameBaseNumber: cameraDarts[i].payload['segment'] as int,
        gameMultiplier: cameraDarts[i].payload['multiplier'] as int,
      ),
  ];

  return CameraCorrelation(
    darts: darts,
    trackerEmittedCount: emitted.length,
    gameCameraCount: cameraDarts.length,
  );
}
