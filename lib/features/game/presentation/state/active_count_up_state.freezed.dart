// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_count_up_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveCountUpState {

 GameState get gameState; String? get pendingGameWinnerId;
/// Create a copy of ActiveCountUpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveCountUpStateCopyWith<ActiveCountUpState> get copyWith => _$ActiveCountUpStateCopyWithImpl<ActiveCountUpState>(this as ActiveCountUpState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveCountUpState&&(identical(other.gameState, gameState) || other.gameState == gameState)&&(identical(other.pendingGameWinnerId, pendingGameWinnerId) || other.pendingGameWinnerId == pendingGameWinnerId));
}


@override
int get hashCode => Object.hash(runtimeType,gameState,pendingGameWinnerId);

@override
String toString() {
  return 'ActiveCountUpState(gameState: $gameState, pendingGameWinnerId: $pendingGameWinnerId)';
}


}

/// @nodoc
abstract mixin class $ActiveCountUpStateCopyWith<$Res>  {
  factory $ActiveCountUpStateCopyWith(ActiveCountUpState value, $Res Function(ActiveCountUpState) _then) = _$ActiveCountUpStateCopyWithImpl;
@useResult
$Res call({
 GameState gameState, String? pendingGameWinnerId
});


$GameStateCopyWith<$Res> get gameState;

}
/// @nodoc
class _$ActiveCountUpStateCopyWithImpl<$Res>
    implements $ActiveCountUpStateCopyWith<$Res> {
  _$ActiveCountUpStateCopyWithImpl(this._self, this._then);

  final ActiveCountUpState _self;
  final $Res Function(ActiveCountUpState) _then;

/// Create a copy of ActiveCountUpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameState = null,Object? pendingGameWinnerId = freezed,}) {
  return _then(_self.copyWith(
gameState: null == gameState ? _self.gameState : gameState // ignore: cast_nullable_to_non_nullable
as GameState,pendingGameWinnerId: freezed == pendingGameWinnerId ? _self.pendingGameWinnerId : pendingGameWinnerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ActiveCountUpState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStateCopyWith<$Res> get gameState {
  
  return $GameStateCopyWith<$Res>(_self.gameState, (value) {
    return _then(_self.copyWith(gameState: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActiveCountUpState].
extension ActiveCountUpStatePatterns on ActiveCountUpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveCountUpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveCountUpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveCountUpState value)  $default,){
final _that = this;
switch (_that) {
case _ActiveCountUpState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveCountUpState value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveCountUpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameState gameState,  String? pendingGameWinnerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveCountUpState() when $default != null:
return $default(_that.gameState,_that.pendingGameWinnerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameState gameState,  String? pendingGameWinnerId)  $default,) {final _that = this;
switch (_that) {
case _ActiveCountUpState():
return $default(_that.gameState,_that.pendingGameWinnerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameState gameState,  String? pendingGameWinnerId)?  $default,) {final _that = this;
switch (_that) {
case _ActiveCountUpState() when $default != null:
return $default(_that.gameState,_that.pendingGameWinnerId);case _:
  return null;

}
}

}

/// @nodoc


class _ActiveCountUpState implements ActiveCountUpState {
  const _ActiveCountUpState({required this.gameState, this.pendingGameWinnerId});
  

@override final  GameState gameState;
@override final  String? pendingGameWinnerId;

/// Create a copy of ActiveCountUpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveCountUpStateCopyWith<_ActiveCountUpState> get copyWith => __$ActiveCountUpStateCopyWithImpl<_ActiveCountUpState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveCountUpState&&(identical(other.gameState, gameState) || other.gameState == gameState)&&(identical(other.pendingGameWinnerId, pendingGameWinnerId) || other.pendingGameWinnerId == pendingGameWinnerId));
}


@override
int get hashCode => Object.hash(runtimeType,gameState,pendingGameWinnerId);

@override
String toString() {
  return 'ActiveCountUpState(gameState: $gameState, pendingGameWinnerId: $pendingGameWinnerId)';
}


}

/// @nodoc
abstract mixin class _$ActiveCountUpStateCopyWith<$Res> implements $ActiveCountUpStateCopyWith<$Res> {
  factory _$ActiveCountUpStateCopyWith(_ActiveCountUpState value, $Res Function(_ActiveCountUpState) _then) = __$ActiveCountUpStateCopyWithImpl;
@override @useResult
$Res call({
 GameState gameState, String? pendingGameWinnerId
});


@override $GameStateCopyWith<$Res> get gameState;

}
/// @nodoc
class __$ActiveCountUpStateCopyWithImpl<$Res>
    implements _$ActiveCountUpStateCopyWith<$Res> {
  __$ActiveCountUpStateCopyWithImpl(this._self, this._then);

  final _ActiveCountUpState _self;
  final $Res Function(_ActiveCountUpState) _then;

/// Create a copy of ActiveCountUpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameState = null,Object? pendingGameWinnerId = freezed,}) {
  return _then(_ActiveCountUpState(
gameState: null == gameState ? _self.gameState : gameState // ignore: cast_nullable_to_non_nullable
as GameState,pendingGameWinnerId: freezed == pendingGameWinnerId ? _self.pendingGameWinnerId : pendingGameWinnerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ActiveCountUpState
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
