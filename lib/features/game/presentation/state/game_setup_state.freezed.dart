// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_setup_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameSetupState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSetupState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameSetupState()';
}


}

/// @nodoc
class $GameSetupStateCopyWith<$Res>  {
$GameSetupStateCopyWith(GameSetupState _, $Res Function(GameSetupState) __);
}


/// Adds pattern-matching-related methods to [GameSetupState].
extension GameSetupStatePatterns on GameSetupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SelectingType value)?  selectingType,TResult Function( _ConfiguringGame value)?  configuringGame,TResult Function( _SelectingPlayers value)?  selectingPlayers,TResult Function( _FormingTeams value)?  formingTeams,TResult Function( _Ready value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelectingType() when selectingType != null:
return selectingType(_that);case _ConfiguringGame() when configuringGame != null:
return configuringGame(_that);case _SelectingPlayers() when selectingPlayers != null:
return selectingPlayers(_that);case _FormingTeams() when formingTeams != null:
return formingTeams(_that);case _Ready() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SelectingType value)  selectingType,required TResult Function( _ConfiguringGame value)  configuringGame,required TResult Function( _SelectingPlayers value)  selectingPlayers,required TResult Function( _FormingTeams value)  formingTeams,required TResult Function( _Ready value)  ready,}){
final _that = this;
switch (_that) {
case _SelectingType():
return selectingType(_that);case _ConfiguringGame():
return configuringGame(_that);case _SelectingPlayers():
return selectingPlayers(_that);case _FormingTeams():
return formingTeams(_that);case _Ready():
return ready(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SelectingType value)?  selectingType,TResult? Function( _ConfiguringGame value)?  configuringGame,TResult? Function( _SelectingPlayers value)?  selectingPlayers,TResult? Function( _FormingTeams value)?  formingTeams,TResult? Function( _Ready value)?  ready,}){
final _that = this;
switch (_that) {
case _SelectingType() when selectingType != null:
return selectingType(_that);case _ConfiguringGame() when configuringGame != null:
return configuringGame(_that);case _SelectingPlayers() when selectingPlayers != null:
return selectingPlayers(_that);case _FormingTeams() when formingTeams != null:
return formingTeams(_that);case _Ready() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  selectingType,TResult Function( GameType gameType,  GameConfig config)?  configuringGame,TResult Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)?  selectingPlayers,TResult Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)?  formingTeams,TResult Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelectingType() when selectingType != null:
return selectingType();case _ConfiguringGame() when configuringGame != null:
return configuringGame(_that.gameType,_that.config);case _SelectingPlayers() when selectingPlayers != null:
return selectingPlayers(_that.gameType,_that.config,_that.selectedPlayerIds);case _FormingTeams() when formingTeams != null:
return formingTeams(_that.gameType,_that.config,_that.selectedPlayerIds);case _Ready() when ready != null:
return ready(_that.gameType,_that.config,_that.selectedPlayerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  selectingType,required TResult Function( GameType gameType,  GameConfig config)  configuringGame,required TResult Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)  selectingPlayers,required TResult Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)  formingTeams,required TResult Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)  ready,}) {final _that = this;
switch (_that) {
case _SelectingType():
return selectingType();case _ConfiguringGame():
return configuringGame(_that.gameType,_that.config);case _SelectingPlayers():
return selectingPlayers(_that.gameType,_that.config,_that.selectedPlayerIds);case _FormingTeams():
return formingTeams(_that.gameType,_that.config,_that.selectedPlayerIds);case _Ready():
return ready(_that.gameType,_that.config,_that.selectedPlayerIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  selectingType,TResult? Function( GameType gameType,  GameConfig config)?  configuringGame,TResult? Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)?  selectingPlayers,TResult? Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)?  formingTeams,TResult? Function( GameType gameType,  GameConfig config,  List<String> selectedPlayerIds)?  ready,}) {final _that = this;
switch (_that) {
case _SelectingType() when selectingType != null:
return selectingType();case _ConfiguringGame() when configuringGame != null:
return configuringGame(_that.gameType,_that.config);case _SelectingPlayers() when selectingPlayers != null:
return selectingPlayers(_that.gameType,_that.config,_that.selectedPlayerIds);case _FormingTeams() when formingTeams != null:
return formingTeams(_that.gameType,_that.config,_that.selectedPlayerIds);case _Ready() when ready != null:
return ready(_that.gameType,_that.config,_that.selectedPlayerIds);case _:
  return null;

}
}

}

