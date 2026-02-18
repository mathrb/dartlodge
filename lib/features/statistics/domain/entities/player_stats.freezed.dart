// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PlayerStats _$PlayerStatsFromJson(Map<String, dynamic> json) {
  return _PlayerStats.fromJson(json);
}

/// @nodoc
mixin _$PlayerStats {
  String get playerId => throw _privateConstructorUsedError;
  GameType get gameType => throw _privateConstructorUsedError;
  int get totalGames => throw _privateConstructorUsedError;
  int get gamesWon => throw _privateConstructorUsedError;
  double get winRate => throw _privateConstructorUsedError;
  double get threeDartAverage => throw _privateConstructorUsedError;
  double? get checkoutPercentage =>
      throw _privateConstructorUsedError; // null for non-X01 games
  int? get highestCheckout => throw _privateConstructorUsedError;
  int get highestTurnScore => throw _privateConstructorUsedError;
  int get totalDartsThrown => throw _privateConstructorUsedError;
  double get dartsPerLeg => throw _privateConstructorUsedError;
  double get bustRate => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PlayerStatsCopyWith<PlayerStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStatsCopyWith<$Res> {
  factory $PlayerStatsCopyWith(
          PlayerStats value, $Res Function(PlayerStats) then) =
      _$PlayerStatsCopyWithImpl<$Res, PlayerStats>;
  @useResult
  $Res call(
      {String playerId,
      GameType gameType,
      int totalGames,
      int gamesWon,
      double winRate,
      double threeDartAverage,
      double? checkoutPercentage,
      int? highestCheckout,
      int highestTurnScore,
      int totalDartsThrown,
      double dartsPerLeg,
      double bustRate});
}

/// @nodoc
class _$PlayerStatsCopyWithImpl<$Res, $Val extends PlayerStats>
    implements $PlayerStatsCopyWith<$Res> {
  _$PlayerStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? gameType = null,
    Object? totalGames = null,
    Object? gamesWon = null,
    Object? winRate = null,
    Object? threeDartAverage = null,
    Object? checkoutPercentage = freezed,
    Object? highestCheckout = freezed,
    Object? highestTurnScore = null,
    Object? totalDartsThrown = null,
    Object? dartsPerLeg = null,
    Object? bustRate = null,
  }) {
    return _then(_value.copyWith(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as GameType,
      totalGames: null == totalGames
          ? _value.totalGames
          : totalGames // ignore: cast_nullable_to_non_nullable
              as int,
      gamesWon: null == gamesWon
          ? _value.gamesWon
          : gamesWon // ignore: cast_nullable_to_non_nullable
              as int,
      winRate: null == winRate
          ? _value.winRate
          : winRate // ignore: cast_nullable_to_non_nullable
              as double,
      threeDartAverage: null == threeDartAverage
          ? _value.threeDartAverage
          : threeDartAverage // ignore: cast_nullable_to_non_nullable
              as double,
      checkoutPercentage: freezed == checkoutPercentage
          ? _value.checkoutPercentage
          : checkoutPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      highestCheckout: freezed == highestCheckout
          ? _value.highestCheckout
          : highestCheckout // ignore: cast_nullable_to_non_nullable
              as int?,
      highestTurnScore: null == highestTurnScore
          ? _value.highestTurnScore
          : highestTurnScore // ignore: cast_nullable_to_non_nullable
              as int,
      totalDartsThrown: null == totalDartsThrown
          ? _value.totalDartsThrown
          : totalDartsThrown // ignore: cast_nullable_to_non_nullable
              as int,
      dartsPerLeg: null == dartsPerLeg
          ? _value.dartsPerLeg
          : dartsPerLeg // ignore: cast_nullable_to_non_nullable
              as double,
      bustRate: null == bustRate
          ? _value.bustRate
          : bustRate // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerStatsImplCopyWith<$Res>
    implements $PlayerStatsCopyWith<$Res> {
  factory _$$PlayerStatsImplCopyWith(
          _$PlayerStatsImpl value, $Res Function(_$PlayerStatsImpl) then) =
      __$$PlayerStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String playerId,
      GameType gameType,
      int totalGames,
      int gamesWon,
      double winRate,
      double threeDartAverage,
      double? checkoutPercentage,
      int? highestCheckout,
      int highestTurnScore,
      int totalDartsThrown,
      double dartsPerLeg,
      double bustRate});
}

/// @nodoc
class __$$PlayerStatsImplCopyWithImpl<$Res>
    extends _$PlayerStatsCopyWithImpl<$Res, _$PlayerStatsImpl>
    implements _$$PlayerStatsImplCopyWith<$Res> {
  __$$PlayerStatsImplCopyWithImpl(
      _$PlayerStatsImpl _value, $Res Function(_$PlayerStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playerId = null,
    Object? gameType = null,
    Object? totalGames = null,
    Object? gamesWon = null,
    Object? winRate = null,
    Object? threeDartAverage = null,
    Object? checkoutPercentage = freezed,
    Object? highestCheckout = freezed,
    Object? highestTurnScore = null,
    Object? totalDartsThrown = null,
    Object? dartsPerLeg = null,
    Object? bustRate = null,
  }) {
    return _then(_$PlayerStatsImpl(
      playerId: null == playerId
          ? _value.playerId
          : playerId // ignore: cast_nullable_to_non_nullable
              as String,
      gameType: null == gameType
          ? _value.gameType
          : gameType // ignore: cast_nullable_to_non_nullable
              as GameType,
      totalGames: null == totalGames
          ? _value.totalGames
          : totalGames // ignore: cast_nullable_to_non_nullable
              as int,
      gamesWon: null == gamesWon
          ? _value.gamesWon
          : gamesWon // ignore: cast_nullable_to_non_nullable
              as int,
      winRate: null == winRate
          ? _value.winRate
          : winRate // ignore: cast_nullable_to_non_nullable
              as double,
      threeDartAverage: null == threeDartAverage
          ? _value.threeDartAverage
          : threeDartAverage // ignore: cast_nullable_to_non_nullable
              as double,
      checkoutPercentage: freezed == checkoutPercentage
          ? _value.checkoutPercentage
          : checkoutPercentage // ignore: cast_nullable_to_non_nullable
              as double?,
      highestCheckout: freezed == highestCheckout
          ? _value.highestCheckout
          : highestCheckout // ignore: cast_nullable_to_non_nullable
              as int?,
      highestTurnScore: null == highestTurnScore
          ? _value.highestTurnScore
          : highestTurnScore // ignore: cast_nullable_to_non_nullable
              as int,
      totalDartsThrown: null == totalDartsThrown
          ? _value.totalDartsThrown
          : totalDartsThrown // ignore: cast_nullable_to_non_nullable
              as int,
      dartsPerLeg: null == dartsPerLeg
          ? _value.dartsPerLeg
          : dartsPerLeg // ignore: cast_nullable_to_non_nullable
              as double,
      bustRate: null == bustRate
          ? _value.bustRate
          : bustRate // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerStatsImpl implements _PlayerStats {
  const _$PlayerStatsImpl(
      {required this.playerId,
      required this.gameType,
      required this.totalGames,
      required this.gamesWon,
      required this.winRate,
      required this.threeDartAverage,
      this.checkoutPercentage,
      this.highestCheckout,
      required this.highestTurnScore,
      required this.totalDartsThrown,
      required this.dartsPerLeg,
      required this.bustRate});

  factory _$PlayerStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerStatsImplFromJson(json);

  @override
  final String playerId;
  @override
  final GameType gameType;
  @override
  final int totalGames;
  @override
  final int gamesWon;
  @override
  final double winRate;
  @override
  final double threeDartAverage;
  @override
  final double? checkoutPercentage;
// null for non-X01 games
  @override
  final int? highestCheckout;
  @override
  final int highestTurnScore;
  @override
  final int totalDartsThrown;
  @override
  final double dartsPerLeg;
  @override
  final double bustRate;

  @override
  String toString() {
    return 'PlayerStats(playerId: $playerId, gameType: $gameType, totalGames: $totalGames, gamesWon: $gamesWon, winRate: $winRate, threeDartAverage: $threeDartAverage, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, highestTurnScore: $highestTurnScore, totalDartsThrown: $totalDartsThrown, dartsPerLeg: $dartsPerLeg, bustRate: $bustRate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStatsImpl &&
            (identical(other.playerId, playerId) ||
                other.playerId == playerId) &&
            (identical(other.gameType, gameType) ||
                other.gameType == gameType) &&
            (identical(other.totalGames, totalGames) ||
                other.totalGames == totalGames) &&
            (identical(other.gamesWon, gamesWon) ||
                other.gamesWon == gamesWon) &&
            (identical(other.winRate, winRate) || other.winRate == winRate) &&
            (identical(other.threeDartAverage, threeDartAverage) ||
                other.threeDartAverage == threeDartAverage) &&
            (identical(other.checkoutPercentage, checkoutPercentage) ||
                other.checkoutPercentage == checkoutPercentage) &&
            (identical(other.highestCheckout, highestCheckout) ||
                other.highestCheckout == highestCheckout) &&
            (identical(other.highestTurnScore, highestTurnScore) ||
                other.highestTurnScore == highestTurnScore) &&
            (identical(other.totalDartsThrown, totalDartsThrown) ||
                other.totalDartsThrown == totalDartsThrown) &&
            (identical(other.dartsPerLeg, dartsPerLeg) ||
                other.dartsPerLeg == dartsPerLeg) &&
            (identical(other.bustRate, bustRate) ||
                other.bustRate == bustRate));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      playerId,
      gameType,
      totalGames,
      gamesWon,
      winRate,
      threeDartAverage,
      checkoutPercentage,
      highestCheckout,
      highestTurnScore,
      totalDartsThrown,
      dartsPerLeg,
      bustRate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStatsImplCopyWith<_$PlayerStatsImpl> get copyWith =>
      __$$PlayerStatsImplCopyWithImpl<_$PlayerStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerStatsImplToJson(
      this,
    );
  }
}

abstract class _PlayerStats implements PlayerStats {
  const factory _PlayerStats(
      {required final String playerId,
      required final GameType gameType,
      required final int totalGames,
      required final int gamesWon,
      required final double winRate,
      required final double threeDartAverage,
      final double? checkoutPercentage,
      final int? highestCheckout,
      required final int highestTurnScore,
      required final int totalDartsThrown,
      required final double dartsPerLeg,
      required final double bustRate}) = _$PlayerStatsImpl;

  factory _PlayerStats.fromJson(Map<String, dynamic> json) =
      _$PlayerStatsImpl.fromJson;

  @override
  String get playerId;
  @override
  GameType get gameType;
  @override
  int get totalGames;
  @override
  int get gamesWon;
  @override
  double get winRate;
  @override
  double get threeDartAverage;
  @override
  double? get checkoutPercentage;
  @override // null for non-X01 games
  int? get highestCheckout;
  @override
  int get highestTurnScore;
  @override
  int get totalDartsThrown;
  @override
  double get dartsPerLeg;
  @override
  double get bustRate;
  @override
  @JsonKey(ignore: true)
  _$$PlayerStatsImplCopyWith<_$PlayerStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
