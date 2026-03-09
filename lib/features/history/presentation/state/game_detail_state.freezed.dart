// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameDetailState {

 Game? get game; List<Competitor> get competitors; List<GameEvent> get events; List<DartThrow> get darts; GameStats? get gameStats;
/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameDetailStateCopyWith<GameDetailState> get copyWith => _$GameDetailStateCopyWithImpl<GameDetailState>(this as GameDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameDetailState&&(identical(other.game, game) || other.game == game)&&const DeepCollectionEquality().equals(other.competitors, competitors)&&const DeepCollectionEquality().equals(other.events, events)&&const DeepCollectionEquality().equals(other.darts, darts)&&(identical(other.gameStats, gameStats) || other.gameStats == gameStats));
}


@override
int get hashCode => Object.hash(runtimeType,game,const DeepCollectionEquality().hash(competitors),const DeepCollectionEquality().hash(events),const DeepCollectionEquality().hash(darts),gameStats);

@override
String toString() {
  return 'GameDetailState(game: $game, competitors: $competitors, events: $events, darts: $darts, gameStats: $gameStats)';
}


}

/// @nodoc
abstract mixin class $GameDetailStateCopyWith<$Res>  {
  factory $GameDetailStateCopyWith(GameDetailState value, $Res Function(GameDetailState) _then) = _$GameDetailStateCopyWithImpl;
@useResult
$Res call({
 Game? game, List<Competitor> competitors, List<GameEvent> events, List<DartThrow> darts, GameStats? gameStats
});


$GameCopyWith<$Res>? get game;$GameStatsCopyWith<$Res>? get gameStats;

}
/// @nodoc
class _$GameDetailStateCopyWithImpl<$Res>
    implements $GameDetailStateCopyWith<$Res> {
  _$GameDetailStateCopyWithImpl(this._self, this._then);

  final GameDetailState _self;
  final $Res Function(GameDetailState) _then;

/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? game = freezed,Object? competitors = null,Object? events = null,Object? darts = null,Object? gameStats = freezed,}) {
  return _then(_self.copyWith(
game: freezed == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as Game?,competitors: null == competitors ? _self.competitors : competitors // ignore: cast_nullable_to_non_nullable
as List<Competitor>,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,darts: null == darts ? _self.darts : darts // ignore: cast_nullable_to_non_nullable
as List<DartThrow>,gameStats: freezed == gameStats ? _self.gameStats : gameStats // ignore: cast_nullable_to_non_nullable
as GameStats?,
  ));
}
/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameCopyWith<$Res>? get game {
    if (_self.game == null) {
    return null;
  }

  return $GameCopyWith<$Res>(_self.game!, (value) {
    return _then(_self.copyWith(game: value));
  });
}/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStatsCopyWith<$Res>? get gameStats {
    if (_self.gameStats == null) {
    return null;
  }

  return $GameStatsCopyWith<$Res>(_self.gameStats!, (value) {
    return _then(_self.copyWith(gameStats: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameDetailState].
extension GameDetailStatePatterns on GameDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameDetailState value)  $default,){
final _that = this;
switch (_that) {
case _GameDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _GameDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Game? game,  List<Competitor> competitors,  List<GameEvent> events,  List<DartThrow> darts,  GameStats? gameStats)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameDetailState() when $default != null:
return $default(_that.game,_that.competitors,_that.events,_that.darts,_that.gameStats);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Game? game,  List<Competitor> competitors,  List<GameEvent> events,  List<DartThrow> darts,  GameStats? gameStats)  $default,) {final _that = this;
switch (_that) {
case _GameDetailState():
return $default(_that.game,_that.competitors,_that.events,_that.darts,_that.gameStats);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Game? game,  List<Competitor> competitors,  List<GameEvent> events,  List<DartThrow> darts,  GameStats? gameStats)?  $default,) {final _that = this;
switch (_that) {
case _GameDetailState() when $default != null:
return $default(_that.game,_that.competitors,_that.events,_that.darts,_that.gameStats);case _:
  return null;

}
}

}

