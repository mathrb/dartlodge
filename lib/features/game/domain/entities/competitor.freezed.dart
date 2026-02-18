// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'competitor.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Competitor _$CompetitorFromJson(Map<String, dynamic> json) {
  return _Competitor.fromJson(json);
}

/// @nodoc
mixin _$Competitor {
  String get competitorId => throw _privateConstructorUsedError;
  String get gameId => throw _privateConstructorUsedError;
  CompetitorType get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<CompetitorPlayer> get players => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CompetitorCopyWith<Competitor> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompetitorCopyWith<$Res> {
  factory $CompetitorCopyWith(
          Competitor value, $Res Function(Competitor) then) =
      _$CompetitorCopyWithImpl<$Res, Competitor>;
  @useResult
  $Res call(
      {String competitorId,
      String gameId,
      CompetitorType type,
      String name,
      List<CompetitorPlayer> players});
}

/// @nodoc
class _$CompetitorCopyWithImpl<$Res, $Val extends Competitor>
    implements $CompetitorCopyWith<$Res> {
  _$CompetitorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? competitorId = null,
    Object? gameId = null,
    Object? type = null,
    Object? name = null,
    Object? players = null,
  }) {
    return _then(_value.copyWith(
      competitorId: null == competitorId
          ? _value.competitorId
          : competitorId // ignore: cast_nullable_to_non_nullable
              as String,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CompetitorType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      players: null == players
          ? _value.players
          : players // ignore: cast_nullable_to_non_nullable
              as List<CompetitorPlayer>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompetitorImplCopyWith<$Res>
    implements $CompetitorCopyWith<$Res> {
  factory _$$CompetitorImplCopyWith(
          _$CompetitorImpl value, $Res Function(_$CompetitorImpl) then) =
      __$$CompetitorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String competitorId,
      String gameId,
      CompetitorType type,
      String name,
      List<CompetitorPlayer> players});
}

/// @nodoc
class __$$CompetitorImplCopyWithImpl<$Res>
    extends _$CompetitorCopyWithImpl<$Res, _$CompetitorImpl>
    implements _$$CompetitorImplCopyWith<$Res> {
  __$$CompetitorImplCopyWithImpl(
      _$CompetitorImpl _value, $Res Function(_$CompetitorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? competitorId = null,
    Object? gameId = null,
    Object? type = null,
    Object? name = null,
    Object? players = null,
  }) {
    return _then(_$CompetitorImpl(
      competitorId: null == competitorId
          ? _value.competitorId
          : competitorId // ignore: cast_nullable_to_non_nullable
              as String,
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CompetitorType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      players: null == players
          ? _value._players
          : players // ignore: cast_nullable_to_non_nullable
              as List<CompetitorPlayer>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompetitorImpl implements _Competitor {
  const _$CompetitorImpl(
      {required this.competitorId,
      required this.gameId,
      required this.type,
      required this.name,
      required final List<CompetitorPlayer> players})
      : _players = players;

  factory _$CompetitorImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompetitorImplFromJson(json);

  @override
  final String competitorId;
  @override
  final String gameId;
  @override
  final CompetitorType type;
  @override
  final String name;
  final List<CompetitorPlayer> _players;
  @override
  List<CompetitorPlayer> get players {
    if (_players is EqualUnmodifiableListView) return _players;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_players);
  }

  @override
  String toString() {
    return 'Competitor(competitorId: $competitorId, gameId: $gameId, type: $type, name: $name, players: $players)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompetitorImpl &&
            (identical(other.competitorId, competitorId) ||
                other.competitorId == competitorId) &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._players, _players));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, competitorId, gameId, type, name,
      const DeepCollectionEquality().hash(_players));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CompetitorImplCopyWith<_$CompetitorImpl> get copyWith =>
      __$$CompetitorImplCopyWithImpl<_$CompetitorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompetitorImplToJson(
      this,
    );
  }
}

abstract class _Competitor implements Competitor {
  const factory _Competitor(
      {required final String competitorId,
      required final String gameId,
      required final CompetitorType type,
      required final String name,
      required final List<CompetitorPlayer> players}) = _$CompetitorImpl;

  factory _Competitor.fromJson(Map<String, dynamic> json) =
      _$CompetitorImpl.fromJson;

  @override
  String get competitorId;
  @override
  String get gameId;
  @override
  CompetitorType get type;
  @override
  String get name;
  @override
  List<CompetitorPlayer> get players;
  @override
  @JsonKey(ignore: true)
  _$$CompetitorImplCopyWith<_$CompetitorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompetitorPlayer _$CompetitorPlayerFromJson(Map<String, dynamic> json) {
  return _CompetitorPlayer.fromJson(json);
}

/// @nodoc
mixin _$CompetitorPlayer {
  String get playerId => throw _privateConstructorUsedError;
  int get rotationPosition => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CompetitorPlayerCopyWith<CompetitorPlayer> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompetitorPlayerCopyWith<$Res> {
  factory $CompetitorPlayerCopyWith(
          CompetitorPlayer value, $Res Function(CompetitorPlayer) then) =
      _$CompetitorPlayerCopyWithImpl<$Res, CompetitorPlayer>;
  @useResult
  $Res call({String playerId, int rotationPosition});
}

/// @nodoc
class _$CompetitorPlayerCopyWithImpl<$Res, $Val extends CompetitorPlayer>
    implements $CompetitorPlayerCopyWith<$Res> {
  _$CompetitorPlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? rotationPosition = null,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      rotationPosition: null == rotationPosition
          ? _value.rotationPosition
          : rotationPosition // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompetitorPlayerImplCopyWith<$Res>
    implements $CompetitorPlayerCopyWith<$Res> {
  factory _$$CompetitorPlayerImplCopyWith(_$CompetitorPlayerImpl value,
          $Res Function(_$CompetitorPlayerImpl) then) =
      __$$CompetitorPlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId, int rotationPosition});
}

/// @nodoc
class __$$CompetitorPlayerImplCopyWithImpl<$Res>
    extends _$CompetitorPlayerCopyWithImpl<$Res, _$CompetitorPlayerImpl>
    implements _$$CompetitorPlayerImplCopyWith<$Res> {
  __$$CompetitorPlayerImplCopyWithImpl(_$CompetitorPlayerImpl _value,
      $Res Function(_$CompetitorPlayerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? rotationPosition = null,
  }) {
    return _then(_$CompetitorPlayerImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      rotationPosition: null == rotationPosition
          ? _value.rotationPosition
          : rotationPosition // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompetitorPlayerImpl implements _CompetitorPlayer {
  const _$CompetitorPlayerImpl(
      {required this.playerId, required this.rotationPosition});

  factory _$CompetitorPlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompetitorPlayerImplFromJson(json);

  @override
  final String playerId;
  @override
  final int rotationPosition;

  @override
  String toString() {
    return 'CompetitorPlayer(playerId: $playerId, rotationPosition: $rotationPosition)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompetitorPlayerImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.rotationPosition, rotationPosition) ||
                other.rotationPosition == rotationPosition));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, playerId, rotationPosition);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CompetitorPlayerImplCopyWith<_$CompetitorPlayerImpl> get copyWith =>
      __$$CompetitorPlayerImplCopyWithImpl<_$CompetitorPlayerImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompetitorPlayerImplToJson(
      this,
    );
  }
}

abstract class _CompetitorPlayer implements CompetitorPlayer {
  const factory _CompetitorPlayer(
      {required final String playerId,
      required final int rotationPosition}) = _$CompetitorPlayerImpl;

  factory _CompetitorPlayer.fromJson(Map<String, dynamic> json) =
      _$CompetitorPlayerImpl.fromJson;

  @override
  String get playerId;
  @override
  int get rotationPosition;
  @override
  @JsonKey(ignore: true)
  _$$CompetitorPlayerImplCopyWith<_$CompetitorPlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
