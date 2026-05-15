// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Game {

@JsonKey(name: 'game_id') String get gameId;@JsonKey(name: 'game_type', unknownEnumValue: GameType.x01) GameType get gameType;@JsonKey(name: 'config_json') GameConfig get config;@JsonKey(name: 'start_time') DateTime get startTime;@JsonKey(name: 'end_time') DateTime? get endTime;@JsonKey(name: 'winner_competitor_id') String? get winnerCompetitorId;@JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt) bool? get isComplete;
/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameCopyWith<Game> get copyWith => _$GameCopyWithImpl<Game>(this as Game, _$identity);

  /// Serializes this Game to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Game&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.config, config) || other.config == config)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.winnerCompetitorId, winnerCompetitorId) || other.winnerCompetitorId == winnerCompetitorId)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,gameType,config,startTime,endTime,winnerCompetitorId,isComplete);

@override
String toString() {
  return 'Game(gameId: $gameId, gameType: $gameType, config: $config, startTime: $startTime, endTime: $endTime, winnerCompetitorId: $winnerCompetitorId, isComplete: $isComplete)';
}


}

/// @nodoc
abstract mixin class $GameCopyWith<$Res>  {
  factory $GameCopyWith(Game value, $Res Function(Game) _then) = _$GameCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'game_type', unknownEnumValue: GameType.x01) GameType gameType,@JsonKey(name: 'config_json') GameConfig config,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'winner_competitor_id') String? winnerCompetitorId,@JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt) bool? isComplete
});


$GameConfigCopyWith<$Res> get config;

}
/// @nodoc
class _$GameCopyWithImpl<$Res>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._self, this._then);

  final Game _self;
  final $Res Function(Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? gameType = null,Object? config = null,Object? startTime = null,Object? endTime = freezed,Object? winnerCompetitorId = freezed,Object? isComplete = freezed,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,isComplete: freezed == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameConfigCopyWith<$Res> get config {
  
  return $GameConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [Game].
extension GamePatterns on Game {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Game value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Game value)  $default,){
final _that = this;
switch (_that) {
case _Game():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Game value)?  $default,){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)  GameType gameType, @JsonKey(name: 'config_json')  GameConfig config, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'winner_competitor_id')  String? winnerCompetitorId, @JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt)  bool? isComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.gameId,_that.gameType,_that.config,_that.startTime,_that.endTime,_that.winnerCompetitorId,_that.isComplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)  GameType gameType, @JsonKey(name: 'config_json')  GameConfig config, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'winner_competitor_id')  String? winnerCompetitorId, @JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt)  bool? isComplete)  $default,) {final _that = this;
switch (_that) {
case _Game():
return $default(_that.gameId,_that.gameType,_that.config,_that.startTime,_that.endTime,_that.winnerCompetitorId,_that.isComplete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)  GameType gameType, @JsonKey(name: 'config_json')  GameConfig config, @JsonKey(name: 'start_time')  DateTime startTime, @JsonKey(name: 'end_time')  DateTime? endTime, @JsonKey(name: 'winner_competitor_id')  String? winnerCompetitorId, @JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt)  bool? isComplete)?  $default,) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.gameId,_that.gameType,_that.config,_that.startTime,_that.endTime,_that.winnerCompetitorId,_that.isComplete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Game implements Game {
  const _Game({@JsonKey(name: 'game_id') required this.gameId, @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01) required this.gameType, @JsonKey(name: 'config_json') required this.config, @JsonKey(name: 'start_time') required this.startTime, @JsonKey(name: 'end_time') this.endTime, @JsonKey(name: 'winner_competitor_id') this.winnerCompetitorId, @JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt) this.isComplete});
  factory _Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);

@override@JsonKey(name: 'game_id') final  String gameId;
@override@JsonKey(name: 'game_type', unknownEnumValue: GameType.x01) final  GameType gameType;
@override@JsonKey(name: 'config_json') final  GameConfig config;
@override@JsonKey(name: 'start_time') final  DateTime startTime;
@override@JsonKey(name: 'end_time') final  DateTime? endTime;
@override@JsonKey(name: 'winner_competitor_id') final  String? winnerCompetitorId;
@override@JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt) final  bool? isComplete;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameCopyWith<_Game> get copyWith => __$GameCopyWithImpl<_Game>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Game&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.config, config) || other.config == config)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.winnerCompetitorId, winnerCompetitorId) || other.winnerCompetitorId == winnerCompetitorId)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,gameType,config,startTime,endTime,winnerCompetitorId,isComplete);

@override
String toString() {
  return 'Game(gameId: $gameId, gameType: $gameType, config: $config, startTime: $startTime, endTime: $endTime, winnerCompetitorId: $winnerCompetitorId, isComplete: $isComplete)';
}


}

/// @nodoc
abstract mixin class _$GameCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$GameCopyWith(_Game value, $Res Function(_Game) _then) = __$GameCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'game_type', unknownEnumValue: GameType.x01) GameType gameType,@JsonKey(name: 'config_json') GameConfig config,@JsonKey(name: 'start_time') DateTime startTime,@JsonKey(name: 'end_time') DateTime? endTime,@JsonKey(name: 'winner_competitor_id') String? winnerCompetitorId,@JsonKey(name: 'is_complete', fromJson: _parseBoolFromDynamic, toJson: _convertBoolToInt) bool? isComplete
});


@override $GameConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$GameCopyWithImpl<$Res>
    implements _$GameCopyWith<$Res> {
  __$GameCopyWithImpl(this._self, this._then);

  final _Game _self;
  final $Res Function(_Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? gameType = null,Object? config = null,Object? startTime = null,Object? endTime = freezed,Object? winnerCompetitorId = freezed,Object? isComplete = freezed,}) {
  return _then(_Game(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,isComplete: freezed == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameConfigCopyWith<$Res> get config {
  
  return $GameConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

// dart format on
