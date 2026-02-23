// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dart_throw.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DartThrow {

@JsonKey(name: 'dart_id') String get dartId;@JsonKey(name: 'game_id') String get gameId;@JsonKey(name: 'competitor_id') String get competitorId;@JsonKey(name: 'player_id') String get playerId;@JsonKey(name: 'turn_number') int get turnNumber;@JsonKey(name: 'dart_number') int get dartNumber;// 1, 2, or 3
@JsonKey(name: 'segment') String get segment;// canonical: '20', 'T20', 'D20', 'SB', 'DB', 'MISS'
@JsonKey(name: 'score') int get score;@JsonKey(name: 'x') double? get x;// coordinates for auto-scoring
@JsonKey(name: 'y') double? get y;
/// Create a copy of DartThrow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DartThrowCopyWith<DartThrow> get copyWith => _$DartThrowCopyWithImpl<DartThrow>(this as DartThrow, _$identity);

  /// Serializes this DartThrow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DartThrow&&(identical(other.dartId, dartId) || other.dartId == dartId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.turnNumber, turnNumber) || other.turnNumber == turnNumber)&&(identical(other.dartNumber, dartNumber) || other.dartNumber == dartNumber)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.score, score) || other.score == score)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dartId,gameId,competitorId,playerId,turnNumber,dartNumber,segment,score,x,y);

