// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameStats {

 String get gameId; List<CompetitorStats> get byCompetitor;
/// Create a copy of GameStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStatsCopyWith<GameStats> get copyWith => _$GameStatsCopyWithImpl<GameStats>(this as GameStats, _$identity);

  /// Serializes this GameStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStats&&(identical(other.gameId, gameId) || other.gameId == gameId)&&const DeepCollectionEquality().equals(other.byCompetitor, byCompetitor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,const DeepCollectionEquality().hash(byCompetitor));

@override
String toString() {
  return 'GameStats(gameId: $gameId, byCompetitor: $byCompetitor)';
}


}

/// @nodoc
abstract mixin class $GameStatsCopyWith<$Res>  {
  factory $GameStatsCopyWith(GameStats value, $Res Function(GameStats) _then) = _$GameStatsCopyWithImpl;
@useResult
$Res call({
 String gameId, List<CompetitorStats> byCompetitor
});




}
/// @nodoc
class _$GameStatsCopyWithImpl<$Res>
    implements $GameStatsCopyWith<$Res> {
  _$GameStatsCopyWithImpl(this._self, this._then);

  final GameStats _self;
  final $Res Function(GameStats) _then;

/// Create a copy of GameStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? byCompetitor = null,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,byCompetitor: null == byCompetitor ? _self.byCompetitor : byCompetitor // ignore: cast_nullable_to_non_nullable
as List<CompetitorStats>,
  ));
}

}


