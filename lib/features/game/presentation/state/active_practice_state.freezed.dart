// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_practice_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActivePracticeState {

 GameState get gameState; String? get pendingGameWinnerId; bool get showShanghaiBonus;/// Transient flag set true on the dart that busted in Catch 40 (#325).
/// The board page listens for the false→true transition to flash a
/// BUST snackbar; the next dart (or `dismissBust`) clears it. Only
/// Catch 40 currently emits this — other practice modes either
/// can't bust (ATC) or already handle their own busts (X01 in
/// `ActiveGameState`).
 bool get showBust;/// `true` while the currently-displayed turn busted (Checkout Practice:
/// a dart that overshot, reverting the score). Unlike [showBust] (a
/// transient snackbar trigger that's dismissed after the flash), this
/// persists for the whole displayed turn so the status-bar turn-points
/// readout can show 0 instead of the raw busted-dart sum (#604). Reset to
/// false when the next turn starts (every construction site rebuilds via
/// the constructor, defaulting it back).
 bool get turnBusted;/// Set to `true` when `EndPracticeUseCase` was invoked via the
/// "End Drill" menu (i.e. the user manually ended the drill). Both
/// natural completion and manual end now route to the post-game
/// summary (#289/#291); the flag stays so the completion listener in
/// `practice_board_page` can skip its own navigation when the menu
/// handler is already going to navigate explicitly — preventing a
/// double-nav race.
 bool get wasEndedManually;
/// Create a copy of ActivePracticeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivePracticeStateCopyWith<ActivePracticeState> get copyWith => _$ActivePracticeStateCopyWithImpl<ActivePracticeState>(this as ActivePracticeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivePracticeState&&(identical(other.gameState, gameState) || other.gameState == gameState)&&(identical(other.pendingGameWinnerId, pendingGameWinnerId) || other.pendingGameWinnerId == pendingGameWinnerId)&&(identical(other.showShanghaiBonus, showShanghaiBonus) || other.showShanghaiBonus == showShanghaiBonus)&&(identical(other.showBust, showBust) || other.showBust == showBust)&&(identical(other.turnBusted, turnBusted) || other.turnBusted == turnBusted)&&(identical(other.wasEndedManually, wasEndedManually) || other.wasEndedManually == wasEndedManually));
}


@override
int get hashCode => Object.hash(runtimeType,gameState,pendingGameWinnerId,showShanghaiBonus,showBust,turnBusted,wasEndedManually);

@override
String toString() {
  return 'ActivePracticeState(gameState: $gameState, pendingGameWinnerId: $pendingGameWinnerId, showShanghaiBonus: $showShanghaiBonus, showBust: $showBust, turnBusted: $turnBusted, wasEndedManually: $wasEndedManually)';
}


}

/// @nodoc
abstract mixin class $ActivePracticeStateCopyWith<$Res>  {
  factory $ActivePracticeStateCopyWith(ActivePracticeState value, $Res Function(ActivePracticeState) _then) = _$ActivePracticeStateCopyWithImpl;
@useResult
$Res call({
 GameState gameState, String? pendingGameWinnerId, bool showShanghaiBonus, bool showBust, bool turnBusted, bool wasEndedManually
});


$GameStateCopyWith<$Res> get gameState;

}
/// @nodoc
class _$ActivePracticeStateCopyWithImpl<$Res>
    implements $ActivePracticeStateCopyWith<$Res> {
  _$ActivePracticeStateCopyWithImpl(this._self, this._then);

  final ActivePracticeState _self;
  final $Res Function(ActivePracticeState) _then;

/// Create a copy of ActivePracticeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameState = null,Object? pendingGameWinnerId = freezed,Object? showShanghaiBonus = null,Object? showBust = null,Object? turnBusted = null,Object? wasEndedManually = null,}) {
  return _then(_self.copyWith(
gameState: null == gameState ? _self.gameState : gameState // ignore: cast_nullable_to_non_nullable
as GameState,pendingGameWinnerId: freezed == pendingGameWinnerId ? _self.pendingGameWinnerId : pendingGameWinnerId // ignore: cast_nullable_to_non_nullable
as String?,showShanghaiBonus: null == showShanghaiBonus ? _self.showShanghaiBonus : showShanghaiBonus // ignore: cast_nullable_to_non_nullable
as bool,showBust: null == showBust ? _self.showBust : showBust // ignore: cast_nullable_to_non_nullable
as bool,turnBusted: null == turnBusted ? _self.turnBusted : turnBusted // ignore: cast_nullable_to_non_nullable
as bool,wasEndedManually: null == wasEndedManually ? _self.wasEndedManually : wasEndedManually // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ActivePracticeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStateCopyWith<$Res> get gameState {
  
  return $GameStateCopyWith<$Res>(_self.gameState, (value) {
    return _then(_self.copyWith(gameState: value));
  });
}
}


/// Adds pattern-matching-related methods to [ActivePracticeState].
extension ActivePracticeStatePatterns on ActivePracticeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivePracticeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivePracticeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivePracticeState value)  $default,){
final _that = this;
switch (_that) {
case _ActivePracticeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivePracticeState value)?  $default,){
final _that = this;
switch (_that) {
case _ActivePracticeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameState gameState,  String? pendingGameWinnerId,  bool showShanghaiBonus,  bool showBust,  bool turnBusted,  bool wasEndedManually)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivePracticeState() when $default != null:
return $default(_that.gameState,_that.pendingGameWinnerId,_that.showShanghaiBonus,_that.showBust,_that.turnBusted,_that.wasEndedManually);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameState gameState,  String? pendingGameWinnerId,  bool showShanghaiBonus,  bool showBust,  bool turnBusted,  bool wasEndedManually)  $default,) {final _that = this;
switch (_that) {
case _ActivePracticeState():
return $default(_that.gameState,_that.pendingGameWinnerId,_that.showShanghaiBonus,_that.showBust,_that.turnBusted,_that.wasEndedManually);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameState gameState,  String? pendingGameWinnerId,  bool showShanghaiBonus,  bool showBust,  bool turnBusted,  bool wasEndedManually)?  $default,) {final _that = this;
switch (_that) {
case _ActivePracticeState() when $default != null:
return $default(_that.gameState,_that.pendingGameWinnerId,_that.showShanghaiBonus,_that.showBust,_that.turnBusted,_that.wasEndedManually);case _:
  return null;

}
}

}

