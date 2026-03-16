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

 String get playerId; GameType get gameType; int get totalGames; int get gamesWon; double get winRate; double get threeDartAverage; double? get checkoutPercentage;// null for non-X01 games
 int? get highestCheckout; int get highestTurnScore; int get totalDartsThrown; double get dartsPerLeg; double get bustRate;// 0.0–1.0
 int get legsPlayed; int get legsWon; double? get firstNinePpr; int get sixtyPlusTurns; int get oneHundredPlusTurns; int get oneFortyPlusTurns; int get oneEightyTurns;
/// Create a copy of PlayerStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStatsCopyWith<PlayerStats> get copyWith => _$PlayerStatsCopyWithImpl<PlayerStats>(this as PlayerStats, _$identity);

  /// Serializes this PlayerStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerStats&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.totalGames, totalGames) || other.totalGames == totalGames)&&(identical(other.gamesWon, gamesWon) || other.gamesWon == gamesWon)&&(identical(other.winRate, winRate) || other.winRate == winRate)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.checkoutPercentage, checkoutPercentage) || other.checkoutPercentage == checkoutPercentage)&&(identical(other.highestCheckout, highestCheckout) || other.highestCheckout == highestCheckout)&&(identical(other.highestTurnScore, highestTurnScore) || other.highestTurnScore == highestTurnScore)&&(identical(other.totalDartsThrown, totalDartsThrown) || other.totalDartsThrown == totalDartsThrown)&&(identical(other.dartsPerLeg, dartsPerLeg) || other.dartsPerLeg == dartsPerLeg)&&(identical(other.bustRate, bustRate) || other.bustRate == bustRate)&&(identical(other.legsPlayed, legsPlayed) || other.legsPlayed == legsPlayed)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.firstNinePpr, firstNinePpr) || other.firstNinePpr == firstNinePpr)&&(identical(other.sixtyPlusTurns, sixtyPlusTurns) || other.sixtyPlusTurns == sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, oneHundredPlusTurns) || other.oneHundredPlusTurns == oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, oneFortyPlusTurns) || other.oneFortyPlusTurns == oneFortyPlusTurns)&&(identical(other.oneEightyTurns, oneEightyTurns) || other.oneEightyTurns == oneEightyTurns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,playerId,gameType,totalGames,gamesWon,winRate,threeDartAverage,checkoutPercentage,highestCheckout,highestTurnScore,totalDartsThrown,dartsPerLeg,bustRate,legsPlayed,legsWon,firstNinePpr,sixtyPlusTurns,oneHundredPlusTurns,oneFortyPlusTurns,oneEightyTurns]);

@override
String toString() {
  return 'PlayerStats(playerId: $playerId, gameType: $gameType, totalGames: $totalGames, gamesWon: $gamesWon, winRate: $winRate, threeDartAverage: $threeDartAverage, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, highestTurnScore: $highestTurnScore, totalDartsThrown: $totalDartsThrown, dartsPerLeg: $dartsPerLeg, bustRate: $bustRate, legsPlayed: $legsPlayed, legsWon: $legsWon, firstNinePpr: $firstNinePpr, sixtyPlusTurns: $sixtyPlusTurns, oneHundredPlusTurns: $oneHundredPlusTurns, oneFortyPlusTurns: $oneFortyPlusTurns, oneEightyTurns: $oneEightyTurns)';
}


}

