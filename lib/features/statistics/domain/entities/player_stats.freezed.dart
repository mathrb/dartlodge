// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerStats {

 String get playerId; GameType get gameType; int get totalGames; int get gamesWon; double get winRate; double get threeDartAverage; double? get checkoutPercentage; int? get highestCheckout; int get highestTurnScore; int get totalDartsThrown; double get dartsPerLeg; double get bustRate; int get legsPlayed; int get legsWon; double? get firstNinePpr; int get sixtyPlusTurns; int get oneHundredPlusTurns; int get oneFortyPlusTurns; int get oneEightyTurns; double? get bestLegPpr; double? get bestFirstNinePpr; double? get avgCheckoutScore; double? get bestGameCheckoutPercentage; double? get doubleOutSuccessRate; double? get firstDartInSuccessRate; double? get marksPerTurn; double? get hitRate; int get fiveMarkTurns; int get sixMarkTurns; int get sevenMarkTurns; int get eightMarkTurns; int get nineMarkTurns; double? get bestLegMpt; double? get bestGameHitRate; double? get firstNineMpr; int get atcCompletions; double? get atcHitRate; double? get atcAvgTurns; int? get atcBestTurns; Map<int, int> get atcSegmentHits; Map<int, int> get atcSegmentAttempts; double? get bobs27AvgScore; int? get bobs27BestScore; double? get bobs27CompletionRate; double? get bobs27DoubleHitRate; double? get shanghaiAvgScore; int? get shanghaiBestScore; int get shanghaiCount; double? get catch40AvgScore; int? get catch40BestScore; int get catch40TwoDartCheckouts; int get catch40ThreeDartCheckouts; int get catch40FourSixDartCheckouts; int get catch40FailedCheckouts; int get checkoutAttempts; int get checkoutSuccesses; double? get checkoutSuccessRate;
/// Create a copy of PlayerStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStatsCopyWith<PlayerStats> get copyWith => _$PlayerStatsCopyWithImpl<PlayerStats>(this as PlayerStats, _$identity);

  /// Serializes this PlayerStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerStats&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.totalGames, totalGames) || other.totalGames == totalGames)&&(identical(other.gamesWon, gamesWon) || other.gamesWon == gamesWon)&&(identical(other.winRate, winRate) || other.winRate == winRate)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.checkoutPercentage, checkoutPercentage) || other.checkoutPercentage == checkoutPercentage)&&(identical(other.highestCheckout, highestCheckout) || other.highestCheckout == highestCheckout)&&(identical(other.highestTurnScore, highestTurnScore) || other.highestTurnScore == highestTurnScore)&&(identical(other.totalDartsThrown, totalDartsThrown) || other.totalDartsThrown == totalDartsThrown)&&(identical(other.dartsPerLeg, dartsPerLeg) || other.dartsPerLeg == dartsPerLeg)&&(identical(other.bustRate, bustRate) || other.bustRate == bustRate)&&(identical(other.legsPlayed, legsPlayed) || other.legsPlayed == legsPlayed)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.firstNinePpr, firstNinePpr) || other.firstNinePpr == firstNinePpr)&&(identical(other.sixtyPlusTurns, sixtyPlusTurns) || other.sixtyPlusTurns == sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, oneHundredPlusTurns) || other.oneHundredPlusTurns == oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, oneFortyPlusTurns) || other.oneFortyPlusTurns == oneFortyPlusTurns)&&(identical(other.oneEightyTurns, oneEightyTurns) || other.oneEightyTurns == oneEightyTurns)&&(identical(other.bestLegPpr, bestLegPpr) || other.bestLegPpr == bestLegPpr)&&(identical(other.bestFirstNinePpr, bestFirstNinePpr) || other.bestFirstNinePpr == bestFirstNinePpr)&&(identical(other.avgCheckoutScore, avgCheckoutScore) || other.avgCheckoutScore == avgCheckoutScore)&&(identical(other.bestGameCheckoutPercentage, bestGameCheckoutPercentage) || other.bestGameCheckoutPercentage == bestGameCheckoutPercentage)&&(identical(other.doubleOutSuccessRate, doubleOutSuccessRate) || other.doubleOutSuccessRate == doubleOutSuccessRate)&&(identical(other.firstDartInSuccessRate, firstDartInSuccessRate) || other.firstDartInSuccessRate == firstDartInSuccessRate)&&(identical(other.marksPerTurn, marksPerTurn) || other.marksPerTurn == marksPerTurn)&&(identical(other.hitRate, hitRate) || other.hitRate == hitRate)&&(identical(other.fiveMarkTurns, fiveMarkTurns) || other.fiveMarkTurns == fiveMarkTurns)&&(identical(other.sixMarkTurns, sixMarkTurns) || other.sixMarkTurns == sixMarkTurns)&&(identical(other.sevenMarkTurns, sevenMarkTurns) || other.sevenMarkTurns == sevenMarkTurns)&&(identical(other.eightMarkTurns, eightMarkTurns) || other.eightMarkTurns == eightMarkTurns)&&(identical(other.nineMarkTurns, nineMarkTurns) || other.nineMarkTurns == nineMarkTurns)&&(identical(other.bestLegMpt, bestLegMpt) || other.bestLegMpt == bestLegMpt)&&(identical(other.bestGameHitRate, bestGameHitRate) || other.bestGameHitRate == bestGameHitRate)&&(identical(other.firstNineMpr, firstNineMpr) || other.firstNineMpr == firstNineMpr)&&(identical(other.atcCompletions, atcCompletions) || other.atcCompletions == atcCompletions)&&(identical(other.atcHitRate, atcHitRate) || other.atcHitRate == atcHitRate)&&(identical(other.atcAvgTurns, atcAvgTurns) || other.atcAvgTurns == atcAvgTurns)&&(identical(other.atcBestTurns, atcBestTurns) || other.atcBestTurns == atcBestTurns)&&const DeepCollectionEquality().equals(other.atcSegmentHits, atcSegmentHits)&&const DeepCollectionEquality().equals(other.atcSegmentAttempts, atcSegmentAttempts)&&(identical(other.bobs27AvgScore, bobs27AvgScore) || other.bobs27AvgScore == bobs27AvgScore)&&(identical(other.bobs27BestScore, bobs27BestScore) || other.bobs27BestScore == bobs27BestScore)&&(identical(other.bobs27CompletionRate, bobs27CompletionRate) || other.bobs27CompletionRate == bobs27CompletionRate)&&(identical(other.bobs27DoubleHitRate, bobs27DoubleHitRate) || other.bobs27DoubleHitRate == bobs27DoubleHitRate)&&(identical(other.shanghaiAvgScore, shanghaiAvgScore) || other.shanghaiAvgScore == shanghaiAvgScore)&&(identical(other.shanghaiBestScore, shanghaiBestScore) || other.shanghaiBestScore == shanghaiBestScore)&&(identical(other.shanghaiCount, shanghaiCount) || other.shanghaiCount == shanghaiCount)&&(identical(other.catch40AvgScore, catch40AvgScore) || other.catch40AvgScore == catch40AvgScore)&&(identical(other.catch40BestScore, catch40BestScore) || other.catch40BestScore == catch40BestScore)&&(identical(other.catch40TwoDartCheckouts, catch40TwoDartCheckouts) || other.catch40TwoDartCheckouts == catch40TwoDartCheckouts)&&(identical(other.catch40ThreeDartCheckouts, catch40ThreeDartCheckouts) || other.catch40ThreeDartCheckouts == catch40ThreeDartCheckouts)&&(identical(other.catch40FourSixDartCheckouts, catch40FourSixDartCheckouts) || other.catch40FourSixDartCheckouts == catch40FourSixDartCheckouts)&&(identical(other.catch40FailedCheckouts, catch40FailedCheckouts) || other.catch40FailedCheckouts == catch40FailedCheckouts)&&(identical(other.checkoutAttempts, checkoutAttempts) || other.checkoutAttempts == checkoutAttempts)&&(identical(other.checkoutSuccesses, checkoutSuccesses) || other.checkoutSuccesses == checkoutSuccesses)&&(identical(other.checkoutSuccessRate, checkoutSuccessRate) || other.checkoutSuccessRate == checkoutSuccessRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,playerId,gameType,totalGames,gamesWon,winRate,threeDartAverage,checkoutPercentage,highestCheckout,highestTurnScore,totalDartsThrown,dartsPerLeg,bustRate,legsPlayed,legsWon,firstNinePpr,sixtyPlusTurns,oneHundredPlusTurns,oneFortyPlusTurns,oneEightyTurns,bestLegPpr,bestFirstNinePpr,avgCheckoutScore,bestGameCheckoutPercentage,doubleOutSuccessRate,firstDartInSuccessRate,marksPerTurn,hitRate,fiveMarkTurns,sixMarkTurns,sevenMarkTurns,eightMarkTurns,nineMarkTurns,bestLegMpt,bestGameHitRate,firstNineMpr,atcCompletions,atcHitRate,atcAvgTurns,atcBestTurns,const DeepCollectionEquality().hash(atcSegmentHits),const DeepCollectionEquality().hash(atcSegmentAttempts),bobs27AvgScore,bobs27BestScore,bobs27CompletionRate,bobs27DoubleHitRate,shanghaiAvgScore,shanghaiBestScore,shanghaiCount,catch40AvgScore,catch40BestScore,catch40TwoDartCheckouts,catch40ThreeDartCheckouts,catch40FourSixDartCheckouts,catch40FailedCheckouts,checkoutAttempts,checkoutSuccesses,checkoutSuccessRate]);

