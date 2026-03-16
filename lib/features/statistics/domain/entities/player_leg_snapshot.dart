import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_leg_snapshot.freezed.dart';

@freezed
abstract class PlayerLegSnapshot with _$PlayerLegSnapshot {
  const factory PlayerLegSnapshot({
    required String gameId,
    required int legIndex,
    required DateTime gameDate,
    required double ppr,
    double? checkoutPct,
    int? startingScore,
  }) = _PlayerLegSnapshot;
}
