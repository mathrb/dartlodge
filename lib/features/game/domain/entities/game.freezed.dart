// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Game _$GameFromJson(Map<String, dynamic> json) {
  return _Game.fromJson(json);
}

/// @nodoc
mixin _$Game {
  @JsonKey(name: 'game_id')
  String get gameId => throw _privateConstructorUsedError;
  @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)
  GameType get gameType => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'config_json', fromJson: _parseJsonMap, toJson: _stringifyJsonMap)
  Map<String, dynamic> get config => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  DateTime get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'end_time')
  DateTime? get endTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'winner_competitor_id')
  String? get winnerCompetitorId => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'is_complete',
      fromJson: _parseBoolFromInt,
      toJson: _convertBoolToInt)
  bool? get isComplete => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'game_state_json',
      fromJson: _parseNullableJsonMap,
      toJson: _stringifyNullableJsonMap)
  Map<String, dynamic>? get activeState => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GameCopyWith<Game> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameCopyWith<$Res> {
  factory $GameCopyWith(Game value, $Res Function(Game) then) =
      _$GameCopyWithImpl<$Res, Game>;
  @useResult
  $Res call(
      {@JsonKey(name: 'game_id') String gameId,
      @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)
      GameType gameType,
      @JsonKey(
          name: 'config_json',
          fromJson: _parseJsonMap,
          toJson: _stringifyJsonMap)
      Map<String, dynamic> config,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'end_time') DateTime? endTime,
      @JsonKey(name: 'winner_competitor_id') String? winnerCompetitorId,
      @JsonKey(
          name: 'is_complete',
          fromJson: _parseBoolFromInt,
          toJson: _convertBoolToInt)
      bool? isComplete,
      @JsonKey(
          name: 'game_state_json',
          fromJson: _parseNullableJsonMap,
          toJson: _stringifyNullableJsonMap)
      Map<String, dynamic>? activeState});
}

/// @nodoc
class _$GameCopyWithImpl<$Res, $Val extends Game>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? gameType = null,
    Object? config = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? winnerCompetitorId = freezed,
    Object? isComplete = freezed,
    Object? activeState = freezed,
  }) {
    return _then(_value.copyWith(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as GameType,
      config: null == config
          ? _value.config
          : config // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      winnerCompetitorId: freezed == winnerCompetitorId
          ? _value.winnerCompetitorId
          : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
              as String?,
      isComplete: freezed == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool?,
      activeState: freezed == activeState
          ? _value.activeState
          : activeState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameImplCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$$GameImplCopyWith(
          _$GameImpl value, $Res Function(_$GameImpl) then) =
      __$$GameImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'game_id') String gameId,
      @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)
      GameType gameType,
      @JsonKey(
          name: 'config_json',
          fromJson: _parseJsonMap,
          toJson: _stringifyJsonMap)
      Map<String, dynamic> config,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'end_time') DateTime? endTime,
      @JsonKey(name: 'winner_competitor_id') String? winnerCompetitorId,
      @JsonKey(
          name: 'is_complete',
          fromJson: _parseBoolFromInt,
          toJson: _convertBoolToInt)
      bool? isComplete,
      @JsonKey(
          name: 'game_state_json',
          fromJson: _parseNullableJsonMap,
          toJson: _stringifyNullableJsonMap)
      Map<String, dynamic>? activeState});
}

