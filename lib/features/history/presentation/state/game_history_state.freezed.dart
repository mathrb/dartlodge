// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_history_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameHistoryState {

 List<Game> get games; Map<String, List<Competitor>> get competitorsByGameId; bool get isLoadingMore; bool get hasMore; GameType? get filterGameType; DateTime? get filterDateFrom; DateTime? get filterDateTo;
/// Create a copy of GameHistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameHistoryStateCopyWith<GameHistoryState> get copyWith => _$GameHistoryStateCopyWithImpl<GameHistoryState>(this as GameHistoryState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameHistoryState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameHistoryState&&const DeepCollectionEquality().equals(other.games, _this.games)&&const DeepCollectionEquality().equals(other.competitorsByGameId, _this.competitorsByGameId)&&(identical(other.isLoadingMore, _this.isLoadingMore) || other.isLoadingMore == _this.isLoadingMore)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.filterGameType, _this.filterGameType) || other.filterGameType == _this.filterGameType)&&(identical(other.filterDateFrom, _this.filterDateFrom) || other.filterDateFrom == _this.filterDateFrom)&&(identical(other.filterDateTo, _this.filterDateTo) || other.filterDateTo == _this.filterDateTo));
}


@override
int get hashCode {
  final _this = this as GameHistoryState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.games),const DeepCollectionEquality().hash(_this.competitorsByGameId),_this.isLoadingMore,_this.hasMore,_this.filterGameType,_this.filterDateFrom,_this.filterDateTo);
}

@override
String toString() {
  final _this = this as GameHistoryState;
  return 'GameHistoryState(games: ${_this.games}, competitorsByGameId: ${_this.competitorsByGameId}, isLoadingMore: ${_this.isLoadingMore}, hasMore: ${_this.hasMore}, filterGameType: ${_this.filterGameType}, filterDateFrom: ${_this.filterDateFrom}, filterDateTo: ${_this.filterDateTo})';
}


}

/// @nodoc
abstract mixin class $GameHistoryStateCopyWith<$Res>  {
  factory $GameHistoryStateCopyWith(GameHistoryState value, $Res Function(GameHistoryState) _then) = _$GameHistoryStateCopyWithImpl;
@useResult
$Res call({
 List<Game> games, Map<String, List<Competitor>> competitorsByGameId, bool isLoadingMore, bool hasMore, GameType? filterGameType, DateTime? filterDateFrom, DateTime? filterDateTo
});




}
/// @nodoc
class _$GameHistoryStateCopyWithImpl<$Res>
    implements $GameHistoryStateCopyWith<$Res> {
  _$GameHistoryStateCopyWithImpl(this._self, this._then);

  final GameHistoryState _self;
  final $Res Function(GameHistoryState) _then;

/// Create a copy of GameHistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? games = null,Object? competitorsByGameId = null,Object? isLoadingMore = null,Object? hasMore = null,Object? filterGameType = freezed,Object? filterDateFrom = freezed,Object? filterDateTo = freezed,}) {
  return _then(GameHistoryState(
games: null == games ? _self.games : games // ignore: cast_nullable_to_non_nullable
as List<Game>,competitorsByGameId: null == competitorsByGameId ? _self.competitorsByGameId : competitorsByGameId // ignore: cast_nullable_to_non_nullable
as Map<String, List<Competitor>>,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,filterGameType: freezed == filterGameType ? _self.filterGameType : filterGameType // ignore: cast_nullable_to_non_nullable
as GameType?,filterDateFrom: freezed == filterDateFrom ? _self.filterDateFrom : filterDateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,filterDateTo: freezed == filterDateTo ? _self.filterDateTo : filterDateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameHistoryState].
extension GameHistoryStatePatterns on GameHistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameHistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameHistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameHistoryState value)  $default,){
final _that = this;
switch (_that) {
case _GameHistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameHistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _GameHistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Game> games,  Map<String, List<Competitor>> competitorsByGameId,  bool isLoadingMore,  bool hasMore,  GameType? filterGameType,  DateTime? filterDateFrom,  DateTime? filterDateTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameHistoryState() when $default != null:
return $default(_that.games,_that.competitorsByGameId,_that.isLoadingMore,_that.hasMore,_that.filterGameType,_that.filterDateFrom,_that.filterDateTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Game> games,  Map<String, List<Competitor>> competitorsByGameId,  bool isLoadingMore,  bool hasMore,  GameType? filterGameType,  DateTime? filterDateFrom,  DateTime? filterDateTo)  $default,) {final _that = this;
switch (_that) {
case _GameHistoryState():
return $default(_that.games,_that.competitorsByGameId,_that.isLoadingMore,_that.hasMore,_that.filterGameType,_that.filterDateFrom,_that.filterDateTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Game> games,  Map<String, List<Competitor>> competitorsByGameId,  bool isLoadingMore,  bool hasMore,  GameType? filterGameType,  DateTime? filterDateFrom,  DateTime? filterDateTo)?  $default,) {final _that = this;
switch (_that) {
case _GameHistoryState() when $default != null:
return $default(_that.games,_that.competitorsByGameId,_that.isLoadingMore,_that.hasMore,_that.filterGameType,_that.filterDateFrom,_that.filterDateTo);case _:
  return null;

}
}

}

/// @nodoc


class _GameHistoryState implements GameHistoryState {
  const _GameHistoryState({ List<Game> games = const <Game>[],  Map<String, List<Competitor>> competitorsByGameId = const <String, List<Competitor>>{}, this.isLoadingMore = false, this.hasMore = true, this.filterGameType, this.filterDateFrom, this.filterDateTo}): _games = games,_competitorsByGameId = competitorsByGameId;
  

