// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameState {

 String get gameId; GameType get gameType; List<CompetitorState> get competitors; int get currentTurnIndex; int get dartsThrownInTurn; bool get isComplete; String? get winnerCompetitorId; GameEngineStatus get status; bool get turnActive; int get legsToWin; int get currentLegIndex; String get inStrategy; String get outStrategy;
/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameStateCopyWith<GameState> get copyWith => _$GameStateCopyWithImpl<GameState>(this as GameState, _$identity);

  /// Serializes this GameState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameState&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&const DeepCollectionEquality().equals(other.competitors, competitors)&&(identical(other.currentTurnIndex, currentTurnIndex) || other.currentTurnIndex == currentTurnIndex)&&(identical(other.dartsThrownInTurn, dartsThrownInTurn) || other.dartsThrownInTurn == dartsThrownInTurn)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.winnerCompetitorId, winnerCompetitorId) || other.winnerCompetitorId == winnerCompetitorId)&&(identical(other.status, status) || other.status == status)&&(identical(other.turnActive, turnActive) || other.turnActive == turnActive)&&(identical(other.legsToWin, legsToWin) || other.legsToWin == legsToWin)&&(identical(other.currentLegIndex, currentLegIndex) || other.currentLegIndex == currentLegIndex)&&(identical(other.inStrategy, inStrategy) || other.inStrategy == inStrategy)&&(identical(other.outStrategy, outStrategy) || other.outStrategy == outStrategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,gameType,const DeepCollectionEquality().hash(competitors),currentTurnIndex,dartsThrownInTurn,isComplete,winnerCompetitorId,status,turnActive,legsToWin,currentLegIndex,inStrategy,outStrategy);

@override
String toString() {
  return 'GameState(gameId: $gameId, gameType: $gameType, competitors: $competitors, currentTurnIndex: $currentTurnIndex, dartsThrownInTurn: $dartsThrownInTurn, isComplete: $isComplete, winnerCompetitorId: $winnerCompetitorId, status: $status, turnActive: $turnActive, legsToWin: $legsToWin, currentLegIndex: $currentLegIndex, inStrategy: $inStrategy, outStrategy: $outStrategy)';
}


}