/// @nodoc


class _SelectingType implements GameSetupState {
  const _SelectingType();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectingType);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameSetupState.selectingType()';
}


}




/// @nodoc


class _ConfiguringGame implements GameSetupState {
  const _ConfiguringGame({required this.gameType, required this.config});
  

 final  GameType gameType;
 final  GameConfig config;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfiguringGameCopyWith<_ConfiguringGame> get copyWith => __$ConfiguringGameCopyWithImpl<_ConfiguringGame>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfiguringGame&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.config, config) || other.config == config));
}


@override
int get hashCode => Object.hash(runtimeType,gameType,config);

@override
String toString() {
  return 'GameSetupState.configuringGame(gameType: $gameType, config: $config)';
}


}

/// @nodoc
abstract mixin class _$ConfiguringGameCopyWith<$Res> implements $GameSetupStateCopyWith<$Res> {
  factory _$ConfiguringGameCopyWith(_ConfiguringGame value, $Res Function(_ConfiguringGame) _then) = __$ConfiguringGameCopyWithImpl;
@useResult
$Res call({
 GameType gameType, GameConfig config
});


$GameConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$ConfiguringGameCopyWithImpl<$Res>
    implements _$ConfiguringGameCopyWith<$Res> {
  __$ConfiguringGameCopyWithImpl(this._self, this._then);

  final _ConfiguringGame _self;
  final $Res Function(_ConfiguringGame) _then;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? gameType = null,Object? config = null,}) {
  return _then(_ConfiguringGame(
gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,
  ));
}

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameConfigCopyWith<$Res> get config {
  
  return $GameConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

/// @nodoc


class _SelectingPlayers implements GameSetupState {
  const _SelectingPlayers({required this.gameType, required this.config, required final  List<String> selectedPlayerIds}): _selectedPlayerIds = selectedPlayerIds;
  

 final  GameType gameType;
 final  GameConfig config;
 final  List<String> _selectedPlayerIds;
 List<String> get selectedPlayerIds {
  if (_selectedPlayerIds is EqualUnmodifiableListView) return _selectedPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedPlayerIds);
}


/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelectingPlayersCopyWith<_SelectingPlayers> get copyWith => __$SelectingPlayersCopyWithImpl<_SelectingPlayers>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelectingPlayers&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.config, config) || other.config == config)&&const DeepCollectionEquality().equals(other._selectedPlayerIds, _selectedPlayerIds));
}


@override
int get hashCode => Object.hash(runtimeType,gameType,config,const DeepCollectionEquality().hash(_selectedPlayerIds));

@override
String toString() {
  return 'GameSetupState.selectingPlayers(gameType: $gameType, config: $config, selectedPlayerIds: $selectedPlayerIds)';
}


}

/// @nodoc
abstract mixin class _$SelectingPlayersCopyWith<$Res> implements $GameSetupStateCopyWith<$Res> {
  factory _$SelectingPlayersCopyWith(_SelectingPlayers value, $Res Function(_SelectingPlayers) _then) = __$SelectingPlayersCopyWithImpl;
@useResult
$Res call({
 GameType gameType, GameConfig config, List<String> selectedPlayerIds
});


$GameConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$SelectingPlayersCopyWithImpl<$Res>
    implements _$SelectingPlayersCopyWith<$Res> {
  __$SelectingPlayersCopyWithImpl(this._self, this._then);

  final _SelectingPlayers _self;
  final $Res Function(_SelectingPlayers) _then;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? gameType = null,Object? config = null,Object? selectedPlayerIds = null,}) {
  return _then(_SelectingPlayers(
gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,selectedPlayerIds: null == selectedPlayerIds ? _self._selectedPlayerIds : selectedPlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameConfigCopyWith<$Res> get config {
  
  return $GameConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

/// @nodoc


class _FormingTeams implements GameSetupState {
  const _FormingTeams({required this.gameType, required this.config, required final  List<String> selectedPlayerIds}): _selectedPlayerIds = selectedPlayerIds;
  

 final  GameType gameType;
 final  GameConfig config;
 final  List<String> _selectedPlayerIds;
 List<String> get selectedPlayerIds {
  if (_selectedPlayerIds is EqualUnmodifiableListView) return _selectedPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedPlayerIds);
}


/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormingTeamsCopyWith<_FormingTeams> get copyWith => __$FormingTeamsCopyWithImpl<_FormingTeams>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FormingTeams&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.config, config) || other.config == config)&&const DeepCollectionEquality().equals(other._selectedPlayerIds, _selectedPlayerIds));
}