 final  List<Game> _games;
@override@JsonKey() List<Game> get games {
  if (_games is EqualUnmodifiableListView) return _games;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_games);
}

 final  Map<String, List<Competitor>> _competitorsByGameId;
@override@JsonKey() Map<String, List<Competitor>> get competitorsByGameId {
  if (_competitorsByGameId is EqualUnmodifiableMapView) return _competitorsByGameId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_competitorsByGameId);
}

@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool hasMore;
@override final  GameType? filterGameType;
@override final  DateTime? filterDateFrom;
@override final  DateTime? filterDateTo;

/// Create a copy of GameHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameHistoryStateCopyWith<_GameHistoryState> get copyWith => __$GameHistoryStateCopyWithImpl<_GameHistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameHistoryState&&const DeepCollectionEquality().equals(other.games, _games)&&const DeepCollectionEquality().equals(other.competitorsByGameId, _competitorsByGameId)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.filterGameType, filterGameType) || other.filterGameType == filterGameType)&&(identical(other.filterDateFrom, filterDateFrom) || other.filterDateFrom == filterDateFrom)&&(identical(other.filterDateTo, filterDateTo) || other.filterDateTo == filterDateTo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_games),const DeepCollectionEquality().hash(_competitorsByGameId),isLoadingMore,hasMore,filterGameType,filterDateFrom,filterDateTo);
}

@override
String toString() {
    return 'GameHistoryState(games: $games, competitorsByGameId: $competitorsByGameId, isLoadingMore: $isLoadingMore, hasMore: $hasMore, filterGameType: $filterGameType, filterDateFrom: $filterDateFrom, filterDateTo: $filterDateTo)';
}


}

/// @nodoc
abstract mixin class _$GameHistoryStateCopyWith<$Res> implements $GameHistoryStateCopyWith<$Res> {
  factory _$GameHistoryStateCopyWith(_GameHistoryState value, $Res Function(_GameHistoryState) _then) = __$GameHistoryStateCopyWithImpl;
@override @useResult
$Res call({
 List<Game> games, Map<String, List<Competitor>> competitorsByGameId, bool isLoadingMore, bool hasMore, GameType? filterGameType, DateTime? filterDateFrom, DateTime? filterDateTo
});




}
/// @nodoc
class __$GameHistoryStateCopyWithImpl<$Res>
    implements _$GameHistoryStateCopyWith<$Res> {
  __$GameHistoryStateCopyWithImpl(this._self, this._then);

  final _GameHistoryState _self;
  final $Res Function(_GameHistoryState) _then;

/// Create a copy of GameHistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? games = null,Object? competitorsByGameId = null,Object? isLoadingMore = null,Object? hasMore = null,Object? filterGameType = freezed,Object? filterDateFrom = freezed,Object? filterDateTo = freezed,}) {
  return _then(_GameHistoryState(
games: null == games ? _self._games : games // ignore: cast_nullable_to_non_nullable
as List<Game>,competitorsByGameId: null == competitorsByGameId ? _self._competitorsByGameId : competitorsByGameId // ignore: cast_nullable_to_non_nullable
as Map<String, List<Competitor>>,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,filterGameType: freezed == filterGameType ? _self.filterGameType : filterGameType // ignore: cast_nullable_to_non_nullable
as GameType?,filterDateFrom: freezed == filterDateFrom ? _self.filterDateFrom : filterDateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,filterDateTo: freezed == filterDateTo ? _self.filterDateTo : filterDateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
