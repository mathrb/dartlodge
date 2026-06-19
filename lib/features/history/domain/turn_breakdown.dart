import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/core/utils/cricket_segment_utils.dart';
import 'package:dart_lodge/features/game/domain/engines/base_game_engine.dart';
import 'package:dart_lodge/features/game/domain/engines/game_engine_factory.dart';
import 'package:dart_lodge/features/game/domain/entities/competitor.dart';
import 'package:dart_lodge/features/game/domain/entities/game.dart';
import 'package:dart_lodge/features/game/domain/entities/game_event.dart';
import 'package:dart_lodge/features/game/domain/models/game_config.dart';
import 'package:dart_lodge/features/game/domain/models/game_state.dart';
import 'package:dart_lodge/features/statistics/domain/engines/segment_utils.dart';

/// Turn-by-turn (or, for ATC, per-segment) breakdown derived from the game's
/// event log. Used by the history game-detail view to show what happened
/// inside each leg.
///
/// Construction is pure: the builder replays events through the appropriate
/// game engine starting from `GameState.initial(...)`, then captures the
/// per-turn snapshots needed to render the shape required by the UI for each
/// game type. Around-the-Clock skips the per-turn rows entirely and emits a
/// per-segment hit-rate summary instead.
class LegTurnBreakdown {
  const LegTurnBreakdown({
    this.turns = const [],
    this.atcSegments = const [],
  });

  final List<TurnRow> turns;
  final List<SegmentHitRate> atcSegments;

  bool get isEmpty => turns.isEmpty && atcSegments.isEmpty;
}

class TurnRow {
  const TurnRow({
    required this.round,
    required this.competitorId,
    required this.competitorName,
    required this.darts,
    required this.turnScore,
    this.startingScore,
    this.endingScore,
    this.remainingScore,
    this.bust = false,
    this.checkout = false,
    this.targetValue,
    this.hitsOnTarget,
    this.runningTotal,
    this.targetCompleted,
    this.shanghai,
  });

  /// Per-competitor turn index (1-based) — the "round" for round-based games.
  final int round;
  final String competitorId;
  final String competitorName;

  /// Canonical segment strings ('20', 'D5', 'T20', 'SB', 'DB', 'MISS').
  final List<String> darts;

  /// Sum of raw segment values for the darts in this turn (or in this row,
  /// for game types that group darts differently — e.g. Catch 40 spans up
  /// to 6 darts per row).
  final int turnScore;

  // X01 / Bobs27 / Catch 40 / 170-Checkout
  final int? startingScore;
  final int? remainingScore;
  final int? endingScore;
  final bool bust;
  final bool checkout;

  // Bobs27: target = round, hits = darts matching D{round}.
  // Catch 40: target = 61..100, hits = same as darts.length, completed flag.
  // Shanghai: target = round, shanghai flag = single+double+triple of target.
  final int? targetValue;
  final int? hitsOnTarget;
  final int? runningTotal;
  final bool? targetCompleted;
  final bool? shanghai;
}

class SegmentHitRate {
  const SegmentHitRate({
    required this.segmentLabel,
    required this.attempts,
    required this.hits,
  });

  final String segmentLabel;
  final int attempts;
  final int hits;

  double get hitRate => attempts == 0 ? 0 : hits / attempts;
}

class TurnBreakdownBuilder {
  const TurnBreakdownBuilder();

