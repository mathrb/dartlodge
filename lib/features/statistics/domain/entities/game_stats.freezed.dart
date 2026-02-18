// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GameStats _$GameStatsFromJson(Map<String, dynamic> json) {
  return _GameStats.fromJson(json);
}

/// @nodoc
mixin _$GameStats {
  String get gameId => throw _privateConstructorUsedError;
  List<CompetitorStats> get byCompetitor => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GameStatsCopyWith<GameStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GameStatsCopyWith<$Res> {
  factory $GameStatsCopyWith(GameStats value, $Res Function(GameStats) then) =
      _$GameStatsCopyWithImpl<$Res, GameStats>;
  @useResult
  $Res call({String gameId, List<CompetitorStats> byCompetitor});
}

/// @nodoc
class _$GameStatsCopyWithImpl<$Res, $Val extends GameStats>
    implements $GameStatsCopyWith<$Res> {
  _$GameStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? byCompetitor = null,
  }) {
    return _then(_value.copyWith(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      byCompetitor: null == byCompetitor
          ? _value.byCompetitor
          : byCompetitor // ignore: cast_nullable_to_non_nullable
              as List<CompetitorStats>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GameStatsImplCopyWith<$Res>
    implements $GameStatsCopyWith<$Res> {
  factory _$$GameStatsImplCopyWith(
          _$GameStatsImpl value, $Res Function(_$GameStatsImpl) then) =
      __$$GameStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String gameId, List<CompetitorStats> byCompetitor});
}

/// @nodoc
class __$$GameStatsImplCopyWithImpl<$Res>
    extends _$GameStatsCopyWithImpl<$Res, _$GameStatsImpl>
    implements _$$GameStatsImplCopyWith<$Res> {
  __$$GameStatsImplCopyWithImpl(
      _$GameStatsImpl _value, $Res Function(_$GameStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? gameId = null,
    Object? byCompetitor = null,
  }) {
    return _then(_$GameStatsImpl(
      gameId: null == gameId
          ? _value.gameId
          : gameId // ignore: cast_nullable_to_non_nullable
              as String,
      byCompetitor: null == byCompetitor
          ? _value._byCompetitor
          : byCompetitor // ignore: cast_nullable_to_non_nullable
              as List<CompetitorStats>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GameStatsImpl implements _GameStats {
  const _$GameStatsImpl(
      {required this.gameId, required final List<CompetitorStats> byCompetitor})
      : _byCompetitor = byCompetitor;

  factory _$GameStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$GameStatsImplFromJson(json);

  @override
  final String gameId;
  final List<CompetitorStats> _byCompetitor;
  @override
  List<CompetitorStats> get byCompetitor {
    if (_byCompetitor is EqualUnmodifiableListView) return _byCompetitor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_byCompetitor);
  }

  @override
  String toString() {
    return 'GameStats(gameId: $gameId, byCompetitor: $byCompetitor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GameStatsImpl &&
            (identical(other.gameId, gameId) || other.gameId == gameId) &&
            const DeepCollectionEquality()
                .equals(other._byCompetitor, _byCompetitor));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, gameId, const DeepCollectionEquality().hash(_byCompetitor));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GameStatsImplCopyWith<_$GameStatsImpl> get copyWith =>
      __$$GameStatsImplCopyWithImpl<_$GameStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GameStatsImplToJson(
      this,
    );
  }
}

abstract class _GameStats implements GameStats {
  const factory _GameStats(
      {required final String gameId,
      required final List<CompetitorStats> byCompetitor}) = _$GameStatsImpl;

  factory _GameStats.fromJson(Map<String, dynamic> json) =
      _$GameStatsImpl.fromJson;

  @override
  String get gameId;
  @override
  List<CompetitorStats> get byCompetitor;
  @override
  @JsonKey(ignore: true)
  _$$GameStatsImplCopyWith<_$GameStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompetitorStats _$CompetitorStatsFromJson(Map<String, dynamic> json) {
  return _CompetitorStats.fromJson(json);
}

/// @nodoc
mixin _$CompetitorStats {
  String get competitorId => throw _privateConstructorUsedError;
  String get competitorName => throw _privateConstructorUsedError;
  List<PlayerTurnStats> get byPlayer => throw _privateConstructorUsedError;
  double get threeDartAverage => throw _privateConstructorUsedError;
  int get legsWon => throw _privateConstructorUsedError;
  int get totalDartsThrown => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CompetitorStatsCopyWith<CompetitorStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompetitorStatsCopyWith<$Res> {
  factory $CompetitorStatsCopyWith(
          CompetitorStats value, $Res Function(CompetitorStats) then) =
      _$CompetitorStatsCopyWithImpl<$Res, CompetitorStats>;
  @useResult
  $Res call(
      {String competitorId,
      String competitorName,
      List<PlayerTurnStats> byPlayer,
      double threeDartAverage,
      int legsWon,
      int totalDartsThrown});
}

/// @nodoc
class _$CompetitorStatsCopyWithImpl<$Res, $Val extends CompetitorStats>
    implements $CompetitorStatsCopyWith<$Res> {
  _$CompetitorStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? competitorId = null,
    Object? competitorName = null,
    Object? byPlayer = null,
    Object? threeDartAverage = null,
    Object? legsWon = null,
    Object? totalDartsThrown = null,
  }) {
    return _then(_value.copyWith(
      competitorId: null == competitorId
          ? _value.competitorId
          : competitorId // ignore: cast_nullable_to_non_nullable
              as String,
      competitorName: null == competitorName
          ? _value.competitorName
          : competitorName // ignore: cast_nullable_to_non_nullable
              as String,
      byPlayer: null == byPlayer
          ? _value.byPlayer
          : byPlayer // ignore: cast_nullable_to_non_nullable
              as List<PlayerTurnStats>,
      threeDartAverage: null == threeDartAverage
          ? _value.threeDartAverage
          : threeDartAverage // ignore: cast_nullable_to_non_nullable
              as double,
      legsWon: null == legsWon
          ? _value.legsWon
          : legsWon // ignore: cast_nullable_to_non_nullable
              as int,
      totalDartsThrown: null == totalDartsThrown
          ? _value.totalDartsThrown
          : totalDartsThrown // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CompetitorStatsImplCopyWith<$Res>
    implements $CompetitorStatsCopyWith<$Res> {
  factory _$$CompetitorStatsImplCopyWith(_$CompetitorStatsImpl value,
          $Res Function(_$CompetitorStatsImpl) then) =
      __$$CompetitorStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String competitorId,
      String competitorName,
      List<PlayerTurnStats> byPlayer,
      double threeDartAverage,
      int legsWon,
      int totalDartsThrown});
}

/// @nodoc
class __$$CompetitorStatsImplCopyWithImpl<$Res>
    extends _$CompetitorStatsCopyWithImpl<$Res, _$CompetitorStatsImpl>
    implements _$$CompetitorStatsImplCopyWith<$Res> {
  __$$CompetitorStatsImplCopyWithImpl(
      _$CompetitorStatsImpl _value, $Res Function(_$CompetitorStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? competitorId = null,
    Object? competitorName = null,
    Object? byPlayer = null,
    Object? threeDartAverage = null,
    Object? legsWon = null,
    Object? totalDartsThrown = null,
  }) {
    return _then(_$CompetitorStatsImpl(
      competitorId: null == competitorId
          ? _value.competitorId
          : competitorId // ignore: cast_nullable_to_non_nullable
              as String,
      competitorName: null == competitorName
          ? _value.competitorName
          : competitorName // ignore: cast_nullable_to_non_nullable
              as String,
      byPlayer: null == byPlayer
          ? _value._byPlayer
          : byPlayer // ignore: cast_nullable_to_non_nullable
              as List<PlayerTurnStats>,
      threeDartAverage: null == threeDartAverage
          ? _value.threeDartAverage
          : threeDartAverage // ignore: cast_nullable_to_non_nullable
              as double,
      legsWon: null == legsWon
          ? _value.legsWon
          : legsWon // ignore: cast_nullable_to_non_nullable
              as int,
      totalDartsThrown: null == totalDartsThrown
          ? _value.totalDartsThrown
          : totalDartsThrown // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CompetitorStatsImpl implements _CompetitorStats {
  const _$CompetitorStatsImpl(
      {required this.competitorId,
      required this.competitorName,
      required final List<PlayerTurnStats> byPlayer,
      required this.threeDartAverage,
      required this.legsWon,
      required this.totalDartsThrown})
      : _byPlayer = byPlayer;

  factory _$CompetitorStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompetitorStatsImplFromJson(json);

  @override
  final String competitorId;
  @override
  final String competitorName;
  final List<PlayerTurnStats> _byPlayer;
  @override
  List<PlayerTurnStats> get byPlayer {
    if (_byPlayer is EqualUnmodifiableListView) return _byPlayer;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_byPlayer);
  }

  @override
  final double threeDartAverage;
  @override
  final int legsWon;
  @override
  final int totalDartsThrown;

  @override
  String toString() {
    return 'CompetitorStats(competitorId: $competitorId, competitorName: $competitorName, byPlayer: $byPlayer, threeDartAverage: $threeDartAverage, legsWon: $legsWon, totalDartsThrown: $totalDartsThrown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompetitorStatsImpl &&
            (identical(other.competitorId, competitorId) ||
                other.competitorId == competitorId) &&
            (identical(other.competitorName, competitorName) ||
                other.competitorName == competitorName) &&
            const DeepCollectionEquality().equals(other._byPlayer, _byPlayer) &&
            (identical(other.threeDartAverage, threeDartAverage) ||
                other.threeDartAverage == threeDartAverage) &&
            (identical(other.legsWon, legsWon) || other.legsWon == legsWon) &&
            (identical(other.totalDartsThrown, totalDartsThrown) ||
                other.totalDartsThrown == totalDartsThrown));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      competitorId,
      competitorName,
      const DeepCollectionEquality().hash(_byPlayer),
      threeDartAverage,
      legsWon,
      totalDartsThrown);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CompetitorStatsImplCopyWith<_$CompetitorStatsImpl> get copyWith =>
      __$$CompetitorStatsImplCopyWithImpl<_$CompetitorStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CompetitorStatsImplToJson(
      this,
    );
  }
}

abstract class _CompetitorStats implements CompetitorStats {
  const factory _CompetitorStats(
      {required final String competitorId,
      required final String competitorName,
      required final List<PlayerTurnStats> byPlayer,
      required final double threeDartAverage,
      required final int legsWon,
      required final int totalDartsThrown}) = _$CompetitorStatsImpl;

  factory _CompetitorStats.fromJson(Map<String, dynamic> json) =
      _$CompetitorStatsImpl.fromJson;

  @override
  String get competitorId;
  @override
  String get competitorName;
  @override
  List<PlayerTurnStats> get byPlayer;
  @override
  double get threeDartAverage;
  @override
  int get legsWon;
  @override
  int get totalDartsThrown;
  @override
  @JsonKey(ignore: true)
  _$$CompetitorStatsImplCopyWith<_$CompetitorStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PlayerTurnStats _$PlayerTurnStatsFromJson(Map<String, dynamic> json) {
  return _PlayerTurnStats.fromJson(json);
}

/// @nodoc
mixin _$PlayerTurnStats {
  String get playerId => throw _privateConstructorUsedError;
  double get threeDartAverage => throw _privateConstructorUsedError;
  int get dartsThrown => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlayerTurnStatsCopyWith<PlayerTurnStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerTurnStatsCopyWith<$Res> {
  factory $PlayerTurnStatsCopyWith(
          PlayerTurnStats value, $Res Function(PlayerTurnStats) then) =
      _$PlayerTurnStatsCopyWithImpl<$Res, PlayerTurnStats>;
  @useResult
  $Res call({String playerId, double threeDartAverage, int dartsThrown});
}

/// @nodoc
class _$PlayerTurnStatsCopyWithImpl<$Res, $Val extends PlayerTurnStats>
    implements $PlayerTurnStatsCopyWith<$Res> {
  _$PlayerTurnStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? threeDartAverage = null,
    Object? dartsThrown = null,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      threeDartAverage: null == threeDartAverage
          ? _value.threeDartAverage
          : threeDartAverage // ignore: cast_nullable_to_non_nullable
              as double,
      dartsThrown: null == dartsThrown
          ? _value.dartsThrown
          : dartsThrown // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerTurnStatsImplCopyWith<$Res>
    implements $PlayerTurnStatsCopyWith<$Res> {
  factory _$$PlayerTurnStatsImplCopyWith(_$PlayerTurnStatsImpl value,
          $Res Function(_$PlayerTurnStatsImpl) then) =
      __$$PlayerTurnStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String playerId, double threeDartAverage, int dartsThrown});
}

/// @nodoc
class __$$PlayerTurnStatsImplCopyWithImpl<$Res>
    extends _$PlayerTurnStatsCopyWithImpl<$Res, _$PlayerTurnStatsImpl>
    implements _$$PlayerTurnStatsImplCopyWith<$Res> {
  __$$PlayerTurnStatsImplCopyWithImpl(
      _$PlayerTurnStatsImpl _value, $Res Function(_$PlayerTurnStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? threeDartAverage = null,
    Object? dartsThrown = null,
  }) {
    return _then(_$PlayerTurnStatsImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      threeDartAverage: null == threeDartAverage
          ? _value.threeDartAverage
          : threeDartAverage // ignore: cast_nullable_to_non_nullable
              as double,
      dartsThrown: null == dartsThrown
          ? _value.dartsThrown
          : dartsThrown // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerTurnStatsImpl implements _PlayerTurnStats {
  const _$PlayerTurnStatsImpl(
      {required this.playerId,
      required this.threeDartAverage,
      required this.dartsThrown});

  factory _$PlayerTurnStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerTurnStatsImplFromJson(json);

  @override
  final String playerId;
  @override
  final double threeDartAverage;
  @override
  final int dartsThrown;

  @override
  String toString() {
    return 'PlayerTurnStats(playerId: $playerId, threeDartAverage: $threeDartAverage, dartsThrown: $dartsThrown)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerTurnStatsImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.threeDartAverage, threeDartAverage) ||
                other.threeDartAverage == threeDartAverage) &&
            (identical(other.dartsThrown, dartsThrown) ||
                other.dartsThrown == dartsThrown));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, playerId, threeDartAverage, dartsThrown);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerTurnStatsImplCopyWith<_$PlayerTurnStatsImpl> get copyWith =>
      __$$PlayerTurnStatsImplCopyWithImpl<_$PlayerTurnStatsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerTurnStatsImplToJson(
      this,
    );
  }
}

abstract class _PlayerTurnStats implements PlayerTurnStats {
  const factory _PlayerTurnStats(
      {required final String playerId,
      required final double threeDartAverage,
      required final int dartsThrown}) = _$PlayerTurnStatsImpl;

  factory _PlayerTurnStats.fromJson(Map<String, dynamic> json) =
      _$PlayerTurnStatsImpl.fromJson;

  @override
  String get playerId;
  @override
  double get threeDartAverage;
  @override
  int get dartsThrown;
  @override
  @JsonKey(ignore: true)
  _$$PlayerTurnStatsImplCopyWith<_$PlayerTurnStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
