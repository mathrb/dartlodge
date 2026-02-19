// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameStateSnapshot {

 String get gameId; String get gameType; Map<String, dynamic> get stateData;// Game-specific state data
 DateTime get timestamp; bool get isComplete; String? get winnerId;
/// Create a copy of GameStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateSnapshotCopyWith<GameStateSnapshot> get copyWith => _$GameStateSnapshotCopyWithImpl<GameStateSnapshot>(this as GameStateSnapshot, _$identity);

  /// Serializes this GameStateSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameStateSnapshot&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&const DeepCollectionEquality().equals(other.stateData, stateData)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.winnerId, winnerId) || other.winnerId == winnerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,gameType,const DeepCollectionEquality().hash(stateData),timestamp,isComplete,winnerId);

@override
String toString() {
  return 'GameStateSnapshot(gameId: $gameId, gameType: $gameType, stateData: $stateData, timestamp: $timestamp, isComplete: $isComplete, winnerId: $winnerId)';
}


}

/// @nodoc
abstract mixin class $GameStateSnapshotCopyWith<$Res>  {
  factory $GameStateSnapshotCopyWith(GameStateSnapshot value, $Res Function(GameStateSnapshot) _then) = _$GameStateSnapshotCopyWithImpl;
@useResult
$Res call({
 String gameId, String gameType, Map<String, dynamic> stateData, DateTime timestamp, bool isComplete, String? winnerId
});




}
/// @nodoc
class _$GameStateSnapshotCopyWithImpl<$Res>
    implements $GameStateSnapshotCopyWith<$Res> {
  _$GameStateSnapshotCopyWithImpl(this._self, this._then);

  final GameStateSnapshot _self;
  final $Res Function(GameStateSnapshot) _then;

/// Create a copy of GameStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? gameType = null,Object? stateData = null,Object? timestamp = null,Object? isComplete = null,Object? winnerId = freezed,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as String,stateData: null == stateData ? _self.stateData : stateData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,winnerId: freezed == winnerId ? _self.winnerId : winnerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameStateSnapshot].
extension GameStateSnapshotPatterns on GameStateSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameStateSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameStateSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameStateSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _GameStateSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameStateSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _GameStateSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  String gameType,  Map<String, dynamic> stateData,  DateTime timestamp,  bool isComplete,  String? winnerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameStateSnapshot() when $default != null:
return $default(_that.gameId,_that.gameType,_that.stateData,_that.timestamp,_that.isComplete,_that.winnerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  String gameType,  Map<String, dynamic> stateData,  DateTime timestamp,  bool isComplete,  String? winnerId)  $default,) {final _that = this;
switch (_that) {
case _GameStateSnapshot():
return $default(_that.gameId,_that.gameType,_that.stateData,_that.timestamp,_that.isComplete,_that.winnerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  String gameType,  Map<String, dynamic> stateData,  DateTime timestamp,  bool isComplete,  String? winnerId)?  $default,) {final _that = this;
switch (_that) {
case _GameStateSnapshot() when $default != null:
return $default(_that.gameId,_that.gameType,_that.stateData,_that.timestamp,_that.isComplete,_that.winnerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameStateSnapshot implements GameStateSnapshot {
  const _GameStateSnapshot({required this.gameId, required this.gameType, required final  Map<String, dynamic> stateData, required this.timestamp, required this.isComplete, this.winnerId}): _stateData = stateData;
  factory _GameStateSnapshot.fromJson(Map<String, dynamic> json) => _$GameStateSnapshotFromJson(json);

@override final  String gameId;
@override final  String gameType;
 final  Map<String, dynamic> _stateData;
@override Map<String, dynamic> get stateData {
  if (_stateData is EqualUnmodifiableMapView) return _stateData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_stateData);
}

// Game-specific state data
@override final  DateTime timestamp;
@override final  bool isComplete;
@override final  String? winnerId;

/// Create a copy of GameStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStateSnapshotCopyWith<_GameStateSnapshot> get copyWith => __$GameStateSnapshotCopyWithImpl<_GameStateSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameStateSnapshot&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&const DeepCollectionEquality().equals(other._stateData, _stateData)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.winnerId, winnerId) || other.winnerId == winnerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,gameType,const DeepCollectionEquality().hash(_stateData),timestamp,isComplete,winnerId);

@override
String toString() {
  return 'GameStateSnapshot(gameId: $gameId, gameType: $gameType, stateData: $stateData, timestamp: $timestamp, isComplete: $isComplete, winnerId: $winnerId)';
}


}

/// @nodoc
abstract mixin class _$GameStateSnapshotCopyWith<$Res> implements $GameStateSnapshotCopyWith<$Res> {
  factory _$GameStateSnapshotCopyWith(_GameStateSnapshot value, $Res Function(_GameStateSnapshot) _then) = __$GameStateSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String gameId, String gameType, Map<String, dynamic> stateData, DateTime timestamp, bool isComplete, String? winnerId
});




}
/// @nodoc
class __$GameStateSnapshotCopyWithImpl<$Res>
    implements _$GameStateSnapshotCopyWith<$Res> {
  __$GameStateSnapshotCopyWithImpl(this._self, this._then);

  final _GameStateSnapshot _self;
  final $Res Function(_GameStateSnapshot) _then;

/// Create a copy of GameStateSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? gameType = null,Object? stateData = null,Object? timestamp = null,Object? isComplete = null,Object? winnerId = freezed,}) {
  return _then(_GameStateSnapshot(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as String,stateData: null == stateData ? _self._stateData : stateData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,winnerId: freezed == winnerId ? _self.winnerId : winnerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