  /// Returns one [LegTurnBreakdown] per `LegCompleted` event in [events],
  /// keyed by 1-based leg number.
  ///
  /// [events] must be sorted ascending by `localSequence`.
  Map<int, LegTurnBreakdown> build({
    required Game game,
    required List<Competitor> competitors,
    required List<GameEvent> events,
  }) {
    if (competitors.isEmpty) return const {};

    final isAtc = game.gameType == GameType.aroundTheClock;
    final isCatch40 = game.gameType == GameType.catch40;

    final engine = GameEngineFactory.createEngine(game.gameType);
    var state = GameState.initial(game, competitors);

    final result = <int, LegTurnBreakdown>{};
    var legNumber = 1;
    var turns = <TurnRow>[];
    var atc = _AtcTracker();
    _OpenTurn? openTurn;
    // Per-competitor 1-based round counter, derived from the order of
    // TurnStarted events in this leg. Production providers stamp
    // `turn_index` with `currentTurnIndex` (the *competitor index*, 0..N-1),
    // so we cannot use it as a round number directly — see #256. Resets on
    // every LegCompleted.
    final perCompetitorTurnCount = <String, int>{};

    GameState pre = state;

    for (final event in events) {
      pre = state;

      switch (event.eventType) {
        case 'TurnStarted':
          final compId = event.payload['competitor_id'] as String? ?? '';
          final round =
              (perCompetitorTurnCount[compId] ?? 0) + 1;
          perCompetitorTurnCount[compId] = round;
          openTurn = _OpenTurn(
            preState: pre,
            competitorId: compId,
            turnIndex: round,
          );
          state = engine.apply(state, event).state;
          continue;

        case 'DartThrown':
          final segment = _segmentFromPayload(event.payload);
          final canonical = segment.toCanonicalString();
          openTurn?.darts.add(canonical);
          if (isAtc) {
            final compId = event.payload['competitor_id'] as String? ?? '';
            final preComp = pre.competitors
                .where((c) => c.competitorId == compId)
                .firstOrNull;
            if (preComp != null) {
              final target = preComp.currentTarget;
              if (target != null) {
                atc.recordAttempt(target);
                if (segment.baseNumber == target) {
                  atc.recordHit(target);
                }
              }
            }
          }
          final r = engine.apply(state, event);
          state = r.state;
          if (r.outcome == LegOutcome.legCompleted ||
              r.outcome == LegOutcome.gameCompleted) {
            openTurn?.checkoutOnDart = true;
          }
          continue;

        case 'TurnEnded':
          state = engine.apply(state, event).state;
          if (openTurn != null) {
            final reason =
                (event.payload['reason'] as String?) ?? 'normal';
            final row = _buildTurnRow(
              gameType: game.gameType,
              openTurn: openTurn,
              postState: state,
              bust: reason == 'bust',
            );
            if (isAtc) {
              // ATC has no per-turn rows.
            } else if (isCatch40) {
              _appendCatch40Row(turns, openTurn, state, row);
            } else {
              turns.add(row);
            }
            openTurn = null;
          }
          continue;

        case 'LegCompleted':
          state = engine.apply(state, event).state;
          if (isAtc) {
            result[legNumber] = LegTurnBreakdown(
              atcSegments: atc.snapshot(),
            );
            atc = _AtcTracker();
          } else {
            result[legNumber] = LegTurnBreakdown(turns: List.unmodifiable(turns));
            turns = <TurnRow>[];
          }
          legNumber++;
          perCompetitorTurnCount.clear();
          continue;

        default:
          state = engine.apply(state, event).state;
      }
    }

    // Games that never fire `LegCompleted` (Checkout Practice — the engine
    // tracks attempts via `practiceSuccesses` and ends the drill with a
    // bare `GameCompleted`) still want their turn rows surfaced as
    // "leg 1". Without this flush, the per-attempt breakdown was invisible
    // on the History → game detail page (#343).
    if (game.gameType == GameType.checkoutPractice && turns.isNotEmpty) {
      result[legNumber] = LegTurnBreakdown(turns: List.unmodifiable(turns));
    }

    return result;
  }

  TurnRow _buildTurnRow({
    required GameType gameType,
    required _OpenTurn openTurn,
    required GameState postState,
    required bool bust,
  }) {
    final preComp = openTurn.preState.competitors
        .where((c) => c.competitorId == openTurn.competitorId)
        .firstOrNull;
    final postComp = postState.competitors
        .where((c) => c.competitorId == openTurn.competitorId)
        .firstOrNull;

    final round = openTurn.turnIndex;
    final darts = openTurn.darts;
    final turnScore =
        darts.fold<int>(0, (s, d) => s + Segment.parse(d).scoreValue);
    final competitorName = preComp?.name ?? '';

    switch (gameType) {
      case GameType.x01:
        final starting = preComp?.score;
        final checkout = openTurn.checkoutOnDart;
        final remaining = bust
            ? starting
            : checkout
                ? 0
                : (starting ?? 0) - turnScore;
        return TurnRow(
          round: round,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: turnScore,
          startingScore: starting,
          remainingScore: remaining,
          bust: bust,
          checkout: checkout,
        );

      case GameType.cricket:
        // Marks scored this turn — only hits on the active cricket targets
        // count (15–20 + Bull for fixed; the rolled set for random/crazy). A
        // dart on a non-target number scores 0, exactly like a MISS — so an
        // auto-scored '4'/'10'/etc. is not miscounted as a mark (#569). Uses
        // the shared `cricketMarksForSegment` (same source of truth as the
        // stats projections). Targets are constant within a turn
        // (CrazyTargetsRolled fires right after TurnStarted), so postState
        // holds this turn's set.
        final targets = {...postState.cricketTargets, 25};
        final marks = darts.fold<int>(
          0,
          (s, d) => s + cricketMarksForSegment(d, targets: targets),
        );
        return TurnRow(
          round: round,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: marks,
          runningTotal: postComp?.score,
        );

      case GameType.bobs27:
        final target = preComp?.practiceRound ?? round;
        final hits = darts.where((d) => d == 'D$target').length;
        final delta = hits > 0 ? hits * target * 2 : -target * 2;
        return TurnRow(
          round: target,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: delta,
          targetValue: target,
          hitsOnTarget: hits,
          runningTotal: postComp?.score,
        );

      case GameType.shanghai:
        final shanghaiRound = preComp?.practiceRound ?? round;
        final segments = darts.map(Segment.parse).toList();
        final onTarget = segments
            .where((seg) => !seg.isMiss && seg.baseNumber == shanghaiRound)
            .toList();
        final hitsOnTarget = onTarget.length;
        final hasSingle = onTarget.any((s) => s.multiplier == 1);
        final hasDouble = onTarget.any((s) => s.multiplier == 2);
        final hasTriple = onTarget.any((s) => s.multiplier == 3);
        final shanghai = hasSingle && hasDouble && hasTriple;
        final scored =
            onTarget.fold<int>(0, (acc, s) => acc + s.scoreValue);
        return TurnRow(
          round: shanghaiRound,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: scored,
          targetValue: shanghaiRound,
          hitsOnTarget: hitsOnTarget,
          runningTotal: postComp?.score,
          shanghai: shanghai,
        );

      case GameType.checkoutPractice:
        final starting = preComp?.score;
        final checkout = openTurn.checkoutOnDart;
        final ending = bust
            ? starting
            : checkout
                ? 0
                : (starting ?? 0) - turnScore;
        return TurnRow(
          round: round,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: turnScore,
          startingScore: starting,
          endingScore: ending,
          bust: bust,
          checkout: checkout,
        );

      case GameType.catch40:
        // Catch 40 row is built up across multiple turns by _appendCatch40Row;
        // here we return a per-turn slice that the caller merges.
        final target = 60 + (preComp?.practiceRound ?? 1);
        final hits = darts.where((d) => d != 'MISS').length;
        final completed = (postComp?.practiceSuccesses ?? 0) >
            (preComp?.practiceSuccesses ?? 0);
        return TurnRow(
          round: preComp?.practiceRound ?? 1,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: turnScore,
          targetValue: target,
          hitsOnTarget: hits,
          runningTotal: postComp?.score,
          targetCompleted: completed,
        );

      case GameType.countUp:
        return TurnRow(
          round: round,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: turnScore,
          runningTotal: postComp?.score,
        );

      default:
        return TurnRow(
          round: round,
          competitorId: openTurn.competitorId,
          competitorName: competitorName,
          darts: darts,
          turnScore: turnScore,
        );
    }
  }

