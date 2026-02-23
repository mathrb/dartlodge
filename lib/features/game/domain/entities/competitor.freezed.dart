// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'competitor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Competitor {

@JsonKey(name: 'competitor_id') String get competitorId;@JsonKey(name: 'game_id') String get gameId;@JsonKey(name: 'type') CompetitorType get type;@JsonKey(name: 'name') String get name;@JsonKey(name: 'players') List<CompetitorPlayer> get players;
/// Create a copy of Competitor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompetitorCopyWith<Competitor> get copyWith => _$CompetitorCopyWithImpl<Competitor>(this as Competitor, _$identity);

  /// Serializes this Competitor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Competitor&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.players, players));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,gameId,type,name,const DeepCollectionEquality().hash(players));

@override
String toString() {
  return 'Competitor(competitorId: $competitorId, gameId: $gameId, type: $type, name: $name, players: $players)';
}


}

/// @nodoc
abstract mixin class $CompetitorCopyWith<$Res>  {
  factory $CompetitorCopyWith(Competitor value, $Res Function(Competitor) _then) = _$CompetitorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'competitor_id') String competitorId,@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'type') CompetitorType type,@JsonKey(name: 'name') String name,@JsonKey(name: 'players') List<CompetitorPlayer> players
});




}
/// @nodoc
class _$CompetitorCopyWithImpl<$Res>
    implements $CompetitorCopyWith<$Res> {
  _$CompetitorCopyWithImpl(this._self, this._then);

  final Competitor _self;
  final $Res Function(Competitor) _then;

/// Create a copy of Competitor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competitorId = null,Object? gameId = null,Object? type = null,Object? name = null,Object? players = null,}) {
  return _then(_self.copyWith(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CompetitorType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,players: null == players ? _self.players : players // ignore: cast_nullable_to_non_nullable
as List<CompetitorPlayer>,
  ));
}

}


/// Adds pattern-matching-related methods to [Competitor].
extension CompetitorPatterns on Competitor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Competitor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Competitor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Competitor value)  $default,){
final _that = this;
switch (_that) {
case _Competitor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Competitor value)?  $default,){
final _that = this;
switch (_that) {
case _Competitor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'competitor_id')  String competitorId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'type')  CompetitorType type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'players')  List<CompetitorPlayer> players)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Competitor() when $default != null:
return $default(_that.competitorId,_that.gameId,_that.type,_that.name,_that.players);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'competitor_id')  String competitorId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'type')  CompetitorType type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'players')  List<CompetitorPlayer> players)  $default,) {final _that = this;
switch (_that) {
case _Competitor():
return $default(_that.competitorId,_that.gameId,_that.type,_that.name,_that.players);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'competitor_id')  String competitorId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'type')  CompetitorType type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'players')  List<CompetitorPlayer> players)?  $default,) {final _that = this;
switch (_that) {
case _Competitor() when $default != null:
return $default(_that.competitorId,_that.gameId,_that.type,_that.name,_that.players);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Competitor implements Competitor {
  const _Competitor({@JsonKey(name: 'competitor_id') required this.competitorId, @JsonKey(name: 'game_id') required this.gameId, @JsonKey(name: 'type') required this.type, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'players') required final  List<CompetitorPlayer> players}): _players = players;
  factory _Competitor.fromJson(Map<String, dynamic> json) => _$CompetitorFromJson(json);

@override@JsonKey(name: 'competitor_id') final  String competitorId;
@override@JsonKey(name: 'game_id') final  String gameId;
@override@JsonKey(name: 'type') final  CompetitorType type;
@override@JsonKey(name: 'name') final  String name;
 final  List<CompetitorPlayer> _players;
@override@JsonKey(name: 'players') List<CompetitorPlayer> get players {
  if (_players is EqualUnmodifiableListView) return _players;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_players);
}


/// Create a copy of Competitor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompetitorCopyWith<_Competitor> get copyWith => __$CompetitorCopyWithImpl<_Competitor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompetitorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Competitor&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._players, _players));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,gameId,type,name,const DeepCollectionEquality().hash(_players));

@override
String toString() {
  return 'Competitor(competitorId: $competitorId, gameId: $gameId, type: $type, name: $name, players: $players)';
}


}

/// @nodoc
abstract mixin class _$CompetitorCopyWith<$Res> implements $CompetitorCopyWith<$Res> {
  factory _$CompetitorCopyWith(_Competitor value, $Res Function(_Competitor) _then) = __$CompetitorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'competitor_id') String competitorId,@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'type') CompetitorType type,@JsonKey(name: 'name') String name,@JsonKey(name: 'players') List<CompetitorPlayer> players
});




}
/// @nodoc
class __$CompetitorCopyWithImpl<$Res>
    implements _$CompetitorCopyWith<$Res> {
  __$CompetitorCopyWithImpl(this._self, this._then);

  final _Competitor _self;
  final $Res Function(_Competitor) _then;

/// Create a copy of Competitor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorId = null,Object? gameId = null,Object? type = null,Object? name = null,Object? players = null,}) {
  return _then(_Competitor(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CompetitorType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,players: null == players ? _self._players : players // ignore: cast_nullable_to_non_nullable
as List<CompetitorPlayer>,
  ));
}


}