/// Adds pattern-matching-related methods to [GameStats].
extension GameStatsPatterns on GameStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameStats value)  $default,){
final _that = this;
switch (_that) {
case _GameStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameStats value)?  $default,){
final _that = this;
switch (_that) {
case _GameStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  List<CompetitorStats> byCompetitor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameStats() when $default != null:
return $default(_that.gameId,_that.byCompetitor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  List<CompetitorStats> byCompetitor)  $default,) {final _that = this;
switch (_that) {
case _GameStats():
return $default(_that.gameId,_that.byCompetitor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  List<CompetitorStats> byCompetitor)?  $default,) {final _that = this;
switch (_that) {
case _GameStats() when $default != null:
return $default(_that.gameId,_that.byCompetitor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameStats implements GameStats {
  const _GameStats({required this.gameId, required final  List<CompetitorStats> byCompetitor}): _byCompetitor = byCompetitor;
  factory _GameStats.fromJson(Map<String, dynamic> json) => _$GameStatsFromJson(json);

@override final  String gameId;
 final  List<CompetitorStats> _byCompetitor;
@override List<CompetitorStats> get byCompetitor {
  if (_byCompetitor is EqualUnmodifiableListView) return _byCompetitor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCompetitor);
}


/// Create a copy of GameStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStatsCopyWith<_GameStats> get copyWith => __$GameStatsCopyWithImpl<_GameStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameStats&&(identical(other.gameId, gameId) || other.gameId == gameId)&&const DeepCollectionEquality().equals(other._byCompetitor, _byCompetitor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,const DeepCollectionEquality().hash(_byCompetitor));

@override
String toString() {
  return 'GameStats(gameId: $gameId, byCompetitor: $byCompetitor)';
}


}

/// @nodoc
abstract mixin class _$GameStatsCopyWith<$Res> implements $GameStatsCopyWith<$Res> {
  factory _$GameStatsCopyWith(_GameStats value, $Res Function(_GameStats) _then) = __$GameStatsCopyWithImpl;
@override @useResult
$Res call({
 String gameId, List<CompetitorStats> byCompetitor
});




}
/// @nodoc
class __$GameStatsCopyWithImpl<$Res>
    implements _$GameStatsCopyWith<$Res> {
  __$GameStatsCopyWithImpl(this._self, this._then);

  final _GameStats _self;
  final $Res Function(_GameStats) _then;

/// Create a copy of GameStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? byCompetitor = null,}) {
  return _then(_GameStats(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,byCompetitor: null == byCompetitor ? _self._byCompetitor : byCompetitor // ignore: cast_nullable_to_non_nullable
as List<CompetitorStats>,
  ));
}


}


/// @nodoc
mixin _$CompetitorStats {

 String get competitorId; String get competitorName; List<PlayerTurnStats> get byPlayer; double get threeDartAverage; int get legsWon; int get totalDartsThrown; double? get checkoutPercentage; int? get highestCheckout; int get oneEightyTurns; int get sixtyPlusTurns; int get oneHundredPlusTurns; int get oneFortyPlusTurns;
/// Create a copy of CompetitorStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompetitorStatsCopyWith<CompetitorStats> get copyWith => _$CompetitorStatsCopyWithImpl<CompetitorStats>(this as CompetitorStats, _$identity);

  /// Serializes this CompetitorStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompetitorStats&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&const DeepCollectionEquality().equals(other.byPlayer, byPlayer)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.totalDartsThrown, totalDartsThrown) || other.totalDartsThrown == totalDartsThrown)&&(identical(other.checkoutPercentage, checkoutPercentage) || other.checkoutPercentage == checkoutPercentage)&&(identical(other.highestCheckout, highestCheckout) || other.highestCheckout == highestCheckout)&&(identical(other.oneEightyTurns, oneEightyTurns) || other.oneEightyTurns == oneEightyTurns)&&(identical(other.sixtyPlusTurns, sixtyPlusTurns) || other.sixtyPlusTurns == sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, oneHundredPlusTurns) || other.oneHundredPlusTurns == oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, oneFortyPlusTurns) || other.oneFortyPlusTurns == oneFortyPlusTurns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,competitorName,const DeepCollectionEquality().hash(byPlayer),threeDartAverage,legsWon,totalDartsThrown,checkoutPercentage,highestCheckout,oneEightyTurns,sixtyPlusTurns,oneHundredPlusTurns,oneFortyPlusTurns);

@override
String toString() {
  return 'CompetitorStats(competitorId: $competitorId, competitorName: $competitorName, byPlayer: $byPlayer, threeDartAverage: $threeDartAverage, legsWon: $legsWon, totalDartsThrown: $totalDartsThrown, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, oneEightyTurns: $oneEightyTurns, sixtyPlusTurns: $sixtyPlusTurns, oneHundredPlusTurns: $oneHundredPlusTurns, oneFortyPlusTurns: $oneFortyPlusTurns)';
}


}

/// @nodoc
abstract mixin class $CompetitorStatsCopyWith<$Res>  {
  factory $CompetitorStatsCopyWith(CompetitorStats value, $Res Function(CompetitorStats) _then) = _$CompetitorStatsCopyWithImpl;
@useResult
$Res call({
 String competitorId, String competitorName, List<PlayerTurnStats> byPlayer, double threeDartAverage, int legsWon, int totalDartsThrown, double? checkoutPercentage, int? highestCheckout, int oneEightyTurns, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns
});




}
/// @nodoc
class _$CompetitorStatsCopyWithImpl<$Res>
    implements $CompetitorStatsCopyWith<$Res> {
  _$CompetitorStatsCopyWithImpl(this._self, this._then);

  final CompetitorStats _self;
  final $Res Function(CompetitorStats) _then;

/// Create a copy of CompetitorStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competitorId = null,Object? competitorName = null,Object? byPlayer = null,Object? threeDartAverage = null,Object? legsWon = null,Object? totalDartsThrown = null,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? oneEightyTurns = null,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,}) {
  return _then(_self.copyWith(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,byPlayer: null == byPlayer ? _self.byPlayer : byPlayer // ignore: cast_nullable_to_non_nullable
as List<PlayerTurnStats>,threeDartAverage: null == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double,legsWon: null == legsWon ? _self.legsWon : legsWon // ignore: cast_nullable_to_non_nullable
as int,totalDartsThrown: null == totalDartsThrown ? _self.totalDartsThrown : totalDartsThrown // ignore: cast_nullable_to_non_nullable
as int,checkoutPercentage: freezed == checkoutPercentage ? _self.checkoutPercentage : checkoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,highestCheckout: freezed == highestCheckout ? _self.highestCheckout : highestCheckout // ignore: cast_nullable_to_non_nullable
as int?,oneEightyTurns: null == oneEightyTurns ? _self.oneEightyTurns : oneEightyTurns // ignore: cast_nullable_to_non_nullable
as int,sixtyPlusTurns: null == sixtyPlusTurns ? _self.sixtyPlusTurns : sixtyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneHundredPlusTurns: null == oneHundredPlusTurns ? _self.oneHundredPlusTurns : oneHundredPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneFortyPlusTurns: null == oneFortyPlusTurns ? _self.oneFortyPlusTurns : oneFortyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CompetitorStats].
extension CompetitorStatsPatterns on CompetitorStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompetitorStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompetitorStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompetitorStats value)  $default,){
final _that = this;
switch (_that) {
case _CompetitorStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompetitorStats value)?  $default,){
final _that = this;
switch (_that) {
case _CompetitorStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  List<PlayerTurnStats> byPlayer,  double threeDartAverage,  int legsWon,  int totalDartsThrown,  double? checkoutPercentage,  int? highestCheckout,  int oneEightyTurns,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompetitorStats() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.byPlayer,_that.threeDartAverage,_that.legsWon,_that.totalDartsThrown,_that.checkoutPercentage,_that.highestCheckout,_that.oneEightyTurns,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  List<PlayerTurnStats> byPlayer,  double threeDartAverage,  int legsWon,  int totalDartsThrown,  double? checkoutPercentage,  int? highestCheckout,  int oneEightyTurns,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns)  $default,) {final _that = this;
switch (_that) {
case _CompetitorStats():
return $default(_that.competitorId,_that.competitorName,_that.byPlayer,_that.threeDartAverage,_that.legsWon,_that.totalDartsThrown,_that.checkoutPercentage,_that.highestCheckout,_that.oneEightyTurns,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String competitorId,  String competitorName,  List<PlayerTurnStats> byPlayer,  double threeDartAverage,  int legsWon,  int totalDartsThrown,  double? checkoutPercentage,  int? highestCheckout,  int oneEightyTurns,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns)?  $default,) {final _that = this;
switch (_that) {
case _CompetitorStats() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.byPlayer,_that.threeDartAverage,_that.legsWon,_that.totalDartsThrown,_that.checkoutPercentage,_that.highestCheckout,_that.oneEightyTurns,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompetitorStats implements CompetitorStats {
  const _CompetitorStats({required this.competitorId, required this.competitorName, required final  List<PlayerTurnStats> byPlayer, required this.threeDartAverage, required this.legsWon, required this.totalDartsThrown, this.checkoutPercentage, this.highestCheckout, this.oneEightyTurns = 0, this.sixtyPlusTurns = 0, this.oneHundredPlusTurns = 0, this.oneFortyPlusTurns = 0}): _byPlayer = byPlayer;
  factory _CompetitorStats.fromJson(Map<String, dynamic> json) => _$CompetitorStatsFromJson(json);

@override final  String competitorId;
@override final  String competitorName;
 final  List<PlayerTurnStats> _byPlayer;
@override List<PlayerTurnStats> get byPlayer {
  if (_byPlayer is EqualUnmodifiableListView) return _byPlayer;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byPlayer);
}

@override final  double threeDartAverage;
@override final  int legsWon;
@override final  int totalDartsThrown;
@override final  double? checkoutPercentage;
@override final  int? highestCheckout;
@override@JsonKey() final  int oneEightyTurns;
@override@JsonKey() final  int sixtyPlusTurns;
@override@JsonKey() final  int oneHundredPlusTurns;
@override@JsonKey() final  int oneFortyPlusTurns;

/// Create a copy of CompetitorStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompetitorStatsCopyWith<_CompetitorStats> get copyWith => __$CompetitorStatsCopyWithImpl<_CompetitorStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompetitorStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompetitorStats&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&const DeepCollectionEquality().equals(other._byPlayer, _byPlayer)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.totalDartsThrown, totalDartsThrown) || other.totalDartsThrown == totalDartsThrown)&&(identical(other.checkoutPercentage, checkoutPercentage) || other.checkoutPercentage == checkoutPercentage)&&(identical(other.highestCheckout, highestCheckout) || other.highestCheckout == highestCheckout)&&(identical(other.oneEightyTurns, oneEightyTurns) || other.oneEightyTurns == oneEightyTurns)&&(identical(other.sixtyPlusTurns, sixtyPlusTurns) || other.sixtyPlusTurns == sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, oneHundredPlusTurns) || other.oneHundredPlusTurns == oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, oneFortyPlusTurns) || other.oneFortyPlusTurns == oneFortyPlusTurns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,competitorName,const DeepCollectionEquality().hash(_byPlayer),threeDartAverage,legsWon,totalDartsThrown,checkoutPercentage,highestCheckout,oneEightyTurns,sixtyPlusTurns,oneHundredPlusTurns,oneFortyPlusTurns);

@override
String toString() {
  return 'CompetitorStats(competitorId: $competitorId, competitorName: $competitorName, byPlayer: $byPlayer, threeDartAverage: $threeDartAverage, legsWon: $legsWon, totalDartsThrown: $totalDartsThrown, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, oneEightyTurns: $oneEightyTurns, sixtyPlusTurns: $sixtyPlusTurns, oneHundredPlusTurns: $oneHundredPlusTurns, oneFortyPlusTurns: $oneFortyPlusTurns)';
}


}

/// @nodoc
abstract mixin class _$CompetitorStatsCopyWith<$Res> implements $CompetitorStatsCopyWith<$Res> {
  factory _$CompetitorStatsCopyWith(_CompetitorStats value, $Res Function(_CompetitorStats) _then) = __$CompetitorStatsCopyWithImpl;
@override @useResult
$Res call({
 String competitorId, String competitorName, List<PlayerTurnStats> byPlayer, double threeDartAverage, int legsWon, int totalDartsThrown, double? checkoutPercentage, int? highestCheckout, int oneEightyTurns, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns
});




}
/// @nodoc
class __$CompetitorStatsCopyWithImpl<$Res>
    implements _$CompetitorStatsCopyWith<$Res> {
  __$CompetitorStatsCopyWithImpl(this._self, this._then);

  final _CompetitorStats _self;
  final $Res Function(_CompetitorStats) _then;

/// Create a copy of CompetitorStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorId = null,Object? competitorName = null,Object? byPlayer = null,Object? threeDartAverage = null,Object? legsWon = null,Object? totalDartsThrown = null,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? oneEightyTurns = null,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,}) {
  return _then(_CompetitorStats(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,byPlayer: null == byPlayer ? _self._byPlayer : byPlayer // ignore: cast_nullable_to_non_nullable
as List<PlayerTurnStats>,threeDartAverage: null == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double,legsWon: null == legsWon ? _self.legsWon : legsWon // ignore: cast_nullable_to_non_nullable
as int,totalDartsThrown: null == totalDartsThrown ? _self.totalDartsThrown : totalDartsThrown // ignore: cast_nullable_to_non_nullable
as int,checkoutPercentage: freezed == checkoutPercentage ? _self.checkoutPercentage : checkoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,highestCheckout: freezed == highestCheckout ? _self.highestCheckout : highestCheckout // ignore: cast_nullable_to_non_nullable
as int?,oneEightyTurns: null == oneEightyTurns ? _self.oneEightyTurns : oneEightyTurns // ignore: cast_nullable_to_non_nullable
as int,sixtyPlusTurns: null == sixtyPlusTurns ? _self.sixtyPlusTurns : sixtyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneHundredPlusTurns: null == oneHundredPlusTurns ? _self.oneHundredPlusTurns : oneHundredPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneFortyPlusTurns: null == oneFortyPlusTurns ? _self.oneFortyPlusTurns : oneFortyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PlayerTurnStats {

 String get playerId; double get threeDartAverage; int get dartsThrown;
/// Create a copy of PlayerTurnStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerTurnStatsCopyWith<PlayerTurnStats> get copyWith => _$PlayerTurnStatsCopyWithImpl<PlayerTurnStats>(this as PlayerTurnStats, _$identity);

  /// Serializes this PlayerTurnStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerTurnStats&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.dartsThrown, dartsThrown) || other.dartsThrown == dartsThrown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,threeDartAverage,dartsThrown);

@override
String toString() {
  return 'PlayerTurnStats(playerId: $playerId, threeDartAverage: $threeDartAverage, dartsThrown: $dartsThrown)';
}


}

/// @nodoc
abstract mixin class $PlayerTurnStatsCopyWith<$Res>  {
  factory $PlayerTurnStatsCopyWith(PlayerTurnStats value, $Res Function(PlayerTurnStats) _then) = _$PlayerTurnStatsCopyWithImpl;
@useResult
$Res call({
 String playerId, double threeDartAverage, int dartsThrown
});




}
/// @nodoc
class _$PlayerTurnStatsCopyWithImpl<$Res>
    implements $PlayerTurnStatsCopyWith<$Res> {
  _$PlayerTurnStatsCopyWithImpl(this._self, this._then);

  final PlayerTurnStats _self;
  final $Res Function(PlayerTurnStats) _then;

/// Create a copy of PlayerTurnStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? threeDartAverage = null,Object? dartsThrown = null,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,threeDartAverage: null == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double,dartsThrown: null == dartsThrown ? _self.dartsThrown : dartsThrown // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerTurnStats].
extension PlayerTurnStatsPatterns on PlayerTurnStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerTurnStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerTurnStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerTurnStats value)  $default,){
final _that = this;
switch (_that) {
case _PlayerTurnStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerTurnStats value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerTurnStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  double threeDartAverage,  int dartsThrown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerTurnStats() when $default != null:
return $default(_that.playerId,_that.threeDartAverage,_that.dartsThrown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  double threeDartAverage,  int dartsThrown)  $default,) {final _that = this;
switch (_that) {
case _PlayerTurnStats():
return $default(_that.playerId,_that.threeDartAverage,_that.dartsThrown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  double threeDartAverage,  int dartsThrown)?  $default,) {final _that = this;
switch (_that) {
case _PlayerTurnStats() when $default != null:
return $default(_that.playerId,_that.threeDartAverage,_that.dartsThrown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerTurnStats implements PlayerTurnStats {
  const _PlayerTurnStats({required this.playerId, required this.threeDartAverage, required this.dartsThrown});
  factory _PlayerTurnStats.fromJson(Map<String, dynamic> json) => _$PlayerTurnStatsFromJson(json);

@override final  String playerId;
@override final  double threeDartAverage;
@override final  int dartsThrown;

/// Create a copy of PlayerTurnStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerTurnStatsCopyWith<_PlayerTurnStats> get copyWith => __$PlayerTurnStatsCopyWithImpl<_PlayerTurnStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerTurnStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerTurnStats&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.dartsThrown, dartsThrown) || other.dartsThrown == dartsThrown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,threeDartAverage,dartsThrown);

@override
String toString() {
  return 'PlayerTurnStats(playerId: $playerId, threeDartAverage: $threeDartAverage, dartsThrown: $dartsThrown)';
}


}

/// @nodoc
abstract mixin class _$PlayerTurnStatsCopyWith<$Res> implements $PlayerTurnStatsCopyWith<$Res> {
  factory _$PlayerTurnStatsCopyWith(_PlayerTurnStats value, $Res Function(_PlayerTurnStats) _then) = __$PlayerTurnStatsCopyWithImpl;
@override @useResult
$Res call({
 String playerId, double threeDartAverage, int dartsThrown
});




}
/// @nodoc
class __$PlayerTurnStatsCopyWithImpl<$Res>
    implements _$PlayerTurnStatsCopyWith<$Res> {
  __$PlayerTurnStatsCopyWithImpl(this._self, this._then);

  final _PlayerTurnStats _self;
  final $Res Function(_PlayerTurnStats) _then;

/// Create a copy of PlayerTurnStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? threeDartAverage = null,Object? dartsThrown = null,}) {
  return _then(_PlayerTurnStats(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,threeDartAverage: null == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double,dartsThrown: null == dartsThrown ? _self.dartsThrown : dartsThrown // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