  /// Catch 40 fans a single target across up to two engine turns. Merge
  /// consecutive turn rows that share `(competitorId, targetValue)` into a
  /// single row with combined darts + final completed flag.
  void _appendCatch40Row(
    List<TurnRow> turns,
    _OpenTurn openTurn,
    GameState postState,
    TurnRow newRow,
  ) {
    if (turns.isNotEmpty) {
      final last = turns.last;
      if (last.competitorId == newRow.competitorId &&
          last.targetValue == newRow.targetValue &&
          last.targetCompleted != true) {
        turns[turns.length - 1] = TurnRow(
          round: last.round,
          competitorId: last.competitorId,
          competitorName: last.competitorName,
          darts: [...last.darts, ...newRow.darts],
          turnScore: last.turnScore + newRow.turnScore,
          targetValue: last.targetValue,
          hitsOnTarget: (last.hitsOnTarget ?? 0) + (newRow.hitsOnTarget ?? 0),
          runningTotal: newRow.runningTotal,
          targetCompleted: newRow.targetCompleted,
        );
        return;
      }
    }
    turns.add(newRow);
  }

  Segment _segmentFromPayload(Map<String, dynamic> payload) {
    final raw = readSegmentFromPayload(payload);
    if (raw.segment == 0) return const Segment.miss();
    if (raw.segment == 25) {
      return raw.multiplier == 2
          ? const Segment.doubleBull()
          : const Segment.singleBull();
    }
    return switch (raw.multiplier) {
      2 => Segment.doubleSegment(raw.segment),
      3 => Segment.triple(raw.segment),
      _ => Segment.single(raw.segment),
    };
  }
}

class _OpenTurn {
  _OpenTurn({
    required this.preState,
    required this.competitorId,
    required this.turnIndex,
  });

  final GameState preState;
  final String competitorId;
  final int turnIndex;
  final List<String> darts = [];
  bool checkoutOnDart = false;
}

class _AtcTracker {
  final Map<int, int> _attempts = {};
  final Map<int, int> _hits = {};

  void recordAttempt(int target) {
    _attempts[target] = (_attempts[target] ?? 0) + 1;
  }

  void recordHit(int target) {
    _hits[target] = (_hits[target] ?? 0) + 1;
  }

  List<SegmentHitRate> snapshot() {
    final segments = <SegmentHitRate>[];
    for (var n = 1; n <= 20; n++) {
      segments.add(SegmentHitRate(
        segmentLabel: '$n',
        attempts: _attempts[n] ?? 0,
        hits: _hits[n] ?? 0,
      ));
    }
    segments.add(SegmentHitRate(
      segmentLabel: 'Bull',
      attempts: _attempts[25] ?? 0,
      hits: _hits[25] ?? 0,
    ));
    return segments;
  }
}