/// @nodoc


class _GameDetailState implements GameDetailState {
  const _GameDetailState({this.game, final  List<Competitor> competitors = const <Competitor>[], final  List<GameEvent> events = const <GameEvent>[], final  List<DartThrow> darts = const <DartThrow>[], this.gameStats}): _competitors = competitors,_events = events,_darts = darts;
  

@override final  Game? game;
 final  List<Competitor> _competitors;
@override@JsonKey() List<Competitor> get competitors {
  if (_competitors is EqualUnmodifiableListView) return _competitors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_competitors);
}

 final  List<GameEvent> _events;
@override@JsonKey() List<GameEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

 final  List<DartThrow> _darts;
@override@JsonKey() List<DartThrow> get darts {
  if (_darts is EqualUnmodifiableListView) return _darts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_darts);
}

@override final  GameStats? gameStats;

/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameDetailStateCopyWith<_GameDetailState> get copyWith => __$GameDetailStateCopyWithImpl<_GameDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameDetailState&&(identical(other.game, game) || other.game == game)&&const DeepCollectionEquality().equals(other._competitors, _competitors)&&const DeepCollectionEquality().equals(other._events, _events)&&const DeepCollectionEquality().equals(other._darts, _darts)&&(identical(other.gameStats, gameStats) || other.gameStats == gameStats));
}


@override
int get hashCode => Object.hash(runtimeType,game,const DeepCollectionEquality().hash(_competitors),const DeepCollectionEquality().hash(_events),const DeepCollectionEquality().hash(_darts),gameStats);

@override
String toString() {
  return 'GameDetailState(game: $game, competitors: $competitors, events: $events, darts: $darts, gameStats: $gameStats)';
}


}

/// @nodoc
abstract mixin class _$GameDetailStateCopyWith<$Res> implements $GameDetailStateCopyWith<$Res> {
  factory _$GameDetailStateCopyWith(_GameDetailState value, $Res Function(_GameDetailState) _then) = __$GameDetailStateCopyWithImpl;
@override @useResult
$Res call({
 Game? game, List<Competitor> competitors, List<GameEvent> events, List<DartThrow> darts, GameStats? gameStats
});


@override $GameCopyWith<$Res>? get game;@override $GameStatsCopyWith<$Res>? get gameStats;

}
/// @nodoc
class __$GameDetailStateCopyWithImpl<$Res>
    implements _$GameDetailStateCopyWith<$Res> {
  __$GameDetailStateCopyWithImpl(this._self, this._then);

  final _GameDetailState _self;
  final $Res Function(_GameDetailState) _then;

/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? game = freezed,Object? competitors = null,Object? events = null,Object? darts = null,Object? gameStats = freezed,}) {
  return _then(_GameDetailState(
game: freezed == game ? _self.game : game // ignore: cast_nullable_to_non_nullable
as Game?,competitors: null == competitors ? _self._competitors : competitors // ignore: cast_nullable_to_non_nullable
as List<Competitor>,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<GameEvent>,darts: null == darts ? _self._darts : darts // ignore: cast_nullable_to_non_nullable
as List<DartThrow>,gameStats: freezed == gameStats ? _self.gameStats : gameStats // ignore: cast_nullable_to_non_nullable
as GameStats?,
  ));
}

/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameCopyWith<$Res>? get game {
    if (_self.game == null) {
    return null;
  }

  return $GameCopyWith<$Res>(_self.game!, (value) {
    return _then(_self.copyWith(game: value));
  });
}/// Create a copy of GameDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameStatsCopyWith<$Res>? get gameStats {
    if (_self.gameStats == null) {
    return null;
  }

  return $GameStatsCopyWith<$Res>(_self.gameStats!, (value) {
    return _then(_self.copyWith(gameStats: value));
  });
}
}

// dart format on