/// @nodoc


class _ActivePracticeState implements ActivePracticeState {
  const _ActivePracticeState({required this.gameState, this.pendingGameWinnerId, this.showShanghaiBonus = false, this.showBust = false, this.turnBusted = false, this.wasEndedManually = false});
  

@override final  GameState gameState;
@override final  String? pendingGameWinnerId;
@override@JsonKey() final  bool showShanghaiBonus;
/// Transient flag set true on the dart that busted in Catch 40 (#325).
/// The board page listens for the false→true transition to flash a
/// BUST snackbar; the next dart (or `dismissBust`) clears it. Only
/// Catch 40 currently emits this — other practice modes either
/// can't bust (ATC) or already handle their own busts (X01 in
/// `ActiveGameState`).
@override@JsonKey() final  bool showBust;
/// `true` while the currently-displayed turn busted (Checkout Practice:
/// a dart that overshot, reverting the score). Unlike [showBust] (a
/// transient snackbar trigger that's dismissed after the flash), this
/// persists for the whole displayed turn so the status-bar turn-points
/// readout can show 0 instead of the raw busted-dart sum (#604). Reset to
/// false when the next turn starts (every construction site rebuilds via
/// the constructor, defaulting it back).
@override@JsonKey() final  bool turnBusted;
/// Set to `true` when `EndPracticeUseCase` was invoked via the
/// "End Drill" menu (i.e. the user manually ended the drill). Both
/// natural completion and manual end now route to the post-game
/// summary (#289/#291); the flag stays so the completion listener in
/// `practice_board_page` can skip its own navigation when the menu
/// handler is already going to navigate explicitly — preventing a
/// double-nav race.
@override@JsonKey() final  bool wasEndedManually;

/// Create a copy of ActivePracticeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivePracticeStateCopyWith<_ActivePracticeState> get copyWith => __$ActivePracticeStateCopyWithImpl<_ActivePracticeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivePracticeState&&(identical(other.gameState, gameState) || other.gameState == gameState)&&(identical(other.pendingGameWinnerId, pendingGameWinnerId) || other.pendingGameWinnerId == pendingGameWinnerId)&&(identical(other.showShanghaiBonus, showShanghaiBonus) || other.showShanghaiBonus == showShanghaiBonus)&&(identical(other.showBust, showBust) || other.showBust == showBust)&&(identical(other.turnBusted, turnBusted) || other.turnBusted == turnBusted)&&(identical(other.wasEndedManually, wasEndedManually) || other.wasEndedManually == wasEndedManually));
}


@override
int get hashCode => Object.hash(runtimeType,gameState,pendingGameWinnerId,showShanghaiBonus,showBust,turnBusted,wasEndedManually);

@override
String toString() {
  return 'ActivePracticeState(gameState: $gameState, pendingGameWinnerId: $pendingGameWinnerId, showShanghaiBonus: $showShanghaiBonus, showBust: $showBust, turnBusted: $turnBusted, wasEndedManually: $wasEndedManually)';
}


}

/// @nodoc
abstract mixin class _$ActivePracticeStateCopyWith<$Res> implements $ActivePracticeStateCopyWith<$Res> {
  factory _$ActivePracticeStateCopyWith(_ActivePracticeState value, $Res Function(_ActivePracticeState) _then) = __$ActivePracticeStateCopyWithImpl;
@override @useResult
$Res call({
 GameState gameState, String? pendingGameWinnerId, bool showShanghaiBonus, bool showBust, bool turnBusted, bool wasEndedManually
});


@override $GameStateCopyWith<$Res> get gameState;

}
/// @nodoc
class __$ActivePracticeStateCopyWithImpl<$Res>
    implements _$ActivePracticeStateCopyWith<$Res> {
  __$ActivePracticeStateCopyWithImpl(this._self, this._then);

  final _ActivePracticeState _self;
  final $Res Function(_ActivePracticeState) _then;

/// Create a copy of ActivePracticeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameState = null,Object? pendingGameWinnerId = freezed,Object? showShanghaiBonus = null,Object? showBust = null,Object? turnBusted = null,Object? wasEndedManually = null,}) {
  return _then(_ActivePracticeState(
gameState: null == gameState ? _self.gameState : gameState // ignore: cast_nullable_to_non_nullable
as GameState,pendingGameWinnerId: freezed == pendingGameWinnerId ? _self.pendingGameWinnerId : pendingGameWinnerId // ignore: cast_nullable_to_non_nullable
as String?,showShanghaiBonus: null == showShanghaiBonus ? _self.showShanghaiBonus : showShanghaiBonus // ignore: cast_nullable_to_non_nullable
as bool,showBust: null == showBust ? _self.showBust : showBust // ignore: cast_nullable_to_non_nullable
as bool,turnBusted: null == turnBusted ? _self.turnBusted : turnBusted // ignore: cast_nullable_to_non_nullable
as bool,wasEndedManually: null == wasEndedManually ? _self.wasEndedManually : wasEndedManually // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ActivePracticeState
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