@override
String toString() {
  return 'PlayerStats(playerId: $playerId, gameType: $gameType, totalGames: $totalGames, gamesWon: $gamesWon, winRate: $winRate, threeDartAverage: $threeDartAverage, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, highestTurnScore: $highestTurnScore, totalDartsThrown: $totalDartsThrown, dartsPerLeg: $dartsPerLeg, bustRate: $bustRate, legsPlayed: $legsPlayed, legsWon: $legsWon, firstNinePpr: $firstNinePpr, sixtyPlusTurns: $sixtyPlusTurns, oneHundredPlusTurns: $oneHundredPlusTurns, oneFortyPlusTurns: $oneFortyPlusTurns, oneEightyTurns: $oneEightyTurns, bestLegPpr: $bestLegPpr, bestFirstNinePpr: $bestFirstNinePpr, avgCheckoutScore: $avgCheckoutScore, bestGameCheckoutPercentage: $bestGameCheckoutPercentage, doubleOutSuccessRate: $doubleOutSuccessRate, firstDartInSuccessRate: $firstDartInSuccessRate, marksPerTurn: $marksPerTurn, hitRate: $hitRate, fiveMarkTurns: $fiveMarkTurns, sixMarkTurns: $sixMarkTurns, sevenMarkTurns: $sevenMarkTurns, eightMarkTurns: $eightMarkTurns, nineMarkTurns: $nineMarkTurns, bestLegMpt: $bestLegMpt, bestGameHitRate: $bestGameHitRate, firstNineMpr: $firstNineMpr, atcCompletions: $atcCompletions, atcHitRate: $atcHitRate, atcAvgTurns: $atcAvgTurns, atcBestTurns: $atcBestTurns, atcSegmentHits: $atcSegmentHits, atcSegmentAttempts: $atcSegmentAttempts, bobs27AvgScore: $bobs27AvgScore, bobs27BestScore: $bobs27BestScore, bobs27CompletionRate: $bobs27CompletionRate, bobs27DoubleHitRate: $bobs27DoubleHitRate, shanghaiAvgScore: $shanghaiAvgScore, shanghaiBestScore: $shanghaiBestScore, shanghaiCount: $shanghaiCount, catch40AvgScore: $catch40AvgScore, catch40BestScore: $catch40BestScore, catch40TwoDartCheckouts: $catch40TwoDartCheckouts, catch40ThreeDartCheckouts: $catch40ThreeDartCheckouts, catch40FourSixDartCheckouts: $catch40FourSixDartCheckouts, catch40FailedCheckouts: $catch40FailedCheckouts, checkoutAttempts: $checkoutAttempts, checkoutSuccesses: $checkoutSuccesses, checkoutSuccessRate: $checkoutSuccessRate)';
}


}

