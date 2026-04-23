// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_cricket_game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveCricketGameState {

 GameState get gameState; String? get pendingLegWinnerId; String? get pendingGameWinnerId; bool get pendingCapSelection;
/// Create a copy of ActiveCricketGameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveCricketGameStateCopyWith<ActiveCricketGameState> get copyWith => _$ActiveCricketGameStateCopyWithImpl<ActiveCricketGameState>(this as ActiveCricketGameState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveCricketGameState&&(identical(other.gameState, gameState) || other.gameState == gameState)&&(identical(other.pendingLegWinnerId, pendingLegWinnerId) || other.pendingLegWinnerId == pendingLegWinnerId)&&(identical(other.pendingGameWinnerId, pendingGameWinnerId) || other.pendingGameWinnerId == pendingGameWinnerId)&&(identical(other.pendingCapSelection, pendingCapSelection) || other.pendingCapSelection == pendingCapSelection));
}


@override
int get hashCode => Object.hash(runtimeType,gameState,pendingLegWinnerId,pendingGameWinnerId,pendingCapSelection);

@override
String toString() {
  return 'ActiveCricketGameState(gameState: $gameState, pendingLegWinnerId: $pendingLegWinnerId, pendingGameWinnerId: $pendingGameWinnerId, pendingCapSelection: $pendingCapSelection)';
}


}