/// @nodoc
class __$$GameImplCopyWithImpl<$Res>
    extends _$GameCopyWithImpl<$Res, _$GameImpl>
    implements _$$GameImplCopyWith<$Res> {
  __$$GameImplCopyWithImpl(_$GameImpl _value, $Res Function(_$GameImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? gameType = null,
    Object? config = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? winnerCompetitorId = freezed,
    Object? isComplete = freezed,
    Object? activeState = freezed,
  }) {
    return _then(_$GameImpl(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as GameType,
      config: null == config
          ? _value._config
          : config // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      winnerCompetitorId: freezed == winnerCompetitorId
          ? _value.winnerCompetitorId
          : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
              as String?,
      isComplete: freezed == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool?,
      activeState: freezed == activeState
          ? _value._activeState
          : activeState // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameImpl implements _Game {
  const _$GameImpl(
      {@JsonKey(name: 'game_id') required this.gameId,
      @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)
      required this.gameType,
      @JsonKey(
          name: 'config_json',
          fromJson: _parseJsonMap,
          toJson: _stringifyJsonMap)
      required final Map<String, dynamic> config,
      @JsonKey(name: 'start_time') required this.startTime,
      @JsonKey(name: 'end_time') this.endTime,
      @JsonKey(name: 'winner_competitor_id') this.winnerCompetitorId,
      @JsonKey(
          name: 'is_complete',
          fromJson: _parseBoolFromInt,
          toJson: _convertBoolToInt)
      this.isComplete,
      @JsonKey(
          name: 'game_state_json',
          fromJson: _parseNullableJsonMap,
          toJson: _stringifyNullableJsonMap)
      final Map<String, dynamic>? activeState})
      : _config = config,
        _activeState = activeState;

  factory _$GameImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameImplFromJson(json);

  @override
  @JsonKey(name: 'game_id')
  final String gameId;
  @override
  @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)
  final GameType gameType;
  final Map<String, dynamic> _config;
  @override
  @JsonKey(
      name: 'config_json', fromJson: _parseJsonMap, toJson: _stringifyJsonMap)
  Map<String, dynamic> get config {
    if (_config is EqualUnmodifiableMapView) return _config;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_config);
  }

  @override
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @override
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  @override
  @JsonKey(name: 'winner_competitor_id')
  final String? winnerCompetitorId;
  @override
  @JsonKey(
      name: 'is_complete',
      fromJson: _parseBoolFromInt,
      toJson: _convertBoolToInt)
  final bool? isComplete;
  final Map<String, dynamic>? _activeState;
  @override
  @JsonKey(
      name: 'game_state_json',
      fromJson: _parseNullableJsonMap,
      toJson: _stringifyNullableJsonMap)
  Map<String, dynamic>? get activeState {
    final value = _activeState;
    if (value == null) return null;
    if (_activeState is EqualUnmodifiableMapView) return _activeState;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Game(gameId: $gameId, gameType: $gameType, config: $config, startTime: $startTime, endTime: $endTime, winnerCompetitorId: $winnerCompetitorId, isComplete: $isComplete, activeState: $activeState)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            const DeepCollectionEquality().equals(other._config, _config) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.winnerCompetitorId, winnerCompetitorId) ||
                other.winnerCompetitorId == winnerCompetitorId) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            const DeepCollectionEquality()
                .equals(other._activeState, _activeState));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      gameId,
      gameType,
      const DeepCollectionEquality().hash(_config),
      startTime,
      endTime,
      winnerCompetitorId,
      isComplete,
      const DeepCollectionEquality().hash(_activeState));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      __$$GameImplCopyWithImpl<_$GameImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameImplToJson(
      this,
    );
  }
}

abstract class _Game implements Game {
  const factory _Game(
      {@JsonKey(name: 'game_id') required final String gameId,
      @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)
      required final GameType gameType,
      @JsonKey(
          name: 'config_json',
          fromJson: _parseJsonMap,
          toJson: _stringifyJsonMap)
      required final Map<String, dynamic> config,
      @JsonKey(name: 'start_time') required final DateTime startTime,
      @JsonKey(name: 'end_time') final DateTime? endTime,
      @JsonKey(name: 'winner_competitor_id') final String? winnerCompetitorId,
      @JsonKey(
          name: 'is_complete',
          fromJson: _parseBoolFromInt,
          toJson: _convertBoolToInt)
      final bool? isComplete,
      @JsonKey(
          name: 'game_state_json',
          fromJson: _parseNullableJsonMap,
          toJson: _stringifyNullableJsonMap)
      final Map<String, dynamic>? activeState}) = _$GameImpl;

  factory _Game.fromJson(Map<String, dynamic> json) = _$GameImpl.fromJson;

  @override
  @JsonKey(name: 'game_id')
  String get gameId;
  @override
  @JsonKey(name: 'game_type', unknownEnumValue: GameType.x01)
  GameType get gameType;
  @override
  @JsonKey(
      name: 'config_json', fromJson: _parseJsonMap, toJson: _stringifyJsonMap)
  Map<String, dynamic> get config;
  @override
  @JsonKey(name: 'start_time')
  DateTime get startTime;
  @override
  @JsonKey(name: 'end_time')
  DateTime? get endTime;
  @override
  @JsonKey(name: 'winner_competitor_id')
  String? get winnerCompetitorId;
  @override
  @JsonKey(
      name: 'is_complete',
      fromJson: _parseBoolFromInt,
      toJson: _convertBoolToInt)
  bool? get isComplete;
  @override
  @JsonKey(
      name: 'game_state_json',
      fromJson: _parseNullableJsonMap,
      toJson: _stringifyNullableJsonMap)
  Map<String, dynamic>? get activeState;
  @override
  @JsonKey(ignore: true)
  _$$GameImplCopyWith<_$GameImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