/// @nodoc
abstract mixin class $PlayerStatsCopyWith<$Res>  {
  factory $PlayerStatsCopyWith(PlayerStats value, $Res Function(PlayerStats) _then) = _$PlayerStatsCopyWithImpl;
@useResult
$Res call({
 String playerId, GameType gameType, int totalGames, int gamesWon, double winRate, double threeDartAverage, double? checkoutPercentage, int? highestCheckout, int highestTurnScore, int totalDartsThrown, double dartsPerLeg, double bustRate, int legsPlayed, int legsWon, double? firstNinePpr, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns, int oneEightyTurns
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
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? gameType = null,Object? totalGames = null,Object? gamesWon = null,Object? winRate = null,Object? threeDartAverage = null,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? highestTurnScore = null,Object? totalDartsThrown = null,Object? dartsPerLeg = null,Object? bustRate = null,Object? legsPlayed = null,Object? legsWon = null,Object? firstNinePpr = freezed,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,Object? oneEightyTurns = null,}) {
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
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  GameType gameType,  int totalGames,  int gamesWon,  double winRate,  double threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int highestTurnScore,  int totalDartsThrown,  double dartsPerLeg,  double bustRate,  int legsPlayed,  int legsWon,  double? firstNinePpr,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  int oneEightyTurns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerStats() when $default != null:
return $default(_that.playerId,_that.gameType,_that.totalGames,_that.gamesWon,_that.winRate,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.highestTurnScore,_that.totalDartsThrown,_that.dartsPerLeg,_that.bustRate,_that.legsPlayed,_that.legsWon,_that.firstNinePpr,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.oneEightyTurns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  GameType gameType,  int totalGames,  int gamesWon,  double winRate,  double threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int highestTurnScore,  int totalDartsThrown,  double dartsPerLeg,  double bustRate,  int legsPlayed,  int legsWon,  double? firstNinePpr,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  int oneEightyTurns)  $default,) {final _that = this;
switch (_that) {
case _PlayerStats():
return $default(_that.playerId,_that.gameType,_that.totalGames,_that.gamesWon,_that.winRate,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.highestTurnScore,_that.totalDartsThrown,_that.dartsPerLeg,_that.bustRate,_that.legsPlayed,_that.legsWon,_that.firstNinePpr,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.oneEightyTurns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  GameType gameType,  int totalGames,  int gamesWon,  double winRate,  double threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int highestTurnScore,  int totalDartsThrown,  double dartsPerLeg,  double bustRate,  int legsPlayed,  int legsWon,  double? firstNinePpr,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  int oneEightyTurns)?  $default,) {final _that = this;
switch (_that) {
case _PlayerStats() when $default != null:
return $default(_that.playerId,_that.gameType,_that.totalGames,_that.gamesWon,_that.winRate,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.highestTurnScore,_that.totalDartsThrown,_that.dartsPerLeg,_that.bustRate,_that.legsPlayed,_that.legsWon,_that.firstNinePpr,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.oneEightyTurns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerStats implements PlayerStats {
  const _PlayerStats({required this.playerId, required this.gameType, required this.totalGames, required this.gamesWon, required this.winRate, required this.threeDartAverage, this.checkoutPercentage, this.highestCheckout, required this.highestTurnScore, required this.totalDartsThrown, required this.dartsPerLeg, required this.bustRate, this.legsPlayed = 0, this.legsWon = 0, this.firstNinePpr, this.sixtyPlusTurns = 0, this.oneHundredPlusTurns = 0, this.oneFortyPlusTurns = 0, this.oneEightyTurns = 0});
  factory _PlayerStats.fromJson(Map<String, dynamic> json) => _$PlayerStatsFromJson(json);

@override final  String playerId;
@override final  GameType gameType;
@override final  int totalGames;
@override final  int gamesWon;
@override final  double winRate;
@override final  double threeDartAverage;
@override final  double? checkoutPercentage;
// null for non-X01 games
@override final  int? highestCheckout;
@override final  int highestTurnScore;
@override final  int totalDartsThrown;
@override final  double dartsPerLeg;
@override final  double bustRate;
// 0.0–1.0
@override@JsonKey() final  int legsPlayed;
@override@JsonKey() final  int legsWon;
@override final  double? firstNinePpr;
@override@JsonKey() final  int sixtyPlusTurns;
@override@JsonKey() final  int oneHundredPlusTurns;
@override@JsonKey() final  int oneFortyPlusTurns;
@override@JsonKey() final  int oneEightyTurns;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerStats&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.totalGames, totalGames) || other.totalGames == totalGames)&&(identical(other.gamesWon, gamesWon) || other.gamesWon == gamesWon)&&(identical(other.winRate, winRate) || other.winRate == winRate)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.checkoutPercentage, checkoutPercentage) || other.checkoutPercentage == checkoutPercentage)&&(identical(other.highestCheckout, highestCheckout) || other.highestCheckout == highestCheckout)&&(identical(other.highestTurnScore, highestTurnScore) || other.highestTurnScore == highestTurnScore)&&(identical(other.totalDartsThrown, totalDartsThrown) || other.totalDartsThrown == totalDartsThrown)&&(identical(other.dartsPerLeg, dartsPerLeg) || other.dartsPerLeg == dartsPerLeg)&&(identical(other.bustRate, bustRate) || other.bustRate == bustRate)&&(identical(other.legsPlayed, legsPlayed) || other.legsPlayed == legsPlayed)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.firstNinePpr, firstNinePpr) || other.firstNinePpr == firstNinePpr)&&(identical(other.sixtyPlusTurns, sixtyPlusTurns) || other.sixtyPlusTurns == sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, oneHundredPlusTurns) || other.oneHundredPlusTurns == oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, oneFortyPlusTurns) || other.oneFortyPlusTurns == oneFortyPlusTurns)&&(identical(other.oneEightyTurns, oneEightyTurns) || other.oneEightyTurns == oneEightyTurns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,playerId,gameType,totalGames,gamesWon,winRate,threeDartAverage,checkoutPercentage,highestCheckout,highestTurnScore,totalDartsThrown,dartsPerLeg,bustRate,legsPlayed,legsWon,firstNinePpr,sixtyPlusTurns,oneHundredPlusTurns,oneFortyPlusTurns,oneEightyTurns]);

@override
String toString() {
  return 'PlayerStats(playerId: $playerId, gameType: $gameType, totalGames: $totalGames, gamesWon: $gamesWon, winRate: $winRate, threeDartAverage: $threeDartAverage, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, highestTurnScore: $highestTurnScore, totalDartsThrown: $totalDartsThrown, dartsPerLeg: $dartsPerLeg, bustRate: $bustRate, legsPlayed: $legsPlayed, legsWon: $legsWon, firstNinePpr: $firstNinePpr, sixtyPlusTurns: $sixtyPlusTurns, oneHundredPlusTurns: $oneHundredPlusTurns, oneFortyPlusTurns: $oneFortyPlusTurns, oneEightyTurns: $oneEightyTurns)';
}


}

/// @nodoc
abstract mixin class _$PlayerStatsCopyWith<$Res> implements $PlayerStatsCopyWith<$Res> {
  factory _$PlayerStatsCopyWith(_PlayerStats value, $Res Function(_PlayerStats) _then) = __$PlayerStatsCopyWithImpl;
@override @useResult
$Res call({
 String playerId, GameType gameType, int totalGames, int gamesWon, double winRate, double threeDartAverage, double? checkoutPercentage, int? highestCheckout, int highestTurnScore, int totalDartsThrown, double dartsPerLeg, double bustRate, int legsPlayed, int legsWon, double? firstNinePpr, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns, int oneEightyTurns
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
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? gameType = null,Object? totalGames = null,Object? gamesWon = null,Object? winRate = null,Object? threeDartAverage = null,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? highestTurnScore = null,Object? totalDartsThrown = null,Object? dartsPerLeg = null,Object? bustRate = null,Object? legsPlayed = null,Object? legsWon = null,Object? firstNinePpr = freezed,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,Object? oneEightyTurns = null,}) {
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
as int,
  ));
}


}

// dart format on