/// @nodoc
mixin _$CompetitorPlayer {

@JsonKey(name: 'player_id') String get playerId;@JsonKey(name: 'rotation_position') int get rotationPosition;
/// Create a copy of CompetitorPlayer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompetitorPlayerCopyWith<CompetitorPlayer> get copyWith => _$CompetitorPlayerCopyWithImpl<CompetitorPlayer>(this as CompetitorPlayer, _$identity);

  /// Serializes this CompetitorPlayer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompetitorPlayer&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.rotationPosition, rotationPosition) || other.rotationPosition == rotationPosition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,rotationPosition);

@override
String toString() {
  return 'CompetitorPlayer(playerId: $playerId, rotationPosition: $rotationPosition)';
}


}

/// @nodoc
abstract mixin class $CompetitorPlayerCopyWith<$Res>  {
  factory $CompetitorPlayerCopyWith(CompetitorPlayer value, $Res Function(CompetitorPlayer) _then) = _$CompetitorPlayerCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'rotation_position') int rotationPosition
});




}
/// @nodoc
class _$CompetitorPlayerCopyWithImpl<$Res>
    implements $CompetitorPlayerCopyWith<$Res> {
  _$CompetitorPlayerCopyWithImpl(this._self, this._then);

  final CompetitorPlayer _self;
  final $Res Function(CompetitorPlayer) _then;

/// Create a copy of CompetitorPlayer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? rotationPosition = null,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,rotationPosition: null == rotationPosition ? _self.rotationPosition : rotationPosition // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CompetitorPlayer].
extension CompetitorPlayerPatterns on CompetitorPlayer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompetitorPlayer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompetitorPlayer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompetitorPlayer value)  $default,){
final _that = this;
switch (_that) {
case _CompetitorPlayer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompetitorPlayer value)?  $default,){
final _that = this;
switch (_that) {
case _CompetitorPlayer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'rotation_position')  int rotationPosition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompetitorPlayer() when $default != null:
return $default(_that.playerId,_that.rotationPosition);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'rotation_position')  int rotationPosition)  $default,) {final _that = this;
switch (_that) {
case _CompetitorPlayer():
return $default(_that.playerId,_that.rotationPosition);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'player_id')  String playerId, @JsonKey(name: 'rotation_position')  int rotationPosition)?  $default,) {final _that = this;
switch (_that) {
case _CompetitorPlayer() when $default != null:
return $default(_that.playerId,_that.rotationPosition);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompetitorPlayer implements CompetitorPlayer {
  const _CompetitorPlayer({@JsonKey(name: 'player_id') required this.playerId, @JsonKey(name: 'rotation_position') required this.rotationPosition});
  factory _CompetitorPlayer.fromJson(Map<String, dynamic> json) => _$CompetitorPlayerFromJson(json);

@override@JsonKey(name: 'player_id') final  String playerId;
@override@JsonKey(name: 'rotation_position') final  int rotationPosition;

/// Create a copy of CompetitorPlayer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompetitorPlayerCopyWith<_CompetitorPlayer> get copyWith => __$CompetitorPlayerCopyWithImpl<_CompetitorPlayer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompetitorPlayerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompetitorPlayer&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.rotationPosition, rotationPosition) || other.rotationPosition == rotationPosition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,playerId,rotationPosition);

@override
String toString() {
  return 'CompetitorPlayer(playerId: $playerId, rotationPosition: $rotationPosition)';
}


}

/// @nodoc
abstract mixin class _$CompetitorPlayerCopyWith<$Res> implements $CompetitorPlayerCopyWith<$Res> {
  factory _$CompetitorPlayerCopyWith(_CompetitorPlayer value, $Res Function(_CompetitorPlayer) _then) = __$CompetitorPlayerCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'player_id') String playerId,@JsonKey(name: 'rotation_position') int rotationPosition
});




}
/// @nodoc
class __$CompetitorPlayerCopyWithImpl<$Res>
    implements _$CompetitorPlayerCopyWith<$Res> {
  __$CompetitorPlayerCopyWithImpl(this._self, this._then);

  final _CompetitorPlayer _self;
  final $Res Function(_CompetitorPlayer) _then;

/// Create a copy of CompetitorPlayer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? rotationPosition = null,}) {
  return _then(_CompetitorPlayer(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,rotationPosition: null == rotationPosition ? _self.rotationPosition : rotationPosition // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
