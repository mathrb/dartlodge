import 'package:dart_lodge/features/game/domain/entities/game_event.dart';

/// A resolved current-turn dart: its `DartThrown` [eventId], plus the
/// [cameraDartOrdinal] the auto-scorer keys its training captures on.
typedef TurnDartRef = ({String eventId, int? cameraDartOrdinal});

/// Resolve the live `DartThrown` event for dart [turnDartIndex] (0-based, throw
/// order) of [competitorId]'s current turn — the last [dartsThrownInTurn] live
/// (non-corrected, non-superseded) darts in [events]. Returns null if out of
/// range.
///
/// [TurnDartRef.cameraDartOrdinal] is the **1-based position of this dart among
/// the turn's camera-sourced darts** (`input_method == 'camera'`), counting up
/// to and including it — which is the ordinal the auto-scorer numbers its
/// per-dart capture handles by (only camera-emitted darts advance that count).
/// It is **null when the dart is manual**: a manually-entered dart has no camera
/// capture, so a correction must not touch any capture (#469). Counting by
/// throw-order position instead — which includes manual darts — is exactly the
/// bug this resolves: after a manual insertion the two numbering schemes diverge.
TurnDartRef? resolveTurnDart({
  required List<GameEvent> events,
  required String competitorId,
  required int dartsThrownInTurn,
  required int turnDartIndex,
}) {
  final n = dartsThrownInTurn;
  if (turnDartIndex < 0 || turnDartIndex >= n) return null;

  final correctedIds = <String>{};
  final supersededIds = <String>{};
  for (final e in events) {
    if (e.eventType != 'DartCorrected') continue;
    final origId = e.payload['original_event_id'];
    if (origId is String) correctedIds.add(origId);
    final superseded = e.payload['superseded_event_ids'];
    if (superseded is List) {
      for (final id in superseded) {
        if (id is String) supersededIds.add(id);
      }
    }
  }

  final liveForComp = [
    for (final e in events)
      if (e.eventType == 'DartThrown' &&
          e.payload['competitor_id'] == competitorId &&
          !correctedIds.contains(e.eventId) &&
          !supersededIds.contains(e.eventId))
        e,
  ];
  if (liveForComp.length < n) return null;
  final turnDarts = liveForComp.sublist(liveForComp.length - n);

  final dart = turnDarts[turnDartIndex];
  int? cameraDartOrdinal;
  if (dart.payload['input_method'] == 'camera') {
    var count = 0;
    for (var i = 0; i <= turnDartIndex; i++) {
      if (turnDarts[i].payload['input_method'] == 'camera') count++;
    }
    cameraDartOrdinal = count;
  }
  return (eventId: dart.eventId, cameraDartOrdinal: cameraDartOrdinal);
}