/// @nodoc
abstract mixin class $PlayerStatsCopyWith<$Res>  {
  factory $PlayerStatsCopyWith(PlayerStats value, $Res Function(PlayerStats) _then) = _$PlayerStatsCopyWithImpl;
@useResult
$Res call({
 String playerId, GameType gameType, int totalGames, int gamesWon, double winRate, double threeDartAverage, double? checkoutPercentage, int? highestCheckout, int highestTurnScore, int totalDartsThrown, double dartsPerLeg, double bustRate, int legsPlayed, int legsWon, double? firstNinePpr, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns, int oneEightyTurns, double? bestLegPpr, double? bestFirstNinePpr, double? avgCheckoutScore, double? bestGameCheckoutPercentage, double? doubleOutSuccessRate, double? firstDartInSuccessRate, double? marksPerTurn, double? hitRate, int fiveMarkTurns, int sixMarkTurns, int sevenMarkTurns, int eightMarkTurns, int nineMarkTurns, double? bestLegMpt, double? bestGameHitRate, double? firstNineMpr, int atcCompletions, double? atcHitRate, double? atcAvgTurns, int? atcBestTurns, Map<int, int> atcSegmentHits, Map<int, int> atcSegmentAttempts, double? bobs27AvgScore, int? bobs27BestScore, double? bobs27CompletionRate, double? bobs27DoubleHitRate, double? shanghaiAvgScore, int? shanghaiBestScore, int shanghaiCount, double? catch40AvgScore, int? catch40BestScore, int catch40TwoDartCheckouts, int catch40ThreeDartCheckouts, int catch40FourSixDartCheckouts, int catch40FailedCheckouts, int checkoutAttempts, int checkoutSuccesses, double? checkoutSuccessRate
});




}
/// @nodoc
class _$PlayerStatsCopyWithImpl<$Res>
    implements $PlayerStatsCopyWith<$Res> {
  _$PlayerStatsCopyWithImpl(this._self, this._then);

  final PlayerStats _self;
  final $Res Function(PlayerStats) _then;

/// Create a copy of PlayerStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? gameType = null,Object? totalGames = null,Object? gamesWon = null,Object? winRate = null,Object? threeDartAverage = null,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? highestTurnScore = null,Object? totalDartsThrown = null,Object? dartsPerLeg = null,Object? bustRate = null,Object? legsPlayed = null,Object? legsWon = null,Object? firstNinePpr = freezed,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,Object? oneEightyTurns = null,Object? bestLegPpr = freezed,Object? bestFirstNinePpr = freezed,Object? avgCheckoutScore = freezed,Object? bestGameCheckoutPercentage = freezed,Object? doubleOutSuccessRate = freezed,Object? firstDartInSuccessRate = freezed,Object? marksPerTurn = freezed,Object? hitRate = freezed,Object? fiveMarkTurns = null,Object? sixMarkTurns = null,Object? sevenMarkTurns = null,Object? eightMarkTurns = null,Object? nineMarkTurns = null,Object? bestLegMpt = freezed,Object? bestGameHitRate = freezed,Object? firstNineMpr = freezed,Object? atcCompletions = null,Object? atcHitRate = freezed,Object? atcAvgTurns = freezed,Object? atcBestTurns = freezed,Object? atcSegmentHits = null,Object? atcSegmentAttempts = null,Object? bobs27AvgScore = freezed,Object? bobs27BestScore = freezed,Object? bobs27CompletionRate = freezed,Object? bobs27DoubleHitRate = freezed,Object? shanghaiAvgScore = freezed,Object? shanghaiBestScore = freezed,Object? shanghaiCount = null,Object? catch40AvgScore = freezed,Object? catch40BestScore = freezed,Object? catch40TwoDartCheckouts = null,Object? catch40ThreeDartCheckouts = null,Object? catch40FourSixDartCheckouts = null,Object? catch40FailedCheckouts = null,Object? checkoutAttempts = null,Object? checkoutSuccesses = null,Object? checkoutSuccessRate = freezed,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,totalGames: null == totalGames ? _self.totalGames : totalGames // ignore: cast_nullable_to_non_nullable
as int,gamesWon: null == gamesWon ? _self.gamesWon : gamesWon // ignore: cast_nullable_to_non_nullable
as int,winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as double,threeDartAverage: null == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double,checkoutPercentage: freezed == checkoutPercentage ? _self.checkoutPercentage : checkoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,highestCheckout: freezed == highestCheckout ? _self.highestCheckout : highestCheckout // ignore: cast_nullable_to_non_nullable
as int?,highestTurnScore: null == highestTurnScore ? _self.highestTurnScore : highestTurnScore // ignore: cast_nullable_to_non_nullable
as int,totalDartsThrown: null == totalDartsThrown ? _self.totalDartsThrown : totalDartsThrown // ignore: cast_nullable_to_non_nullable
as int,dartsPerLeg: null == dartsPerLeg ? _self.dartsPerLeg : dartsPerLeg // ignore: cast_nullable_to_non_nullable
as double,bustRate: null == bustRate ? _self.bustRate : bustRate // ignore: cast_nullable_to_non_nullable
as double,legsPlayed: null == legsPlayed ? _self.legsPlayed : legsPlayed // ignore: cast_nullable_to_non_nullable
as int,legsWon: null == legsWon ? _self.legsWon : legsWon // ignore: cast_nullable_to_non_nullable
as int,firstNinePpr: freezed == firstNinePpr ? _self.firstNinePpr : firstNinePpr // ignore: cast_nullable_to_non_nullable
as double?,sixtyPlusTurns: null == sixtyPlusTurns ? _self.sixtyPlusTurns : sixtyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneHundredPlusTurns: null == oneHundredPlusTurns ? _self.oneHundredPlusTurns : oneHundredPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneFortyPlusTurns: null == oneFortyPlusTurns ? _self.oneFortyPlusTurns : oneFortyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneEightyTurns: null == oneEightyTurns ? _self.oneEightyTurns : oneEightyTurns // ignore: cast_nullable_to_non_nullable
as int,bestLegPpr: freezed == bestLegPpr ? _self.bestLegPpr : bestLegPpr // ignore: cast_nullable_to_non_nullable
as double?,bestFirstNinePpr: freezed == bestFirstNinePpr ? _self.bestFirstNinePpr : bestFirstNinePpr // ignore: cast_nullable_to_non_nullable
as double?,avgCheckoutScore: freezed == avgCheckoutScore ? _self.avgCheckoutScore : avgCheckoutScore // ignore: cast_nullable_to_non_nullable
as double?,bestGameCheckoutPercentage: freezed == bestGameCheckoutPercentage ? _self.bestGameCheckoutPercentage : bestGameCheckoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,doubleOutSuccessRate: freezed == doubleOutSuccessRate ? _self.doubleOutSuccessRate : doubleOutSuccessRate // ignore: cast_nullable_to_non_nullable
as double?,firstDartInSuccessRate: freezed == firstDartInSuccessRate ? _self.firstDartInSuccessRate : firstDartInSuccessRate // ignore: cast_nullable_to_non_nullable
as double?,marksPerTurn: freezed == marksPerTurn ? _self.marksPerTurn : marksPerTurn // ignore: cast_nullable_to_non_nullable
as double?,hitRate: freezed == hitRate ? _self.hitRate : hitRate // ignore: cast_nullable_to_non_nullable
as double?,fiveMarkTurns: null == fiveMarkTurns ? _self.fiveMarkTurns : fiveMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sixMarkTurns: null == sixMarkTurns ? _self.sixMarkTurns : sixMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sevenMarkTurns: null == sevenMarkTurns ? _self.sevenMarkTurns : sevenMarkTurns // ignore: cast_nullable_to_non_nullable
as int,eightMarkTurns: null == eightMarkTurns ? _self.eightMarkTurns : eightMarkTurns // ignore: cast_nullable_to_non_nullable
as int,nineMarkTurns: null == nineMarkTurns ? _self.nineMarkTurns : nineMarkTurns // ignore: cast_nullable_to_non_nullable
as int,bestLegMpt: freezed == bestLegMpt ? _self.bestLegMpt : bestLegMpt // ignore: cast_nullable_to_non_nullable
as double?,bestGameHitRate: freezed == bestGameHitRate ? _self.bestGameHitRate : bestGameHitRate // ignore: cast_nullable_to_non_nullable
as double?,firstNineMpr: freezed == firstNineMpr ? _self.firstNineMpr : firstNineMpr // ignore: cast_nullable_to_non_nullable
as double?,atcCompletions: null == atcCompletions ? _self.atcCompletions : atcCompletions // ignore: cast_nullable_to_non_nullable
as int,atcHitRate: freezed == atcHitRate ? _self.atcHitRate : atcHitRate // ignore: cast_nullable_to_non_nullable
as double?,atcAvgTurns: freezed == atcAvgTurns ? _self.atcAvgTurns : atcAvgTurns // ignore: cast_nullable_to_non_nullable
as double?,atcBestTurns: freezed == atcBestTurns ? _self.atcBestTurns : atcBestTurns // ignore: cast_nullable_to_non_nullable
as int?,atcSegmentHits: null == atcSegmentHits ? _self.atcSegmentHits : atcSegmentHits // ignore: cast_nullable_to_non_nullable
as Map<int, int>,atcSegmentAttempts: null == atcSegmentAttempts ? _self.atcSegmentAttempts : atcSegmentAttempts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,bobs27AvgScore: freezed == bobs27AvgScore ? _self.bobs27AvgScore : bobs27AvgScore // ignore: cast_nullable_to_non_nullable
as double?,bobs27BestScore: freezed == bobs27BestScore ? _self.bobs27BestScore : bobs27BestScore // ignore: cast_nullable_to_non_nullable
as int?,bobs27CompletionRate: freezed == bobs27CompletionRate ? _self.bobs27CompletionRate : bobs27CompletionRate // ignore: cast_nullable_to_non_nullable
as double?,bobs27DoubleHitRate: freezed == bobs27DoubleHitRate ? _self.bobs27DoubleHitRate : bobs27DoubleHitRate // ignore: cast_nullable_to_non_nullable
as double?,shanghaiAvgScore: freezed == shanghaiAvgScore ? _self.shanghaiAvgScore : shanghaiAvgScore // ignore: cast_nullable_to_non_nullable
as double?,shanghaiBestScore: freezed == shanghaiBestScore ? _self.shanghaiBestScore : shanghaiBestScore // ignore: cast_nullable_to_non_nullable
as int?,shanghaiCount: null == shanghaiCount ? _self.shanghaiCount : shanghaiCount // ignore: cast_nullable_to_non_nullable
as int,catch40AvgScore: freezed == catch40AvgScore ? _self.catch40AvgScore : catch40AvgScore // ignore: cast_nullable_to_non_nullable
as double?,catch40BestScore: freezed == catch40BestScore ? _self.catch40BestScore : catch40BestScore // ignore: cast_nullable_to_non_nullable
as int?,catch40TwoDartCheckouts: null == catch40TwoDartCheckouts ? _self.catch40TwoDartCheckouts : catch40TwoDartCheckouts // ignore: cast_nullable_to_non_nullable
as int,catch40ThreeDartCheckouts: null == catch40ThreeDartCheckouts ? _self.catch40ThreeDartCheckouts : catch40ThreeDartCheckouts // ignore: cast_nullable_to_non_nullable
as int,catch40FourSixDartCheckouts: null == catch40FourSixDartCheckouts ? _self.catch40FourSixDartCheckouts : catch40FourSixDartCheckouts // ignore: cast_nullable_to_non_nullable
as int,catch40FailedCheckouts: null == catch40FailedCheckouts ? _self.catch40FailedCheckouts : catch40FailedCheckouts // ignore: cast_nullable_to_non_nullable
as int,checkoutAttempts: null == checkoutAttempts ? _self.checkoutAttempts : checkoutAttempts // ignore: cast_nullable_to_non_nullable
as int,checkoutSuccesses: null == checkoutSuccesses ? _self.checkoutSuccesses : checkoutSuccesses // ignore: cast_nullable_to_non_nullable
as int,checkoutSuccessRate: freezed == checkoutSuccessRate ? _self.checkoutSuccessRate : checkoutSuccessRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerStats].
extension PlayerStatsPatterns on PlayerStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerStats value)  $default,){
final _that = this;
switch (_that) {
case _PlayerStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerStats value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  GameType gameType,  int totalGames,  int gamesWon,  double winRate,  double threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int highestTurnScore,  int totalDartsThrown,  double dartsPerLeg,  double bustRate,  int legsPlayed,  int legsWon,  double? firstNinePpr,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  int oneEightyTurns,  double? bestLegPpr,  double? bestFirstNinePpr,  double? avgCheckoutScore,  double? bestGameCheckoutPercentage,  double? doubleOutSuccessRate,  double? firstDartInSuccessRate,  double? marksPerTurn,  double? hitRate,  int fiveMarkTurns,  int sixMarkTurns,  int sevenMarkTurns,  int eightMarkTurns,  int nineMarkTurns,  double? bestLegMpt,  double? bestGameHitRate,  double? firstNineMpr,  int atcCompletions,  double? atcHitRate,  double? atcAvgTurns,  int? atcBestTurns,  Map<int, int> atcSegmentHits,  Map<int, int> atcSegmentAttempts,  double? bobs27AvgScore,  int? bobs27BestScore,  double? bobs27CompletionRate,  double? bobs27DoubleHitRate,  double? shanghaiAvgScore,  int? shanghaiBestScore,  int shanghaiCount,  double? catch40AvgScore,  int? catch40BestScore,  int catch40TwoDartCheckouts,  int catch40ThreeDartCheckouts,  int catch40FourSixDartCheckouts,  int catch40FailedCheckouts,  int checkoutAttempts,  int checkoutSuccesses,  double? checkoutSuccessRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerStats() when $default != null:
return $default(_that.playerId,_that.gameType,_that.totalGames,_that.gamesWon,_that.winRate,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.highestTurnScore,_that.totalDartsThrown,_that.dartsPerLeg,_that.bustRate,_that.legsPlayed,_that.legsWon,_that.firstNinePpr,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.oneEightyTurns,_that.bestLegPpr,_that.bestFirstNinePpr,_that.avgCheckoutScore,_that.bestGameCheckoutPercentage,_that.doubleOutSuccessRate,_that.firstDartInSuccessRate,_that.marksPerTurn,_that.hitRate,_that.fiveMarkTurns,_that.sixMarkTurns,_that.sevenMarkTurns,_that.eightMarkTurns,_that.nineMarkTurns,_that.bestLegMpt,_that.bestGameHitRate,_that.firstNineMpr,_that.atcCompletions,_that.atcHitRate,_that.atcAvgTurns,_that.atcBestTurns,_that.atcSegmentHits,_that.atcSegmentAttempts,_that.bobs27AvgScore,_that.bobs27BestScore,_that.bobs27CompletionRate,_that.bobs27DoubleHitRate,_that.shanghaiAvgScore,_that.shanghaiBestScore,_that.shanghaiCount,_that.catch40AvgScore,_that.catch40BestScore,_that.catch40TwoDartCheckouts,_that.catch40ThreeDartCheckouts,_that.catch40FourSixDartCheckouts,_that.catch40FailedCheckouts,_that.checkoutAttempts,_that.checkoutSuccesses,_that.checkoutSuccessRate);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  GameType gameType,  int totalGames,  int gamesWon,  double winRate,  double threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int highestTurnScore,  int totalDartsThrown,  double dartsPerLeg,  double bustRate,  int legsPlayed,  int legsWon,  double? firstNinePpr,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  int oneEightyTurns,  double? bestLegPpr,  double? bestFirstNinePpr,  double? avgCheckoutScore,  double? bestGameCheckoutPercentage,  double? doubleOutSuccessRate,  double? firstDartInSuccessRate,  double? marksPerTurn,  double? hitRate,  int fiveMarkTurns,  int sixMarkTurns,  int sevenMarkTurns,  int eightMarkTurns,  int nineMarkTurns,  double? bestLegMpt,  double? bestGameHitRate,  double? firstNineMpr,  int atcCompletions,  double? atcHitRate,  double? atcAvgTurns,  int? atcBestTurns,  Map<int, int> atcSegmentHits,  Map<int, int> atcSegmentAttempts,  double? bobs27AvgScore,  int? bobs27BestScore,  double? bobs27CompletionRate,  double? bobs27DoubleHitRate,  double? shanghaiAvgScore,  int? shanghaiBestScore,  int shanghaiCount,  double? catch40AvgScore,  int? catch40BestScore,  int catch40TwoDartCheckouts,  int catch40ThreeDartCheckouts,  int catch40FourSixDartCheckouts,  int catch40FailedCheckouts,  int checkoutAttempts,  int checkoutSuccesses,  double? checkoutSuccessRate)  $default,) {final _that = this;
switch (_that) {
case _PlayerStats():
return $default(_that.playerId,_that.gameType,_that.totalGames,_that.gamesWon,_that.winRate,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.highestTurnScore,_that.totalDartsThrown,_that.dartsPerLeg,_that.bustRate,_that.legsPlayed,_that.legsWon,_that.firstNinePpr,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.oneEightyTurns,_that.bestLegPpr,_that.bestFirstNinePpr,_that.avgCheckoutScore,_that.bestGameCheckoutPercentage,_that.doubleOutSuccessRate,_that.firstDartInSuccessRate,_that.marksPerTurn,_that.hitRate,_that.fiveMarkTurns,_that.sixMarkTurns,_that.sevenMarkTurns,_that.eightMarkTurns,_that.nineMarkTurns,_that.bestLegMpt,_that.bestGameHitRate,_that.firstNineMpr,_that.atcCompletions,_that.atcHitRate,_that.atcAvgTurns,_that.atcBestTurns,_that.atcSegmentHits,_that.atcSegmentAttempts,_that.bobs27AvgScore,_that.bobs27BestScore,_that.bobs27CompletionRate,_that.bobs27DoubleHitRate,_that.shanghaiAvgScore,_that.shanghaiBestScore,_that.shanghaiCount,_that.catch40AvgScore,_that.catch40BestScore,_that.catch40TwoDartCheckouts,_that.catch40ThreeDartCheckouts,_that.catch40FourSixDartCheckouts,_that.catch40FailedCheckouts,_that.checkoutAttempts,_that.checkoutSuccesses,_that.checkoutSuccessRate);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  GameType gameType,  int totalGames,  int gamesWon,  double winRate,  double threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int highestTurnScore,  int totalDartsThrown,  double dartsPerLeg,  double bustRate,  int legsPlayed,  int legsWon,  double? firstNinePpr,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  int oneEightyTurns,  double? bestLegPpr,  double? bestFirstNinePpr,  double? avgCheckoutScore,  double? bestGameCheckoutPercentage,  double? doubleOutSuccessRate,  double? firstDartInSuccessRate,  double? marksPerTurn,  double? hitRate,  int fiveMarkTurns,  int sixMarkTurns,  int sevenMarkTurns,  int eightMarkTurns,  int nineMarkTurns,  double? bestLegMpt,  double? bestGameHitRate,  double? firstNineMpr,  int atcCompletions,  double? atcHitRate,  double? atcAvgTurns,  int? atcBestTurns,  Map<int, int> atcSegmentHits,  Map<int, int> atcSegmentAttempts,  double? bobs27AvgScore,  int? bobs27BestScore,  double? bobs27CompletionRate,  double? bobs27DoubleHitRate,  double? shanghaiAvgScore,  int? shanghaiBestScore,  int shanghaiCount,  double? catch40AvgScore,  int? catch40BestScore,  int catch40TwoDartCheckouts,  int catch40ThreeDartCheckouts,  int catch40FourSixDartCheckouts,  int catch40FailedCheckouts,  int checkoutAttempts,  int checkoutSuccesses,  double? checkoutSuccessRate)?  $default,) {final _that = this;
switch (_that) {
case _PlayerStats() when $default != null:
return $default(_that.playerId,_that.gameType,_that.totalGames,_that.gamesWon,_that.winRate,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.highestTurnScore,_that.totalDartsThrown,_that.dartsPerLeg,_that.bustRate,_that.legsPlayed,_that.legsWon,_that.firstNinePpr,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.oneEightyTurns,_that.bestLegPpr,_that.bestFirstNinePpr,_that.avgCheckoutScore,_that.bestGameCheckoutPercentage,_that.doubleOutSuccessRate,_that.firstDartInSuccessRate,_that.marksPerTurn,_that.hitRate,_that.fiveMarkTurns,_that.sixMarkTurns,_that.sevenMarkTurns,_that.eightMarkTurns,_that.nineMarkTurns,_that.bestLegMpt,_that.bestGameHitRate,_that.firstNineMpr,_that.atcCompletions,_that.atcHitRate,_that.atcAvgTurns,_that.atcBestTurns,_that.atcSegmentHits,_that.atcSegmentAttempts,_that.bobs27AvgScore,_that.bobs27BestScore,_that.bobs27CompletionRate,_that.bobs27DoubleHitRate,_that.shanghaiAvgScore,_that.shanghaiBestScore,_that.shanghaiCount,_that.catch40AvgScore,_that.catch40BestScore,_that.catch40TwoDartCheckouts,_that.catch40ThreeDartCheckouts,_that.catch40FourSixDartCheckouts,_that.catch40FailedCheckouts,_that.checkoutAttempts,_that.checkoutSuccesses,_that.checkoutSuccessRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerStats implements PlayerStats {
  const _PlayerStats({required this.playerId, required this.gameType, required this.totalGames, required this.gamesWon, required this.winRate, required this.threeDartAverage, this.checkoutPercentage, this.highestCheckout, required this.highestTurnScore, required this.totalDartsThrown, required this.dartsPerLeg, required this.bustRate, this.legsPlayed = 0, this.legsWon = 0, this.firstNinePpr, this.sixtyPlusTurns = 0, this.oneHundredPlusTurns = 0, this.oneFortyPlusTurns = 0, this.oneEightyTurns = 0, this.bestLegPpr, this.bestFirstNinePpr, this.avgCheckoutScore, this.bestGameCheckoutPercentage, this.doubleOutSuccessRate, this.firstDartInSuccessRate, this.marksPerTurn, this.hitRate, this.fiveMarkTurns = 0, this.sixMarkTurns = 0, this.sevenMarkTurns = 0, this.eightMarkTurns = 0, this.nineMarkTurns = 0, this.bestLegMpt, this.bestGameHitRate, this.firstNineMpr, this.atcCompletions = 0, this.atcHitRate, this.atcAvgTurns, this.atcBestTurns, final  Map<int, int> atcSegmentHits = const <int, int>{}, final  Map<int, int> atcSegmentAttempts = const <int, int>{}, this.bobs27AvgScore, this.bobs27BestScore, this.bobs27CompletionRate, this.bobs27DoubleHitRate, this.shanghaiAvgScore, this.shanghaiBestScore, this.shanghaiCount = 0, this.catch40AvgScore, this.catch40BestScore, this.catch40TwoDartCheckouts = 0, this.catch40ThreeDartCheckouts = 0, this.catch40FourSixDartCheckouts = 0, this.catch40FailedCheckouts = 0, this.checkoutAttempts = 0, this.checkoutSuccesses = 0, this.checkoutSuccessRate}): _atcSegmentHits = atcSegmentHits,_atcSegmentAttempts = atcSegmentAttempts;
  factory _PlayerStats.fromJson(Map<String, dynamic> json) => _$PlayerStatsFromJson(json);

@override final  String playerId;
@override final  GameType gameType;
@override final  int totalGames;
@override final  int gamesWon;
@override final  double winRate;
@override final  double threeDartAverage;
@override final  double? checkoutPercentage;
@override final  int? highestCheckout;
@override final  int highestTurnScore;
@override final  int totalDartsThrown;
@override final  double dartsPerLeg;
@override final  double bustRate;
@override@JsonKey() final  int legsPlayed;
@override@JsonKey() final  int legsWon;
@override final  double? firstNinePpr;
@override@JsonKey() final  int sixtyPlusTurns;
@override@JsonKey() final  int oneHundredPlusTurns;
@override@JsonKey() final  int oneFortyPlusTurns;
@override@JsonKey() final  int oneEightyTurns;
@override final  double? bestLegPpr;
@override final  double? bestFirstNinePpr;
@override final  double? avgCheckoutScore;
@override final  double? bestGameCheckoutPercentage;
@override final  double? doubleOutSuccessRate;
@override final  double? firstDartInSuccessRate;
@override final  double? marksPerTurn;
@override final  double? hitRate;
@override@JsonKey() final  int fiveMarkTurns;
@override@JsonKey() final  int sixMarkTurns;
@override@JsonKey() final  int sevenMarkTurns;
@override@JsonKey() final  int eightMarkTurns;
@override@JsonKey() final  int nineMarkTurns;
@override final  double? bestLegMpt;
@override final  double? bestGameHitRate;
@override final  double? firstNineMpr;
@override@JsonKey() final  int atcCompletions;
@override final  double? atcHitRate;
@override final  double? atcAvgTurns;
@override final  int? atcBestTurns;
 final  Map<int, int> _atcSegmentHits;
@override@JsonKey() Map<int, int> get atcSegmentHits {
  if (_atcSegmentHits is EqualUnmodifiableMapView) return _atcSegmentHits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_atcSegmentHits);
}

 final  Map<int, int> _atcSegmentAttempts;
@override@JsonKey() Map<int, int> get atcSegmentAttempts {
  if (_atcSegmentAttempts is EqualUnmodifiableMapView) return _atcSegmentAttempts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_atcSegmentAttempts);
}

@override final  double? bobs27AvgScore;
@override final  int? bobs27BestScore;
@override final  double? bobs27CompletionRate;
@override final  double? bobs27DoubleHitRate;
@override final  double? shanghaiAvgScore;
@override final  int? shanghaiBestScore;
@override@JsonKey() final  int shanghaiCount;
@override final  double? catch40AvgScore;
@override final  int? catch40BestScore;
@override@JsonKey() final  int catch40TwoDartCheckouts;
@override@JsonKey() final  int catch40ThreeDartCheckouts;
@override@JsonKey() final  int catch40FourSixDartCheckouts;
@override@JsonKey() final  int catch40FailedCheckouts;
@override@JsonKey() final  int checkoutAttempts;
@override@JsonKey() final  int checkoutSuccesses;
@override final  double? checkoutSuccessRate;

/// Create a copy of PlayerStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStatsCopyWith<_PlayerStats> get copyWith => __$PlayerStatsCopyWithImpl<_PlayerStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerStats&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.totalGames, totalGames) || other.totalGames == totalGames)&&(identical(other.gamesWon, gamesWon) || other.gamesWon == gamesWon)&&(identical(other.winRate, winRate) || other.winRate == winRate)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.checkoutPercentage, checkoutPercentage) || other.checkoutPercentage == checkoutPercentage)&&(identical(other.highestCheckout, highestCheckout) || other.highestCheckout == highestCheckout)&&(identical(other.highestTurnScore, highestTurnScore) || other.highestTurnScore == highestTurnScore)&&(identical(other.totalDartsThrown, totalDartsThrown) || other.totalDartsThrown == totalDartsThrown)&&(identical(other.dartsPerLeg, dartsPerLeg) || other.dartsPerLeg == dartsPerLeg)&&(identical(other.bustRate, bustRate) || other.bustRate == bustRate)&&(identical(other.legsPlayed, legsPlayed) || other.legsPlayed == legsPlayed)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.firstNinePpr, firstNinePpr) || other.firstNinePpr == firstNinePpr)&&(identical(other.sixtyPlusTurns, sixtyPlusTurns) || other.sixtyPlusTurns == sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, oneHundredPlusTurns) || other.oneHundredPlusTurns == oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, oneFortyPlusTurns) || other.oneFortyPlusTurns == oneFortyPlusTurns)&&(identical(other.oneEightyTurns, oneEightyTurns) || other.oneEightyTurns == oneEightyTurns)&&(identical(other.bestLegPpr, bestLegPpr) || other.bestLegPpr == bestLegPpr)&&(identical(other.bestFirstNinePpr, bestFirstNinePpr) || other.bestFirstNinePpr == bestFirstNinePpr)&&(identical(other.avgCheckoutScore, avgCheckoutScore) || other.avgCheckoutScore == avgCheckoutScore)&&(identical(other.bestGameCheckoutPercentage, bestGameCheckoutPercentage) || other.bestGameCheckoutPercentage == bestGameCheckoutPercentage)&&(identical(other.doubleOutSuccessRate, doubleOutSuccessRate) || other.doubleOutSuccessRate == doubleOutSuccessRate)&&(identical(other.firstDartInSuccessRate, firstDartInSuccessRate) || other.firstDartInSuccessRate == firstDartInSuccessRate)&&(identical(other.marksPerTurn, marksPerTurn) || other.marksPerTurn == marksPerTurn)&&(identical(other.hitRate, hitRate) || other.hitRate == hitRate)&&(identical(other.fiveMarkTurns, fiveMarkTurns) || other.fiveMarkTurns == fiveMarkTurns)&&(identical(other.sixMarkTurns, sixMarkTurns) || other.sixMarkTurns == sixMarkTurns)&&(identical(other.sevenMarkTurns, sevenMarkTurns) || other.sevenMarkTurns == sevenMarkTurns)&&(identical(other.eightMarkTurns, eightMarkTurns) || other.eightMarkTurns == eightMarkTurns)&&(identical(other.nineMarkTurns, nineMarkTurns) || other.nineMarkTurns == nineMarkTurns)&&(identical(other.bestLegMpt, bestLegMpt) || other.bestLegMpt == bestLegMpt)&&(identical(other.bestGameHitRate, bestGameHitRate) || other.bestGameHitRate == bestGameHitRate)&&(identical(other.firstNineMpr, firstNineMpr) || other.firstNineMpr == firstNineMpr)&&(identical(other.atcCompletions, atcCompletions) || other.atcCompletions == atcCompletions)&&(identical(other.atcHitRate, atcHitRate) || other.atcHitRate == atcHitRate)&&(identical(other.atcAvgTurns, atcAvgTurns) || other.atcAvgTurns == atcAvgTurns)&&(identical(other.atcBestTurns, atcBestTurns) || other.atcBestTurns == atcBestTurns)&&const DeepCollectionEquality().equals(other._atcSegmentHits, _atcSegmentHits)&&const DeepCollectionEquality().equals(other._atcSegmentAttempts, _atcSegmentAttempts)&&(identical(other.bobs27AvgScore, bobs27AvgScore) || other.bobs27AvgScore == bobs27AvgScore)&&(identical(other.bobs27BestScore, bobs27BestScore) || other.bobs27BestScore == bobs27BestScore)&&(identical(other.bobs27CompletionRate, bobs27CompletionRate) || other.bobs27CompletionRate == bobs27CompletionRate)&&(identical(other.bobs27DoubleHitRate, bobs27DoubleHitRate) || other.bobs27DoubleHitRate == bobs27DoubleHitRate)&&(identical(other.shanghaiAvgScore, shanghaiAvgScore) || other.shanghaiAvgScore == shanghaiAvgScore)&&(identical(other.shanghaiBestScore, shanghaiBestScore) || other.shanghaiBestScore == shanghaiBestScore)&&(identical(other.shanghaiCount, shanghaiCount) || other.shanghaiCount == shanghaiCount)&&(identical(other.catch40AvgScore, catch40AvgScore) || other.catch40AvgScore == catch40AvgScore)&&(identical(other.catch40BestScore, catch40BestScore) || other.catch40BestScore == catch40BestScore)&&(identical(other.catch40TwoDartCheckouts, catch40TwoDartCheckouts) || other.catch40TwoDartCheckouts == catch40TwoDartCheckouts)&&(identical(other.catch40ThreeDartCheckouts, catch40ThreeDartCheckouts) || other.catch40ThreeDartCheckouts == catch40ThreeDartCheckouts)&&(identical(other.catch40FourSixDartCheckouts, catch40FourSixDartCheckouts) || other.catch40FourSixDartCheckouts == catch40FourSixDartCheckouts)&&(identical(other.catch40FailedCheckouts, catch40FailedCheckouts) || other.catch40FailedCheckouts == catch40FailedCheckouts)&&(identical(other.checkoutAttempts, checkoutAttempts) || other.checkoutAttempts == checkoutAttempts)&&(identical(other.checkoutSuccesses, checkoutSuccesses) || other.checkoutSuccesses == checkoutSuccesses)&&(identical(other.checkoutSuccessRate, checkoutSuccessRate) || other.checkoutSuccessRate == checkoutSuccessRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,playerId,gameType,totalGames,gamesWon,winRate,threeDartAverage,checkoutPercentage,highestCheckout,highestTurnScore,totalDartsThrown,dartsPerLeg,bustRate,legsPlayed,legsWon,firstNinePpr,sixtyPlusTurns,oneHundredPlusTurns,oneFortyPlusTurns,oneEightyTurns,bestLegPpr,bestFirstNinePpr,avgCheckoutScore,bestGameCheckoutPercentage,doubleOutSuccessRate,firstDartInSuccessRate,marksPerTurn,hitRate,fiveMarkTurns,sixMarkTurns,sevenMarkTurns,eightMarkTurns,nineMarkTurns,bestLegMpt,bestGameHitRate,firstNineMpr,atcCompletions,atcHitRate,atcAvgTurns,atcBestTurns,const DeepCollectionEquality().hash(_atcSegmentHits),const DeepCollectionEquality().hash(_atcSegmentAttempts),bobs27AvgScore,bobs27BestScore,bobs27CompletionRate,bobs27DoubleHitRate,shanghaiAvgScore,shanghaiBestScore,shanghaiCount,catch40AvgScore,catch40BestScore,catch40TwoDartCheckouts,catch40ThreeDartCheckouts,catch40FourSixDartCheckouts,catch40FailedCheckouts,checkoutAttempts,checkoutSuccesses,checkoutSuccessRate]);

@override
String toString() {
  return 'PlayerStats(playerId: $playerId, gameType: $gameType, totalGames: $totalGames, gamesWon: $gamesWon, winRate: $winRate, threeDartAverage: $threeDartAverage, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, highestTurnScore: $highestTurnScore, totalDartsThrown: $totalDartsThrown, dartsPerLeg: $dartsPerLeg, bustRate: $bustRate, legsPlayed: $legsPlayed, legsWon: $legsWon, firstNinePpr: $firstNinePpr, sixtyPlusTurns: $sixtyPlusTurns, oneHundredPlusTurns: $oneHundredPlusTurns, oneFortyPlusTurns: $oneFortyPlusTurns, oneEightyTurns: $oneEightyTurns, bestLegPpr: $bestLegPpr, bestFirstNinePpr: $bestFirstNinePpr, avgCheckoutScore: $avgCheckoutScore, bestGameCheckoutPercentage: $bestGameCheckoutPercentage, doubleOutSuccessRate: $doubleOutSuccessRate, firstDartInSuccessRate: $firstDartInSuccessRate, marksPerTurn: $marksPerTurn, hitRate: $hitRate, fiveMarkTurns: $fiveMarkTurns, sixMarkTurns: $sixMarkTurns, sevenMarkTurns: $sevenMarkTurns, eightMarkTurns: $eightMarkTurns, nineMarkTurns: $nineMarkTurns, bestLegMpt: $bestLegMpt, bestGameHitRate: $bestGameHitRate, firstNineMpr: $firstNineMpr, atcCompletions: $atcCompletions, atcHitRate: $atcHitRate, atcAvgTurns: $atcAvgTurns, atcBestTurns: $atcBestTurns, atcSegmentHits: $atcSegmentHits, atcSegmentAttempts: $atcSegmentAttempts, bobs27AvgScore: $bobs27AvgScore, bobs27BestScore: $bobs27BestScore, bobs27CompletionRate: $bobs27CompletionRate, bobs27DoubleHitRate: $bobs27DoubleHitRate, shanghaiAvgScore: $shanghaiAvgScore, shanghaiBestScore: $shanghaiBestScore, shanghaiCount: $shanghaiCount, catch40AvgScore: $catch40AvgScore, catch40BestScore: $catch40BestScore, catch40TwoDartCheckouts: $catch40TwoDartCheckouts, catch40ThreeDartCheckouts: $catch40ThreeDartCheckouts, catch40FourSixDartCheckouts: $catch40FourSixDartCheckouts, catch40FailedCheckouts: $catch40FailedCheckouts, checkoutAttempts: $checkoutAttempts, checkoutSuccesses: $checkoutSuccesses, checkoutSuccessRate: $checkoutSuccessRate)';
}


}

/// @nodoc
abstract mixin class _$PlayerStatsCopyWith<$Res> implements $PlayerStatsCopyWith<$Res> {
  factory _$PlayerStatsCopyWith(_PlayerStats value, $Res Function(_PlayerStats) _then) = __$PlayerStatsCopyWithImpl;
@override @useResult
$Res call({
 String playerId, GameType gameType, int totalGames, int gamesWon, double winRate, double threeDartAverage, double? checkoutPercentage, int? highestCheckout, int highestTurnScore, int totalDartsThrown, double dartsPerLeg, double bustRate, int legsPlayed, int legsWon, double? firstNinePpr, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns, int oneEightyTurns, double? bestLegPpr, double? bestFirstNinePpr, double? avgCheckoutScore, double? bestGameCheckoutPercentage, double? doubleOutSuccessRate, double? firstDartInSuccessRate, double? marksPerTurn, double? hitRate, int fiveMarkTurns, int sixMarkTurns, int sevenMarkTurns, int eightMarkTurns, int nineMarkTurns, double? bestLegMpt, double? bestGameHitRate, double? firstNineMpr, int atcCompletions, double? atcHitRate, double? atcAvgTurns, int? atcBestTurns, Map<int, int> atcSegmentHits, Map<int, int> atcSegmentAttempts, double? bobs27AvgScore, int? bobs27BestScore, double? bobs27CompletionRate, double? bobs27DoubleHitRate, double? shanghaiAvgScore, int? shanghaiBestScore, int shanghaiCount, double? catch40AvgScore, int? catch40BestScore, int catch40TwoDartCheckouts, int catch40ThreeDartCheckouts, int catch40FourSixDartCheckouts, int catch40FailedCheckouts, int checkoutAttempts, int checkoutSuccesses, double? checkoutSuccessRate
});




}
/// @nodoc
class __$PlayerStatsCopyWithImpl<$Res>
    implements _$PlayerStatsCopyWith<$Res> {
  __$PlayerStatsCopyWithImpl(this._self, this._then);

  final _PlayerStats _self;
  final $Res Function(_PlayerStats) _then;

/// Create a copy of PlayerStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? gameType = null,Object? totalGames = null,Object? gamesWon = null,Object? winRate = null,Object? threeDartAverage = null,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? highestTurnScore = null,Object? totalDartsThrown = null,Object? dartsPerLeg = null,Object? bustRate = null,Object? legsPlayed = null,Object? legsWon = null,Object? firstNinePpr = freezed,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,Object? oneEightyTurns = null,Object? bestLegPpr = freezed,Object? bestFirstNinePpr = freezed,Object? avgCheckoutScore = freezed,Object? bestGameCheckoutPercentage = freezed,Object? doubleOutSuccessRate = freezed,Object? firstDartInSuccessRate = freezed,Object? marksPerTurn = freezed,Object? hitRate = freezed,Object? fiveMarkTurns = null,Object? sixMarkTurns = null,Object? sevenMarkTurns = null,Object? eightMarkTurns = null,Object? nineMarkTurns = null,Object? bestLegMpt = freezed,Object? bestGameHitRate = freezed,Object? firstNineMpr = freezed,Object? atcCompletions = null,Object? atcHitRate = freezed,Object? atcAvgTurns = freezed,Object? atcBestTurns = freezed,Object? atcSegmentHits = null,Object? atcSegmentAttempts = null,Object? bobs27AvgScore = freezed,Object? bobs27BestScore = freezed,Object? bobs27CompletionRate = freezed,Object? bobs27DoubleHitRate = freezed,Object? shanghaiAvgScore = freezed,Object? shanghaiBestScore = freezed,Object? shanghaiCount = null,Object? catch40AvgScore = freezed,Object? catch40BestScore = freezed,Object? catch40TwoDartCheckouts = null,Object? catch40ThreeDartCheckouts = null,Object? catch40FourSixDartCheckouts = null,Object? catch40FailedCheckouts = null,Object? checkoutAttempts = null,Object? checkoutSuccesses = null,Object? checkoutSuccessRate = freezed,}) {
  return _then(_PlayerStats(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,totalGames: null == totalGames ? _self.totalGames : totalGames // ignore: cast_nullable_to_non_nullable
as int,gamesWon: null == gamesWon ? _self.gamesWon : gamesWon // ignore: cast_nullable_to_non_nullable
as int,winRate: null == winRate ? _self.winRate : winRate // ignore: cast_nullable_to_non_nullable
as double,threeDartAverage: null == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double,checkoutPercentage: freezed == checkoutPercentage ? _self.checkoutPercentage : checkoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,highestCheckout: freezed == highestCheckout ? _self.highestCheckout : highestCheckout // ignore: cast_nullable_to_non_nullable
as int?,highestTurnScore: null == highestTurnScore ? _self.highestTurnScore : highestTurnScore // ignore: cast_nullable_to_non_nullable
as int,totalDartsThrown: null == totalDartsThrown ? _self.totalDartsThrown : totalDartsThrown // ignore: cast_nullable_to_non_nullable
as int,dartsPerLeg: null == dartsPerLeg ? _self.dartsPerLeg : dartsPerLeg // ignore: cast_nullable_to_non_nullable
as double,bustRate: null == bustRate ? _self.bustRate : bustRate // ignore: cast_nullable_to_non_nullable
as double,legsPlayed: null == legsPlayed ? _self.legsPlayed : legsPlayed // ignore: cast_nullable_to_non_nullable
as int,legsWon: null == legsWon ? _self.legsWon : legsWon // ignore: cast_nullable_to_non_nullable
as int,firstNinePpr: freezed == firstNinePpr ? _self.firstNinePpr : firstNinePpr // ignore: cast_nullable_to_non_nullable
as double?,sixtyPlusTurns: null == sixtyPlusTurns ? _self.sixtyPlusTurns : sixtyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneHundredPlusTurns: null == oneHundredPlusTurns ? _self.oneHundredPlusTurns : oneHundredPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneFortyPlusTurns: null == oneFortyPlusTurns ? _self.oneFortyPlusTurns : oneFortyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneEightyTurns: null == oneEightyTurns ? _self.oneEightyTurns : oneEightyTurns // ignore: cast_nullable_to_non_nullable
as int,bestLegPpr: freezed == bestLegPpr ? _self.bestLegPpr : bestLegPpr // ignore: cast_nullable_to_non_nullable
as double?,bestFirstNinePpr: freezed == bestFirstNinePpr ? _self.bestFirstNinePpr : bestFirstNinePpr // ignore: cast_nullable_to_non_nullable
as double?,avgCheckoutScore: freezed == avgCheckoutScore ? _self.avgCheckoutScore : avgCheckoutScore // ignore: cast_nullable_to_non_nullable
as double?,bestGameCheckoutPercentage: freezed == bestGameCheckoutPercentage ? _self.bestGameCheckoutPercentage : bestGameCheckoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,doubleOutSuccessRate: freezed == doubleOutSuccessRate ? _self.doubleOutSuccessRate : doubleOutSuccessRate // ignore: cast_nullable_to_non_nullable
as double?,firstDartInSuccessRate: freezed == firstDartInSuccessRate ? _self.firstDartInSuccessRate : firstDartInSuccessRate // ignore: cast_nullable_to_non_nullable
as double?,marksPerTurn: freezed == marksPerTurn ? _self.marksPerTurn : marksPerTurn // ignore: cast_nullable_to_non_nullable
as double?,hitRate: freezed == hitRate ? _self.hitRate : hitRate // ignore: cast_nullable_to_non_nullable
as double?,fiveMarkTurns: null == fiveMarkTurns ? _self.fiveMarkTurns : fiveMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sixMarkTurns: null == sixMarkTurns ? _self.sixMarkTurns : sixMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sevenMarkTurns: null == sevenMarkTurns ? _self.sevenMarkTurns : sevenMarkTurns // ignore: cast_nullable_to_non_nullable
as int,eightMarkTurns: null == eightMarkTurns ? _self.eightMarkTurns : eightMarkTurns // ignore: cast_nullable_to_non_nullable
as int,nineMarkTurns: null == nineMarkTurns ? _self.nineMarkTurns : nineMarkTurns // ignore: cast_nullable_to_non_nullable
as int,bestLegMpt: freezed == bestLegMpt ? _self.bestLegMpt : bestLegMpt // ignore: cast_nullable_to_non_nullable
as double?,bestGameHitRate: freezed == bestGameHitRate ? _self.bestGameHitRate : bestGameHitRate // ignore: cast_nullable_to_non_nullable
as double?,firstNineMpr: freezed == firstNineMpr ? _self.firstNineMpr : firstNineMpr // ignore: cast_nullable_to_non_nullable
as double?,atcCompletions: null == atcCompletions ? _self.atcCompletions : atcCompletions // ignore: cast_nullable_to_non_nullable
as int,atcHitRate: freezed == atcHitRate ? _self.atcHitRate : atcHitRate // ignore: cast_nullable_to_non_nullable
as double?,atcAvgTurns: freezed == atcAvgTurns ? _self.atcAvgTurns : atcAvgTurns // ignore: cast_nullable_to_non_nullable
as double?,atcBestTurns: freezed == atcBestTurns ? _self.atcBestTurns : atcBestTurns // ignore: cast_nullable_to_non_nullable
as int?,atcSegmentHits: null == atcSegmentHits ? _self._atcSegmentHits : atcSegmentHits // ignore: cast_nullable_to_non_nullable
as Map<int, int>,atcSegmentAttempts: null == atcSegmentAttempts ? _self._atcSegmentAttempts : atcSegmentAttempts // ignore: cast_nullable_to_non_nullable
as Map<int, int>,bobs27AvgScore: freezed == bobs27AvgScore ? _self.bobs27AvgScore : bobs27AvgScore // ignore: cast_nullable_to_non_nullable
as double?,bobs27BestScore: freezed == bobs27BestScore ? _self.bobs27BestScore : bobs27BestScore // ignore: cast_nullable_to_non_nullable
as int?,bobs27CompletionRate: freezed == bobs27CompletionRate ? _self.bobs27CompletionRate : bobs27CompletionRate // ignore: cast_nullable_to_non_nullable
as double?,bobs27DoubleHitRate: freezed == bobs27DoubleHitRate ? _self.bobs27DoubleHitRate : bobs27DoubleHitRate // ignore: cast_nullable_to_non_nullable
as double?,shanghaiAvgScore: freezed == shanghaiAvgScore ? _self.shanghaiAvgScore : shanghaiAvgScore // ignore: cast_nullable_to_non_nullable
as double?,shanghaiBestScore: freezed == shanghaiBestScore ? _self.shanghaiBestScore : shanghaiBestScore // ignore: cast_nullable_to_non_nullable
as int?,shanghaiCount: null == shanghaiCount ? _self.shanghaiCount : shanghaiCount // ignore: cast_nullable_to_non_nullable
as int,catch40AvgScore: freezed == catch40AvgScore ? _self.catch40AvgScore : catch40AvgScore // ignore: cast_nullable_to_non_nullable
as double?,catch40BestScore: freezed == catch40BestScore ? _self.catch40BestScore : catch40BestScore // ignore: cast_nullable_to_non_nullable
as int?,catch40TwoDartCheckouts: null == catch40TwoDartCheckouts ? _self.catch40TwoDartCheckouts : catch40TwoDartCheckouts // ignore: cast_nullable_to_non_nullable
as int,catch40ThreeDartCheckouts: null == catch40ThreeDartCheckouts ? _self.catch40ThreeDartCheckouts : catch40ThreeDartCheckouts // ignore: cast_nullable_to_non_nullable
as int,catch40FourSixDartCheckouts: null == catch40FourSixDartCheckouts ? _self.catch40FourSixDartCheckouts : catch40FourSixDartCheckouts // ignore: cast_nullable_to_non_nullable
as int,catch40FailedCheckouts: null == catch40FailedCheckouts ? _self.catch40FailedCheckouts : catch40FailedCheckouts // ignore: cast_nullable_to_non_nullable
as int,checkoutAttempts: null == checkoutAttempts ? _self.checkoutAttempts : checkoutAttempts // ignore: cast_nullable_to_non_nullable
as int,checkoutSuccesses: null == checkoutSuccesses ? _self.checkoutSuccesses : checkoutSuccesses // ignore: cast_nullable_to_non_nullable
as int,checkoutSuccessRate: freezed == checkoutSuccessRate ? _self.checkoutSuccessRate : checkoutSuccessRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