/// @nodoc
abstract mixin class $ActiveCricketGameStateCopyWith<$Res>  {
  factory $ActiveCricketGameStateCopyWith(ActiveCricketGameState value, $Res Function(ActiveCricketGameState) _then) = _$ActiveCricketGameStateCopyWithImpl;
@useResult
$Res call({
 GameState gameState, String? pendingLegWinnerId, String? pendingGameWinnerId, bool pendingCapSelection
});


$GameStateCopyWith<$Res> get gameState;

}
/// @nodoc
class _$ActiveCricketGameStateCopyWithImpl<$Res>
    implements $ActiveCricketGameStateCopyWith<$Res> {
  _$ActiveCricketGameStateCopyWithImpl(this._self, this._then);

  final ActiveCricketGameState _self;
  final $Res Function(ActiveCricketGameState) _then;

/// Create a copy of ActiveCricketGameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameState = null,Object? pendingLegWinnerId = freezed,Object? pendingGameWinnerId = freezed,Object? pendingCapSelection = null,}) {
  return _then(_self.copyWith(
gameState: null == gameState ? _self.gameState : gameState // ignore: cast_nullable_to_non_nullable
as GameState,pendingLegWinnerId: freezed == pendingLegWinnerId ? _self.pendingLegWinnerId : pendingLegWinnerId // ignore: cast_nullable_to_non_nullable
as String?,pendingGameWinnerId: freezed == pendingGameWinnerId ? _self.pendingGameWinnerId : pendingGameWinnerId // ignore: cast_nullable_to_non_nullable
as String?,pendingCapSelection: null == pendingCapSelection ? _self.pendingCapSelection : pendingCapSelection // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ActiveCricketGameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStateCopyWith<$Res> get gameState {
  
  return $GameStateCopyWith<$Res>(_self.gameState, (value) {
    return _then(_self.copyWith(gameState: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActiveCricketGameState].
extension ActiveCricketGameStatePatterns on ActiveCricketGameState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveCricketGameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveCricketGameState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveCricketGameState value)  $default,){
final _that = this;
switch (_that) {
case _ActiveCricketGameState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveCricketGameState value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveCricketGameState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameState gameState,  String? pendingLegWinnerId,  String? pendingGameWinnerId,  bool pendingCapSelection)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveCricketGameState() when $default != null:
return $default(_that.gameState,_that.pendingLegWinnerId,_that.pendingGameWinnerId,_that.pendingCapSelection);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameState gameState,  String? pendingLegWinnerId,  String? pendingGameWinnerId,  bool pendingCapSelection)  $default,) {final _that = this;
switch (_that) {
case _ActiveCricketGameState():
return $default(_that.gameState,_that.pendingLegWinnerId,_that.pendingGameWinnerId,_that.pendingCapSelection);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameState gameState,  String? pendingLegWinnerId,  String? pendingGameWinnerId,  bool pendingCapSelection)?  $default,) {final _that = this;
switch (_that) {
case _ActiveCricketGameState() when $default != null:
return $default(_that.gameState,_that.pendingLegWinnerId,_that.pendingGameWinnerId,_that.pendingCapSelection);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveCricketGameState implements ActiveCricketGameState {
  const _ActiveCricketGameState({required this.gameState, this.pendingLegWinnerId, this.pendingGameWinnerId, this.pendingCapSelection = false});
  

@override final  GameState gameState;
@override final  String? pendingLegWinnerId;
@override final  String? pendingGameWinnerId;
@override@JsonKey() final  bool pendingCapSelection;

/// Create a copy of ActiveCricketGameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveCricketGameStateCopyWith<_ActiveCricketGameState> get copyWith => __$ActiveCricketGameStateCopyWithImpl<_ActiveCricketGameState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveCricketGameState&&(identical(other.gameState, gameState) || other.gameState == gameState)&&(identical(other.pendingLegWinnerId, pendingLegWinnerId) || other.pendingLegWinnerId == pendingLegWinnerId)&&(identical(other.pendingGameWinnerId, pendingGameWinnerId) || other.pendingGameWinnerId == pendingGameWinnerId)&&(identical(other.pendingCapSelection, pendingCapSelection) || other.pendingCapSelection == pendingCapSelection));
}


@override
int get hashCode => Object.hash(runtimeType,gameState,pendingLegWinnerId,pendingGameWinnerId,pendingCapSelection);

@override
String toString() {
  return 'ActiveCricketGameState(gameState: $gameState, pendingLegWinnerId: $pendingLegWinnerId, pendingGameWinnerId: $pendingGameWinnerId, pendingCapSelection: $pendingCapSelection)';
}


}

/// @nodoc
abstract mixin class _$ActiveCricketGameStateCopyWith<$Res> implements $ActiveCricketGameStateCopyWith<$Res> {
  factory _$ActiveCricketGameStateCopyWith(_ActiveCricketGameState value, $Res Function(_ActiveCricketGameState) _then) = __$ActiveCricketGameStateCopyWithImpl;
@override @useResult
$Res call({
 GameState gameState, String? pendingLegWinnerId, String? pendingGameWinnerId, bool pendingCapSelection
});


@override $GameStateCopyWith<$Res> get gameState;

}
/// @nodoc
class __$ActiveCricketGameStateCopyWithImpl<$Res>
    implements _$ActiveCricketGameStateCopyWith<$Res> {
  __$ActiveCricketGameStateCopyWithImpl(this._self, this._then);

  final _ActiveCricketGameState _self;
  final $Res Function(_ActiveCricketGameState) _then;

/// Create a copy of ActiveCricketGameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameState = null,Object? pendingLegWinnerId = freezed,Object? pendingGameWinnerId = freezed,Object? pendingCapSelection = null,}) {
  return _then(_ActiveCricketGameState(
gameState: null == gameState ? _self.gameState : gameState // ignore: cast_nullable_to_non_nullable
as GameState,pendingLegWinnerId: freezed == pendingLegWinnerId ? _self.pendingLegWinnerId : pendingLegWinnerId // ignore: cast_nullable_to_non_nullable
as String?,pendingGameWinnerId: freezed == pendingGameWinnerId ? _self.pendingGameWinnerId : pendingGameWinnerId // ignore: cast_nullable_to_non_nullable
as String?,pendingCapSelection: null == pendingCapSelection ? _self.pendingCapSelection : pendingCapSelection // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ActiveCricketGameState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStateCopyWith<$Res> get gameState {
  
  return $GameStateCopyWith<$Res>(_self.gameState, (value) {
    return _then(_self.copyWith(gameState: value));
  });
}
}

// dart format on
