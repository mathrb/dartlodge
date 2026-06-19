import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:dart_lodge/core/persistence/database_provider.dart';
import 'package:dart_lodge/core/utils/constants.dart';
import 'package:dart_lodge/features/statistics/domain/entities/dart_position.dart';

part 'dart_heatmap_provider.freezed.dart';
part 'dart_heatmap_provider.g.dart';

// ── Dart heatmap data provider (#576) ─────────────────────────────────────────
//
// Feeds the impact heatmap (SI-4 widget) with raw recorded dart positions for a
// player, optionally scoped to a single game (post-game heatmap) or filtered by
// game type + date window (stats tabs). Positions are facts read straight from
// `dart_throws` — never routed through `PlayerStatsAssembler`.

/// Filter key for [dartHeatmapProvider]. A `@freezed` value class so the
/// provider family memoises on structural equality of the filter.
@freezed
abstract class DartHeatmapFilter with _$DartHeatmapFilter {
  const factory DartHeatmapFilter({
    required String playerId,
    String? gameId,
    GameType? gameType,
    DateTime? from,
    DateTime? to,
  }) = _DartHeatmapFilter;
}

@riverpod
Future<List<DartPosition>> dartHeatmap(Ref ref, DartHeatmapFilter filter) =>
    ref.watch(statisticsRepositoryProvider).getDartPositions(
          playerId: filter.playerId,
          gameId: filter.gameId,
          gameType: filter.gameType,
          from: filter.from,
          to: filter.to,
        );