@override
String toString() {
  return 'DartThrow(dartId: $dartId, gameId: $gameId, competitorId: $competitorId, playerId: $playerId, turnNumber: $turnNumber, dartNumber: $dartNumber, segment: $segment, score: $score, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class $DartThrowCopyWith<$Res>  {
  factory $DartThrowCopyWith(DartThrow value, $Res Function(DartThrow) _then) = _$DartThrowCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'dart_id') String dartId,@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'competitor_id') String competitorId,@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'turn_number') int turnNumber,@JsonKey(name: 'dart_number') int dartNumber,@JsonKey(name: 'segment') String segment,@JsonKey(name: 'score') int score,@JsonKey(name: 'x') double? x,@JsonKey(name: 'y') double? y
});




}
/// @nodoc
class _$DartThrowCopyWithImpl<$Res>
    implements $DartThrowCopyWith<$Res> {
  _$DartThrowCopyWithImpl(this._self, this._then);

  final DartThrow _self;
  final $Res Function(DartThrow) _then;

/// Create a copy of DartThrow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dartId = null,Object? gameId = null,Object? competitorId = null,Object? playerId = null,Object? turnNumber = null,Object? dartNumber = null,Object? segment = null,Object? score = null,Object? x = freezed,Object? y = freezed,}) {
  return _then(_self.copyWith(
dartId: null == dartId ? _self.dartId : dartId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,turnNumber: null == turnNumber ? _self.turnNumber : turnNumber // ignore: cast_nullable_to_non_nullable
as int,dartNumber: null == dartNumber ? _self.dartNumber : dartNumber // ignore: cast_nullable_to_non_nullable
as int,segment: null == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,x: freezed == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double?,y: freezed == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [DartThrow].
extension DartThrowPatterns on DartThrow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DartThrow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DartThrow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DartThrow value)  $default,){
final _that = this;
switch (_that) {
case _DartThrow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DartThrow value)?  $default,){
final _that = this;
switch (_that) {
case _DartThrow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'dart_id')  String dartId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'competitor_id')  String competitorId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'turn_number')  int turnNumber, @JsonKey(name: 'dart_number')  int dartNumber, @JsonKey(name: 'segment')  String segment, @JsonKey(name: 'score')  int score, @JsonKey(name: 'x')  double? x, @JsonKey(name: 'y')  double? y)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DartThrow() when $default != null:
return $default(_that.dartId,_that.gameId,_that.competitorId,_that.playerId,_that.turnNumber,_that.dartNumber,_that.segment,_that.score,_that.x,_that.y);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'dart_id')  String dartId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'competitor_id')  String competitorId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'turn_number')  int turnNumber, @JsonKey(name: 'dart_number')  int dartNumber, @JsonKey(name: 'segment')  String segment, @JsonKey(name: 'score')  int score, @JsonKey(name: 'x')  double? x, @JsonKey(name: 'y')  double? y)  $default,) {final _that = this;
switch (_that) {
case _DartThrow():
return $default(_that.dartId,_that.gameId,_that.competitorId,_that.playerId,_that.turnNumber,_that.dartNumber,_that.segment,_that.score,_that.x,_that.y);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'dart_id')  String dartId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'competitor_id')  String competitorId, @JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'turn_number')  int turnNumber, @JsonKey(name: 'dart_number')  int dartNumber, @JsonKey(name: 'segment')  String segment, @JsonKey(name: 'score')  int score, @JsonKey(name: 'x')  double? x, @JsonKey(name: 'y')  double? y)?  $default,) {final _that = this;
switch (_that) {
case _DartThrow() when $default != null:
return $default(_that.dartId,_that.gameId,_that.competitorId,_that.playerId,_that.turnNumber,_that.dartNumber,_that.segment,_that.score,_that.x,_that.y);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DartThrow implements DartThrow {
  const _DartThrow({@JsonKey(name: 'dart_id') required this.dartId, @JsonKey(name: 'game_id') required this.gameId, @JsonKey(name: 'competitor_id') required this.competitorId, @JsonKey(name: 'player_id') required this.playerId, @JsonKey(name: 'turn_number') required this.turnNumber, @JsonKey(name: 'dart_number') required this.dartNumber, @JsonKey(name: 'segment') required this.segment, @JsonKey(name: 'score') required this.score, @JsonKey(name: 'x') this.x, @JsonKey(name: 'y') this.y});
  factory _DartThrow.fromJson(Map<String, dynamic> json) => _$DartThrowFromJson(json);

@override@JsonKey(name: 'dart_id') final  String dartId;
@override@JsonKey(name: 'game_id') final  String gameId;
@override@JsonKey(name: 'competitor_id') final  String competitorId;
@override@JsonKey(name: 'player_id') final  String playerId;
@override@JsonKey(name: 'turn_number') final  int turnNumber;
@override@JsonKey(name: 'dart_number') final  int dartNumber;
// 1, 2, or 3
@override@JsonKey(name: 'segment') final  String segment;
// canonical: '20', 'T20', 'D20', 'SB', 'DB', 'MISS'
@override@JsonKey(name: 'score') final  int score;
@override@JsonKey(name: 'x') final  double? x;
// coordinates for auto-scoring
@override@JsonKey(name: 'y') final  double? y;

/// Create a copy of DartThrow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DartThrowCopyWith<_DartThrow> get copyWith => __$DartThrowCopyWithImpl<_DartThrow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DartThrowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DartThrow&&(identical(other.dartId, dartId) || other.dartId == dartId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.turnNumber, turnNumber) || other.turnNumber == turnNumber)&&(identical(other.dartNumber, dartNumber) || other.dartNumber == dartNumber)&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.score, score) || other.score == score)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dartId,gameId,competitorId,playerId,turnNumber,dartNumber,segment,score,x,y);

@override
String toString() {
  return 'DartThrow(dartId: $dartId, gameId: $gameId, competitorId: $competitorId, playerId: $playerId, turnNumber: $turnNumber, dartNumber: $dartNumber, segment: $segment, score: $score, x: $x, y: $y)';
}


}

/// @nodoc
abstract mixin class _$DartThrowCopyWith<$Res> implements $DartThrowCopyWith<$Res> {
  factory _$DartThrowCopyWith(_DartThrow value, $Res Function(_DartThrow) _then) = __$DartThrowCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'dart_id') String dartId,@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'competitor_id') String competitorId,@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'turn_number') int turnNumber,@JsonKey(name: 'dart_number') int dartNumber,@JsonKey(name: 'segment') String segment,@JsonKey(name: 'score') int score,@JsonKey(name: 'x') double? x,@JsonKey(name: 'y') double? y
});




}
/// @nodoc
class __$DartThrowCopyWithImpl<$Res>
    implements _$DartThrowCopyWith<$Res> {
  __$DartThrowCopyWithImpl(this._self, this._then);

  final _DartThrow _self;
  final $Res Function(_DartThrow) _then;

/// Create a copy of DartThrow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dartId = null,Object? gameId = null,Object? competitorId = null,Object? playerId = null,Object? turnNumber = null,Object? dartNumber = null,Object? segment = null,Object? score = null,Object? x = freezed,Object? y = freezed,}) {
  return _then(_DartThrow(
dartId: null == dartId ? _self.dartId : dartId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,turnNumber: null == turnNumber ? _self.turnNumber : turnNumber // ignore: cast_nullable_to_non_nullable
as int,dartNumber: null == dartNumber ? _self.dartNumber : dartNumber // ignore: cast_nullable_to_non_nullable
as int,segment: null == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,x: freezed == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double?,y: freezed == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