/// @nodoc
abstract mixin class $GameStateCopyWith<$Res>  {
  factory $GameStateCopyWith(GameState value, $Res Function(GameState) _then) = _$GameStateCopyWithImpl;
@useResult
$Res call({
 String gameId, GameType gameType, List<CompetitorState> competitors, int currentTurnIndex, int dartsThrownInTurn, bool isComplete, String? winnerCompetitorId, GameEngineStatus status, bool turnActive, int legsToWin, int currentLegIndex, String inStrategy, String outStrategy
});




}
/// @nodoc
class _$GameStateCopyWithImpl<$Res>
    implements $GameStateCopyWith<$Res> {
  _$GameStateCopyWithImpl(this._self, this._then);

  final GameState _self;
  final $Res Function(GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? gameType = null,Object? competitors = null,Object? currentTurnIndex = null,Object? dartsThrownInTurn = null,Object? isComplete = null,Object? winnerCompetitorId = freezed,Object? status = null,Object? turnActive = null,Object? legsToWin = null,Object? currentLegIndex = null,Object? inStrategy = null,Object? outStrategy = null,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,competitors: null == competitors ? _self.competitors : competitors // ignore: cast_nullable_to_non_nullable
as List<CompetitorState>,currentTurnIndex: null == currentTurnIndex ? _self.currentTurnIndex : currentTurnIndex // ignore: cast_nullable_to_non_nullable
as int,dartsThrownInTurn: null == dartsThrownInTurn ? _self.dartsThrownInTurn : dartsThrownInTurn // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GameEngineStatus,turnActive: null == turnActive ? _self.turnActive : turnActive // ignore: cast_nullable_to_non_nullable
as bool,legsToWin: null == legsToWin ? _self.legsToWin : legsToWin // ignore: cast_nullable_to_non_nullable
as int,currentLegIndex: null == currentLegIndex ? _self.currentLegIndex : currentLegIndex // ignore: cast_nullable_to_non_nullable
as int,inStrategy: null == inStrategy ? _self.inStrategy : inStrategy // ignore: cast_nullable_to_non_nullable
as String,outStrategy: null == outStrategy ? _self.outStrategy : outStrategy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GameState].
extension GameStatePatterns on GameState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameState value)  $default,){
final _that = this;
switch (_that) {
case _GameState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameState value)?  $default,){
final _that = this;
switch (_that) {
case _GameState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  GameType gameType,  List<CompetitorState> competitors,  int currentTurnIndex,  int dartsThrownInTurn,  bool isComplete,  String? winnerCompetitorId,  GameEngineStatus status,  bool turnActive,  int legsToWin,  int currentLegIndex,  String inStrategy,  String outStrategy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.gameId,_that.gameType,_that.competitors,_that.currentTurnIndex,_that.dartsThrownInTurn,_that.isComplete,_that.winnerCompetitorId,_that.status,_that.turnActive,_that.legsToWin,_that.currentLegIndex,_that.inStrategy,_that.outStrategy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  GameType gameType,  List<CompetitorState> competitors,  int currentTurnIndex,  int dartsThrownInTurn,  bool isComplete,  String? winnerCompetitorId,  GameEngineStatus status,  bool turnActive,  int legsToWin,  int currentLegIndex,  String inStrategy,  String outStrategy)  $default,) {final _that = this;
switch (_that) {
case _GameState():
return $default(_that.gameId,_that.gameType,_that.competitors,_that.currentTurnIndex,_that.dartsThrownInTurn,_that.isComplete,_that.winnerCompetitorId,_that.status,_that.turnActive,_that.legsToWin,_that.currentLegIndex,_that.inStrategy,_that.outStrategy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  GameType gameType,  List<CompetitorState> competitors,  int currentTurnIndex,  int dartsThrownInTurn,  bool isComplete,  String? winnerCompetitorId,  GameEngineStatus status,  bool turnActive,  int legsToWin,  int currentLegIndex,  String inStrategy,  String outStrategy)?  $default,) {final _that = this;
switch (_that) {
case _GameState() when $default != null:
return $default(_that.gameId,_that.gameType,_that.competitors,_that.currentTurnIndex,_that.dartsThrownInTurn,_that.isComplete,_that.winnerCompetitorId,_that.status,_that.turnActive,_that.legsToWin,_that.currentLegIndex,_that.inStrategy,_that.outStrategy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameState implements GameState {
  const _GameState({required this.gameId, required this.gameType, required final  List<CompetitorState> competitors, required this.currentTurnIndex, required this.dartsThrownInTurn, required this.isComplete, this.winnerCompetitorId, this.status = GameEngineStatus.initialized, this.turnActive = false, this.legsToWin = 1, this.currentLegIndex = 0, this.inStrategy = 'straight', this.outStrategy = 'double'}): _competitors = competitors;
  factory _GameState.fromJson(Map<String, dynamic> json) => _$GameStateFromJson(json);

@override final  String gameId;
@override final  GameType gameType;
 final  List<CompetitorState> _competitors;
@override List<CompetitorState> get competitors {
  if (_competitors is EqualUnmodifiableListView) return _competitors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_competitors);
}

@override final  int currentTurnIndex;
@override final  int dartsThrownInTurn;
@override final  bool isComplete;
@override final  String? winnerCompetitorId;
@override@JsonKey() final  GameEngineStatus status;
@override@JsonKey() final  bool turnActive;
@override@JsonKey() final  int legsToWin;
@override@JsonKey() final  int currentLegIndex;
@override@JsonKey() final  String inStrategy;
@override@JsonKey() final  String outStrategy;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameStateCopyWith<_GameState> get copyWith => __$GameStateCopyWithImpl<_GameState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameState&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&const DeepCollectionEquality().equals(other._competitors, _competitors)&&(identical(other.currentTurnIndex, currentTurnIndex) || other.currentTurnIndex == currentTurnIndex)&&(identical(other.dartsThrownInTurn, dartsThrownInTurn) || other.dartsThrownInTurn == dartsThrownInTurn)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.winnerCompetitorId, winnerCompetitorId) || other.winnerCompetitorId == winnerCompetitorId)&&(identical(other.status, status) || other.status == status)&&(identical(other.turnActive, turnActive) || other.turnActive == turnActive)&&(identical(other.legsToWin, legsToWin) || other.legsToWin == legsToWin)&&(identical(other.currentLegIndex, currentLegIndex) || other.currentLegIndex == currentLegIndex)&&(identical(other.inStrategy, inStrategy) || other.inStrategy == inStrategy)&&(identical(other.outStrategy, outStrategy) || other.outStrategy == outStrategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gameId,gameType,const DeepCollectionEquality().hash(_competitors),currentTurnIndex,dartsThrownInTurn,isComplete,winnerCompetitorId,status,turnActive,legsToWin,currentLegIndex,inStrategy,outStrategy);

@override
String toString() {
  return 'GameState(gameId: $gameId, gameType: $gameType, competitors: $competitors, currentTurnIndex: $currentTurnIndex, dartsThrownInTurn: $dartsThrownInTurn, isComplete: $isComplete, winnerCompetitorId: $winnerCompetitorId, status: $status, turnActive: $turnActive, legsToWin: $legsToWin, currentLegIndex: $currentLegIndex, inStrategy: $inStrategy, outStrategy: $outStrategy)';
}


}

/// @nodoc
abstract mixin class _$GameStateCopyWith<$Res> implements $GameStateCopyWith<$Res> {
  factory _$GameStateCopyWith(_GameState value, $Res Function(_GameState) _then) = __$GameStateCopyWithImpl;
@override @useResult
$Res call({
 String gameId, GameType gameType, List<CompetitorState> competitors, int currentTurnIndex, int dartsThrownInTurn, bool isComplete, String? winnerCompetitorId, GameEngineStatus status, bool turnActive, int legsToWin, int currentLegIndex, String inStrategy, String outStrategy
});




}
/// @nodoc
class __$GameStateCopyWithImpl<$Res>
    implements _$GameStateCopyWith<$Res> {
  __$GameStateCopyWithImpl(this._self, this._then);

  final _GameState _self;
  final $Res Function(_GameState) _then;

/// Create a copy of GameState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? gameType = null,Object? competitors = null,Object? currentTurnIndex = null,Object? dartsThrownInTurn = null,Object? isComplete = null,Object? winnerCompetitorId = freezed,Object? status = null,Object? turnActive = null,Object? legsToWin = null,Object? currentLegIndex = null,Object? inStrategy = null,Object? outStrategy = null,}) {
  return _then(_GameState(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,competitors: null == competitors ? _self._competitors : competitors // ignore: cast_nullable_to_non_nullable
as List<CompetitorState>,currentTurnIndex: null == currentTurnIndex ? _self.currentTurnIndex : currentTurnIndex // ignore: cast_nullable_to_non_nullable
as int,dartsThrownInTurn: null == dartsThrownInTurn ? _self.dartsThrownInTurn : dartsThrownInTurn // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GameEngineStatus,turnActive: null == turnActive ? _self.turnActive : turnActive // ignore: cast_nullable_to_non_nullable
as bool,legsToWin: null == legsToWin ? _self.legsToWin : legsToWin // ignore: cast_nullable_to_non_nullable
as int,currentLegIndex: null == currentLegIndex ? _self.currentLegIndex : currentLegIndex // ignore: cast_nullable_to_non_nullable
as int,inStrategy: null == inStrategy ? _self.inStrategy : inStrategy // ignore: cast_nullable_to_non_nullable
as String,outStrategy: null == outStrategy ? _self.outStrategy : outStrategy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CompetitorState {

 String get competitorId; String get name; List<String> get playerIds; int get score; bool get isComplete; List<String> get dartThrows;// Canonical segment strings
 bool get isIn; int get legsWon; int? get turnStartScore;
/// Create a copy of CompetitorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompetitorStateCopyWith<CompetitorState> get copyWith => _$CompetitorStateCopyWithImpl<CompetitorState>(this as CompetitorState, _$identity);

  /// Serializes this CompetitorState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompetitorState&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.playerIds, playerIds)&&(identical(other.score, score) || other.score == score)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&const DeepCollectionEquality().equals(other.dartThrows, dartThrows)&&(identical(other.isIn, isIn) || other.isIn == isIn)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.turnStartScore, turnStartScore) || other.turnStartScore == turnStartScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,name,const DeepCollectionEquality().hash(playerIds),score,isComplete,const DeepCollectionEquality().hash(dartThrows),isIn,legsWon,turnStartScore);

@override
String toString() {
  return 'CompetitorState(competitorId: $competitorId, name: $name, playerIds: $playerIds, score: $score, isComplete: $isComplete, dartThrows: $dartThrows, isIn: $isIn, legsWon: $legsWon, turnStartScore: $turnStartScore)';
}


}

/// @nodoc
abstract mixin class $CompetitorStateCopyWith<$Res>  {
  factory $CompetitorStateCopyWith(CompetitorState value, $Res Function(CompetitorState) _then) = _$CompetitorStateCopyWithImpl;
@useResult
$Res call({
 String competitorId, String name, List<String> playerIds, int score, bool isComplete, List<String> dartThrows, bool isIn, int legsWon, int? turnStartScore
});




}
/// @nodoc
class _$CompetitorStateCopyWithImpl<$Res>
    implements $CompetitorStateCopyWith<$Res> {
  _$CompetitorStateCopyWithImpl(this._self, this._then);

  final CompetitorState _self;
  final $Res Function(CompetitorState) _then;

/// Create a copy of CompetitorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competitorId = null,Object? name = null,Object? playerIds = null,Object? score = null,Object? isComplete = null,Object? dartThrows = null,Object? isIn = null,Object? legsWon = null,Object? turnStartScore = freezed,}) {
  return _then(_self.copyWith(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,playerIds: null == playerIds ? _self.playerIds : playerIds // ignore: cast_nullable_to_non_nullable
as List<String>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,dartThrows: null == dartThrows ? _self.dartThrows : dartThrows // ignore: cast_nullable_to_non_nullable
as List<String>,isIn: null == isIn ? _self.isIn : isIn // ignore: cast_nullable_to_non_nullable
as bool,legsWon: null == legsWon ? _self.legsWon : legsWon // ignore: cast_nullable_to_non_nullable
as int,turnStartScore: freezed == turnStartScore ? _self.turnStartScore : turnStartScore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CompetitorState].
extension CompetitorStatePatterns on CompetitorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompetitorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompetitorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompetitorState value)  $default,){
final _that = this;
switch (_that) {
case _CompetitorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompetitorState value)?  $default,){
final _that = this;
switch (_that) {
case _CompetitorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String competitorId,  String name,  List<String> playerIds,  int score,  bool isComplete,  List<String> dartThrows,  bool isIn,  int legsWon,  int? turnStartScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompetitorState() when $default != null:
return $default(_that.competitorId,_that.name,_that.playerIds,_that.score,_that.isComplete,_that.dartThrows,_that.isIn,_that.legsWon,_that.turnStartScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String competitorId,  String name,  List<String> playerIds,  int score,  bool isComplete,  List<String> dartThrows,  bool isIn,  int legsWon,  int? turnStartScore)  $default,) {final _that = this;
switch (_that) {
case _CompetitorState():
return $default(_that.competitorId,_that.name,_that.playerIds,_that.score,_that.isComplete,_that.dartThrows,_that.isIn,_that.legsWon,_that.turnStartScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String competitorId,  String name,  List<String> playerIds,  int score,  bool isComplete,  List<String> dartThrows,  bool isIn,  int legsWon,  int? turnStartScore)?  $default,) {final _that = this;
switch (_that) {
case _CompetitorState() when $default != null:
return $default(_that.competitorId,_that.name,_that.playerIds,_that.score,_that.isComplete,_that.dartThrows,_that.isIn,_that.legsWon,_that.turnStartScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompetitorState implements CompetitorState {
  const _CompetitorState({required this.competitorId, required this.name, required final  List<String> playerIds, required this.score, this.isComplete = false, final  List<String> dartThrows = const [], this.isIn = false, this.legsWon = 0, this.turnStartScore}): _playerIds = playerIds,_dartThrows = dartThrows;
  factory _CompetitorState.fromJson(Map<String, dynamic> json) => _$CompetitorStateFromJson(json);

@override final  String competitorId;
@override final  String name;
 final  List<String> _playerIds;
@override List<String> get playerIds {
  if (_playerIds is EqualUnmodifiableListView) return _playerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playerIds);
}

@override final  int score;
@override@JsonKey() final  bool isComplete;
 final  List<String> _dartThrows;
@override@JsonKey() List<String> get dartThrows {
  if (_dartThrows is EqualUnmodifiableListView) return _dartThrows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dartThrows);
}

// Canonical segment strings
@override@JsonKey() final  bool isIn;
@override@JsonKey() final  int legsWon;
@override final  int? turnStartScore;

/// Create a copy of CompetitorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompetitorStateCopyWith<_CompetitorState> get copyWith => __$CompetitorStateCopyWithImpl<_CompetitorState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompetitorStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompetitorState&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._playerIds, _playerIds)&&(identical(other.score, score) || other.score == score)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&const DeepCollectionEquality().equals(other._dartThrows, _dartThrows)&&(identical(other.isIn, isIn) || other.isIn == isIn)&&(identical(other.legsWon, legsWon) || other.legsWon == legsWon)&&(identical(other.turnStartScore, turnStartScore) || other.turnStartScore == turnStartScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,name,const DeepCollectionEquality().hash(_playerIds),score,isComplete,const DeepCollectionEquality().hash(_dartThrows),isIn,legsWon,turnStartScore);

@override
String toString() {
  return 'CompetitorState(competitorId: $competitorId, name: $name, playerIds: $playerIds, score: $score, isComplete: $isComplete, dartThrows: $dartThrows, isIn: $isIn, legsWon: $legsWon, turnStartScore: $turnStartScore)';
}


}

/// @nodoc
abstract mixin class _$CompetitorStateCopyWith<$Res> implements $CompetitorStateCopyWith<$Res> {
  factory _$CompetitorStateCopyWith(_CompetitorState value, $Res Function(_CompetitorState) _then) = __$CompetitorStateCopyWithImpl;
@override @useResult
$Res call({
 String competitorId, String name, List<String> playerIds, int score, bool isComplete, List<String> dartThrows, bool isIn, int legsWon, int? turnStartScore
});




}
/// @nodoc
class __$CompetitorStateCopyWithImpl<$Res>
    implements _$CompetitorStateCopyWith<$Res> {
  __$CompetitorStateCopyWithImpl(this._self, this._then);

  final _CompetitorState _self;
  final $Res Function(_CompetitorState) _then;

/// Create a copy of CompetitorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorId = null,Object? name = null,Object? playerIds = null,Object? score = null,Object? isComplete = null,Object? dartThrows = null,Object? isIn = null,Object? legsWon = null,Object? turnStartScore = freezed,}) {
  return _then(_CompetitorState(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,playerIds: null == playerIds ? _self._playerIds : playerIds // ignore: cast_nullable_to_non_nullable
as List<String>,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,dartThrows: null == dartThrows ? _self._dartThrows : dartThrows // ignore: cast_nullable_to_non_nullable
as List<String>,isIn: null == isIn ? _self.isIn : isIn // ignore: cast_nullable_to_non_nullable
as bool,legsWon: null == legsWon ? _self.legsWon : legsWon // ignore: cast_nullable_to_non_nullable
as int,turnStartScore: freezed == turnStartScore ? _self.turnStartScore : turnStartScore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