@override
int get hashCode => Object.hash(runtimeType,gameType,config,const DeepCollectionEquality().hash(_selectedPlayerIds));

@override
String toString() {
  return 'GameSetupState.formingTeams(gameType: $gameType, config: $config, selectedPlayerIds: $selectedPlayerIds)';
}


}

/// @nodoc
abstract mixin class _$FormingTeamsCopyWith<$Res> implements $GameSetupStateCopyWith<$Res> {
  factory _$FormingTeamsCopyWith(_FormingTeams value, $Res Function(_FormingTeams) _then) = __$FormingTeamsCopyWithImpl;
@useResult
$Res call({
 GameType gameType, GameConfig config, List<String> selectedPlayerIds
});


$GameConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$FormingTeamsCopyWithImpl<$Res>
    implements _$FormingTeamsCopyWith<$Res> {
  __$FormingTeamsCopyWithImpl(this._self, this._then);

  final _FormingTeams _self;
  final $Res Function(_FormingTeams) _then;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? gameType = null,Object? config = null,Object? selectedPlayerIds = null,}) {
  return _then(_FormingTeams(
gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,selectedPlayerIds: null == selectedPlayerIds ? _self._selectedPlayerIds : selectedPlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameConfigCopyWith<$Res> get config {
  
  return $GameConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

/// @nodoc


class _Ready implements GameSetupState {
  const _Ready({required this.gameType, required this.config, required final  List<String> selectedPlayerIds}): _selectedPlayerIds = selectedPlayerIds;
  

 final  GameType gameType;
 final  GameConfig config;
 final  List<String> _selectedPlayerIds;
 List<String> get selectedPlayerIds {
  if (_selectedPlayerIds is EqualUnmodifiableListView) return _selectedPlayerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedPlayerIds);
}


/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadyCopyWith<_Ready> get copyWith => __$ReadyCopyWithImpl<_Ready>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ready&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.config, config) || other.config == config)&&const DeepCollectionEquality().equals(other._selectedPlayerIds, _selectedPlayerIds));
}


@override
int get hashCode => Object.hash(runtimeType,gameType,config,const DeepCollectionEquality().hash(_selectedPlayerIds));

@override
String toString() {
  return 'GameSetupState.ready(gameType: $gameType, config: $config, selectedPlayerIds: $selectedPlayerIds)';
}


}

/// @nodoc
abstract mixin class _$ReadyCopyWith<$Res> implements $GameSetupStateCopyWith<$Res> {
  factory _$ReadyCopyWith(_Ready value, $Res Function(_Ready) _then) = __$ReadyCopyWithImpl;
@useResult
$Res call({
 GameType gameType, GameConfig config, List<String> selectedPlayerIds
});


$GameConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$ReadyCopyWithImpl<$Res>
    implements _$ReadyCopyWith<$Res> {
  __$ReadyCopyWithImpl(this._self, this._then);

  final _Ready _self;
  final $Res Function(_Ready) _then;

/// Create a copy of GameSetupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? gameType = null,Object? config = null,Object? selectedPlayerIds = null,}) {
  return _then(_Ready(
gameType: null == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as GameConfig,selectedPlayerIds: null == selectedPlayerIds ? _self._selectedPlayerIds : selectedPlayerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of GameSetupState
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
