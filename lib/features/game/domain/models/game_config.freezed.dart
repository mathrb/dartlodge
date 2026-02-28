// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
GameConfig _$GameConfigFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'x01':
          return X01GameConfig.fromJson(
            json
          );
                case 'cricket':
          return CricketGameConfig.fromJson(
            json
          );
                case 'aroundTheClock':
          return AroundTheClockGameConfig.fromJson(
            json
          );
                case 'killer':
          return KillerGameConfig.fromJson(
            json
          );
                case 'baseball':
          return BaseballGameConfig.fromJson(
            json
          );
                case 'golf':
          return GolfGameConfig.fromJson(
            json
          );
                case 'shanghai':
          return ShanghaiGameConfig.fromJson(
            json
          );
                case 'scram':
          return ScramGameConfig.fromJson(
            json
          );
                case 'halveIt':
          return HalveItGameConfig.fromJson(
            json
          );
                case 'highScore':
          return HighScoreGameConfig.fromJson(
            json
          );
                case 'blindCricket':
          return BlindCricketGameConfig.fromJson(
            json
          );
                case 'blindGolf':
          return BlindGolfGameConfig.fromJson(
            json
          );
                case 'blindKiller':
          return BlindKillerGameConfig.fromJson(
            json
          );
                case 'blindShanghai':
          return BlindShanghaiGameConfig.fromJson(
            json
          );
                case 'chaseTheDragon':
          return ChaseTheDragonGameConfig.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'GameConfig',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$GameConfig {

 String? get startingPlayerId;
/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameConfigCopyWith<GameConfig> get copyWith => _$GameConfigCopyWithImpl<GameConfig>(this as GameConfig, _$identity);

  /// Serializes this GameConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $GameConfigCopyWith<$Res>  {
  factory $GameConfigCopyWith(GameConfig value, $Res Function(GameConfig) _then) = _$GameConfigCopyWithImpl;
@useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$GameConfigCopyWithImpl<$Res>
    implements $GameConfigCopyWith<$Res> {
  _$GameConfigCopyWithImpl(this._self, this._then);

  final GameConfig _self;
  final $Res Function(GameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startingPlayerId = freezed,}) {
  return _then(_self.copyWith(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameConfig].
extension GameConfigPatterns on GameConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( X01GameConfig value)?  x01,TResult Function( CricketGameConfig value)?  cricket,TResult Function( AroundTheClockGameConfig value)?  aroundTheClock,TResult Function( KillerGameConfig value)?  killer,TResult Function( BaseballGameConfig value)?  baseball,TResult Function( GolfGameConfig value)?  golf,TResult Function( ShanghaiGameConfig value)?  shanghai,TResult Function( ScramGameConfig value)?  scram,TResult Function( HalveItGameConfig value)?  halveIt,TResult Function( HighScoreGameConfig value)?  highScore,TResult Function( BlindCricketGameConfig value)?  blindCricket,TResult Function( BlindGolfGameConfig value)?  blindGolf,TResult Function( BlindKillerGameConfig value)?  blindKiller,TResult Function( BlindShanghaiGameConfig value)?  blindShanghai,TResult Function( ChaseTheDragonGameConfig value)?  chaseTheDragon,required TResult orElse(),}){
final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that);case CricketGameConfig() when cricket != null:
return cricket(_that);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that);case KillerGameConfig() when killer != null:
return killer(_that);case BaseballGameConfig() when baseball != null:
return baseball(_that);case GolfGameConfig() when golf != null:
return golf(_that);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that);case ScramGameConfig() when scram != null:
return scram(_that);case HalveItGameConfig() when halveIt != null:
return halveIt(_that);case HighScoreGameConfig() when highScore != null:
return highScore(_that);case BlindCricketGameConfig() when blindCricket != null:
return blindCricket(_that);case BlindGolfGameConfig() when blindGolf != null:
return blindGolf(_that);case BlindKillerGameConfig() when blindKiller != null:
return blindKiller(_that);case BlindShanghaiGameConfig() when blindShanghai != null:
return blindShanghai(_that);case ChaseTheDragonGameConfig() when chaseTheDragon != null:
return chaseTheDragon(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( X01GameConfig value)  x01,required TResult Function( CricketGameConfig value)  cricket,required TResult Function( AroundTheClockGameConfig value)  aroundTheClock,required TResult Function( KillerGameConfig value)  killer,required TResult Function( BaseballGameConfig value)  baseball,required TResult Function( GolfGameConfig value)  golf,required TResult Function( ShanghaiGameConfig value)  shanghai,required TResult Function( ScramGameConfig value)  scram,required TResult Function( HalveItGameConfig value)  halveIt,required TResult Function( HighScoreGameConfig value)  highScore,required TResult Function( BlindCricketGameConfig value)  blindCricket,required TResult Function( BlindGolfGameConfig value)  blindGolf,required TResult Function( BlindKillerGameConfig value)  blindKiller,required TResult Function( BlindShanghaiGameConfig value)  blindShanghai,required TResult Function( ChaseTheDragonGameConfig value)  chaseTheDragon,}){
final _that = this;
switch (_that) {
case X01GameConfig():
return x01(_that);case CricketGameConfig():
return cricket(_that);case AroundTheClockGameConfig():
return aroundTheClock(_that);case KillerGameConfig():
return killer(_that);case BaseballGameConfig():
return baseball(_that);case GolfGameConfig():
return golf(_that);case ShanghaiGameConfig():
return shanghai(_that);case ScramGameConfig():
return scram(_that);case HalveItGameConfig():
return halveIt(_that);case HighScoreGameConfig():
return highScore(_that);case BlindCricketGameConfig():
return blindCricket(_that);case BlindGolfGameConfig():
return blindGolf(_that);case BlindKillerGameConfig():
return blindKiller(_that);case BlindShanghaiGameConfig():
return blindShanghai(_that);case ChaseTheDragonGameConfig():
return chaseTheDragon(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( X01GameConfig value)?  x01,TResult? Function( CricketGameConfig value)?  cricket,TResult? Function( AroundTheClockGameConfig value)?  aroundTheClock,TResult? Function( KillerGameConfig value)?  killer,TResult? Function( BaseballGameConfig value)?  baseball,TResult? Function( GolfGameConfig value)?  golf,TResult? Function( ShanghaiGameConfig value)?  shanghai,TResult? Function( ScramGameConfig value)?  scram,TResult? Function( HalveItGameConfig value)?  halveIt,TResult? Function( HighScoreGameConfig value)?  highScore,TResult? Function( BlindCricketGameConfig value)?  blindCricket,TResult? Function( BlindGolfGameConfig value)?  blindGolf,TResult? Function( BlindKillerGameConfig value)?  blindKiller,TResult? Function( BlindShanghaiGameConfig value)?  blindShanghai,TResult? Function( ChaseTheDragonGameConfig value)?  chaseTheDragon,}){
final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that);case CricketGameConfig() when cricket != null:
return cricket(_that);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that);case KillerGameConfig() when killer != null:
return killer(_that);case BaseballGameConfig() when baseball != null:
return baseball(_that);case GolfGameConfig() when golf != null:
return golf(_that);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that);case ScramGameConfig() when scram != null:
return scram(_that);case HalveItGameConfig() when halveIt != null:
return halveIt(_that);case HighScoreGameConfig() when highScore != null:
return highScore(_that);case BlindCricketGameConfig() when blindCricket != null:
return blindCricket(_that);case BlindGolfGameConfig() when blindGolf != null:
return blindGolf(_that);case BlindKillerGameConfig() when blindKiller != null:
return blindKiller(_that);case BlindShanghaiGameConfig() when blindShanghai != null:
return blindShanghai(_that);case ChaseTheDragonGameConfig() when chaseTheDragon != null:
return chaseTheDragon(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int startingScore,  String inStrategy,  String outStrategy,  int legsToWin,  String? startingPlayerId)?  x01,TResult Function( String variant,  List<String> numbers,  int pointsToWin,  String? startingPlayerId)?  cricket,TResult Function( String? startingPlayerId)?  aroundTheClock,TResult Function( String? startingPlayerId)?  killer,TResult Function( String? startingPlayerId)?  baseball,TResult Function( String? startingPlayerId)?  golf,TResult Function( String? startingPlayerId)?  shanghai,TResult Function( String? startingPlayerId)?  scram,TResult Function( String? startingPlayerId)?  halveIt,TResult Function( String? startingPlayerId)?  highScore,TResult Function( String? startingPlayerId)?  blindCricket,TResult Function( String? startingPlayerId)?  blindGolf,TResult Function( String? startingPlayerId)?  blindKiller,TResult Function( String? startingPlayerId)?  blindShanghai,TResult Function( String? startingPlayerId)?  chaseTheDragon,required TResult orElse(),}) {final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy,_that.legsToWin,_that.startingPlayerId);case CricketGameConfig() when cricket != null:
return cricket(_that.variant,_that.numbers,_that.pointsToWin,_that.startingPlayerId);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that.startingPlayerId);case KillerGameConfig() when killer != null:
return killer(_that.startingPlayerId);case BaseballGameConfig() when baseball != null:
return baseball(_that.startingPlayerId);case GolfGameConfig() when golf != null:
return golf(_that.startingPlayerId);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that.startingPlayerId);case ScramGameConfig() when scram != null:
return scram(_that.startingPlayerId);case HalveItGameConfig() when halveIt != null:
return halveIt(_that.startingPlayerId);case HighScoreGameConfig() when highScore != null:
return highScore(_that.startingPlayerId);case BlindCricketGameConfig() when blindCricket != null:
return blindCricket(_that.startingPlayerId);case BlindGolfGameConfig() when blindGolf != null:
return blindGolf(_that.startingPlayerId);case BlindKillerGameConfig() when blindKiller != null:
return blindKiller(_that.startingPlayerId);case BlindShanghaiGameConfig() when blindShanghai != null:
return blindShanghai(_that.startingPlayerId);case ChaseTheDragonGameConfig() when chaseTheDragon != null:
return chaseTheDragon(_that.startingPlayerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int startingScore,  String inStrategy,  String outStrategy,  int legsToWin,  String? startingPlayerId)  x01,required TResult Function( String variant,  List<String> numbers,  int pointsToWin,  String? startingPlayerId)  cricket,required TResult Function( String? startingPlayerId)  aroundTheClock,required TResult Function( String? startingPlayerId)  killer,required TResult Function( String? startingPlayerId)  baseball,required TResult Function( String? startingPlayerId)  golf,required TResult Function( String? startingPlayerId)  shanghai,required TResult Function( String? startingPlayerId)  scram,required TResult Function( String? startingPlayerId)  halveIt,required TResult Function( String? startingPlayerId)  highScore,required TResult Function( String? startingPlayerId)  blindCricket,required TResult Function( String? startingPlayerId)  blindGolf,required TResult Function( String? startingPlayerId)  blindKiller,required TResult Function( String? startingPlayerId)  blindShanghai,required TResult Function( String? startingPlayerId)  chaseTheDragon,}) {final _that = this;
switch (_that) {
case X01GameConfig():
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy,_that.legsToWin,_that.startingPlayerId);case CricketGameConfig():
return cricket(_that.variant,_that.numbers,_that.pointsToWin,_that.startingPlayerId);case AroundTheClockGameConfig():
return aroundTheClock(_that.startingPlayerId);case KillerGameConfig():
return killer(_that.startingPlayerId);case BaseballGameConfig():
return baseball(_that.startingPlayerId);case GolfGameConfig():
return golf(_that.startingPlayerId);case ShanghaiGameConfig():
return shanghai(_that.startingPlayerId);case ScramGameConfig():
return scram(_that.startingPlayerId);case HalveItGameConfig():
return halveIt(_that.startingPlayerId);case HighScoreGameConfig():
return highScore(_that.startingPlayerId);case BlindCricketGameConfig():
return blindCricket(_that.startingPlayerId);case BlindGolfGameConfig():
return blindGolf(_that.startingPlayerId);case BlindKillerGameConfig():
return blindKiller(_that.startingPlayerId);case BlindShanghaiGameConfig():
return blindShanghai(_that.startingPlayerId);case ChaseTheDragonGameConfig():
return chaseTheDragon(_that.startingPlayerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int startingScore,  String inStrategy,  String outStrategy,  int legsToWin,  String? startingPlayerId)?  x01,TResult? Function( String variant,  List<String> numbers,  int pointsToWin,  String? startingPlayerId)?  cricket,TResult? Function( String? startingPlayerId)?  aroundTheClock,TResult? Function( String? startingPlayerId)?  killer,TResult? Function( String? startingPlayerId)?  baseball,TResult? Function( String? startingPlayerId)?  golf,TResult? Function( String? startingPlayerId)?  shanghai,TResult? Function( String? startingPlayerId)?  scram,TResult? Function( String? startingPlayerId)?  halveIt,TResult? Function( String? startingPlayerId)?  highScore,TResult? Function( String? startingPlayerId)?  blindCricket,TResult? Function( String? startingPlayerId)?  blindGolf,TResult? Function( String? startingPlayerId)?  blindKiller,TResult? Function( String? startingPlayerId)?  blindShanghai,TResult? Function( String? startingPlayerId)?  chaseTheDragon,}) {final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy,_that.legsToWin,_that.startingPlayerId);case CricketGameConfig() when cricket != null:
return cricket(_that.variant,_that.numbers,_that.pointsToWin,_that.startingPlayerId);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that.startingPlayerId);case KillerGameConfig() when killer != null:
return killer(_that.startingPlayerId);case BaseballGameConfig() when baseball != null:
return baseball(_that.startingPlayerId);case GolfGameConfig() when golf != null:
return golf(_that.startingPlayerId);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that.startingPlayerId);case ScramGameConfig() when scram != null:
return scram(_that.startingPlayerId);case HalveItGameConfig() when halveIt != null:
return halveIt(_that.startingPlayerId);case HighScoreGameConfig() when highScore != null:
return highScore(_that.startingPlayerId);case BlindCricketGameConfig() when blindCricket != null:
return blindCricket(_that.startingPlayerId);case BlindGolfGameConfig() when blindGolf != null:
return blindGolf(_that.startingPlayerId);case BlindKillerGameConfig() when blindKiller != null:
return blindKiller(_that.startingPlayerId);case BlindShanghaiGameConfig() when blindShanghai != null:
return blindShanghai(_that.startingPlayerId);case ChaseTheDragonGameConfig() when chaseTheDragon != null:
return chaseTheDragon(_that.startingPlayerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class X01GameConfig implements GameConfig {
  const X01GameConfig({required this.startingScore, required this.inStrategy, required this.outStrategy, this.legsToWin = 1, this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'x01';
  factory X01GameConfig.fromJson(Map<String, dynamic> json) => _$X01GameConfigFromJson(json);

 final  int startingScore;
 final  String inStrategy;
// 'straight', 'double', 'master'
 final  String outStrategy;
// 'straight', 'double', 'master'
@JsonKey() final  int legsToWin;
@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$X01GameConfigCopyWith<X01GameConfig> get copyWith => _$X01GameConfigCopyWithImpl<X01GameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$X01GameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is X01GameConfig&&(identical(other.startingScore, startingScore) || other.startingScore == startingScore)&&(identical(other.inStrategy, inStrategy) || other.inStrategy == inStrategy)&&(identical(other.outStrategy, outStrategy) || other.outStrategy == outStrategy)&&(identical(other.legsToWin, legsToWin) || other.legsToWin == legsToWin)&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingScore,inStrategy,outStrategy,legsToWin,startingPlayerId);

@override
String toString() {
  return 'GameConfig.x01(startingScore: $startingScore, inStrategy: $inStrategy, outStrategy: $outStrategy, legsToWin: $legsToWin, startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $X01GameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $X01GameConfigCopyWith(X01GameConfig value, $Res Function(X01GameConfig) _then) = _$X01GameConfigCopyWithImpl;
@override @useResult
$Res call({
 int startingScore, String inStrategy, String outStrategy, int legsToWin, String? startingPlayerId
});




}
/// @nodoc
class _$X01GameConfigCopyWithImpl<$Res>
    implements $X01GameConfigCopyWith<$Res> {
  _$X01GameConfigCopyWithImpl(this._self, this._then);

  final X01GameConfig _self;
  final $Res Function(X01GameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingScore = null,Object? inStrategy = null,Object? outStrategy = null,Object? legsToWin = null,Object? startingPlayerId = freezed,}) {
  return _then(X01GameConfig(
startingScore: null == startingScore ? _self.startingScore : startingScore // ignore: cast_nullable_to_non_nullable
as int,inStrategy: null == inStrategy ? _self.inStrategy : inStrategy // ignore: cast_nullable_to_non_nullable
as String,outStrategy: null == outStrategy ? _self.outStrategy : outStrategy // ignore: cast_nullable_to_non_nullable
as String,legsToWin: null == legsToWin ? _self.legsToWin : legsToWin // ignore: cast_nullable_to_non_nullable
as int,startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CricketGameConfig implements GameConfig {
  const CricketGameConfig({required this.variant, required final  List<String> numbers, required this.pointsToWin, this.startingPlayerId = null, final  String? $type}): _numbers = numbers,$type = $type ?? 'cricket';
  factory CricketGameConfig.fromJson(Map<String, dynamic> json) => _$CricketGameConfigFromJson(json);

 final  String variant;
// 'standard', 'cut-throat', 'no-score'
 final  List<String> _numbers;
// 'standard', 'cut-throat', 'no-score'
 List<String> get numbers {
  if (_numbers is EqualUnmodifiableListView) return _numbers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_numbers);
}

// ['15', '16', '17', '18', '19', '20', 'bull']
 final  int pointsToWin;
@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CricketGameConfigCopyWith<CricketGameConfig> get copyWith => _$CricketGameConfigCopyWithImpl<CricketGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CricketGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CricketGameConfig&&(identical(other.variant, variant) || other.variant == variant)&&const DeepCollectionEquality().equals(other._numbers, _numbers)&&(identical(other.pointsToWin, pointsToWin) || other.pointsToWin == pointsToWin)&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,variant,const DeepCollectionEquality().hash(_numbers),pointsToWin,startingPlayerId);

@override
String toString() {
  return 'GameConfig.cricket(variant: $variant, numbers: $numbers, pointsToWin: $pointsToWin, startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $CricketGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $CricketGameConfigCopyWith(CricketGameConfig value, $Res Function(CricketGameConfig) _then) = _$CricketGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String variant, List<String> numbers, int pointsToWin, String? startingPlayerId
});




}
/// @nodoc
class _$CricketGameConfigCopyWithImpl<$Res>
    implements $CricketGameConfigCopyWith<$Res> {
  _$CricketGameConfigCopyWithImpl(this._self, this._then);

  final CricketGameConfig _self;
  final $Res Function(CricketGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? variant = null,Object? numbers = null,Object? pointsToWin = null,Object? startingPlayerId = freezed,}) {
  return _then(CricketGameConfig(
variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String,numbers: null == numbers ? _self._numbers : numbers // ignore: cast_nullable_to_non_nullable
as List<String>,pointsToWin: null == pointsToWin ? _self.pointsToWin : pointsToWin // ignore: cast_nullable_to_non_nullable
as int,startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class AroundTheClockGameConfig implements GameConfig {
  const AroundTheClockGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'aroundTheClock';
  factory AroundTheClockGameConfig.fromJson(Map<String, dynamic> json) => _$AroundTheClockGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AroundTheClockGameConfigCopyWith<AroundTheClockGameConfig> get copyWith => _$AroundTheClockGameConfigCopyWithImpl<AroundTheClockGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AroundTheClockGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AroundTheClockGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.aroundTheClock(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $AroundTheClockGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $AroundTheClockGameConfigCopyWith(AroundTheClockGameConfig value, $Res Function(AroundTheClockGameConfig) _then) = _$AroundTheClockGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$AroundTheClockGameConfigCopyWithImpl<$Res>
    implements $AroundTheClockGameConfigCopyWith<$Res> {
  _$AroundTheClockGameConfigCopyWithImpl(this._self, this._then);

  final AroundTheClockGameConfig _self;
  final $Res Function(AroundTheClockGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(AroundTheClockGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class KillerGameConfig implements GameConfig {
  const KillerGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'killer';
  factory KillerGameConfig.fromJson(Map<String, dynamic> json) => _$KillerGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KillerGameConfigCopyWith<KillerGameConfig> get copyWith => _$KillerGameConfigCopyWithImpl<KillerGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KillerGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KillerGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.killer(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $KillerGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $KillerGameConfigCopyWith(KillerGameConfig value, $Res Function(KillerGameConfig) _then) = _$KillerGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$KillerGameConfigCopyWithImpl<$Res>
    implements $KillerGameConfigCopyWith<$Res> {
  _$KillerGameConfigCopyWithImpl(this._self, this._then);

  final KillerGameConfig _self;
  final $Res Function(KillerGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(KillerGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BaseballGameConfig implements GameConfig {
  const BaseballGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'baseball';
  factory BaseballGameConfig.fromJson(Map<String, dynamic> json) => _$BaseballGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BaseballGameConfigCopyWith<BaseballGameConfig> get copyWith => _$BaseballGameConfigCopyWithImpl<BaseballGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BaseballGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BaseballGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.baseball(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $BaseballGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $BaseballGameConfigCopyWith(BaseballGameConfig value, $Res Function(BaseballGameConfig) _then) = _$BaseballGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$BaseballGameConfigCopyWithImpl<$Res>
    implements $BaseballGameConfigCopyWith<$Res> {
  _$BaseballGameConfigCopyWithImpl(this._self, this._then);

  final BaseballGameConfig _self;
  final $Res Function(BaseballGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(BaseballGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GolfGameConfig implements GameConfig {
  const GolfGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'golf';
  factory GolfGameConfig.fromJson(Map<String, dynamic> json) => _$GolfGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GolfGameConfigCopyWith<GolfGameConfig> get copyWith => _$GolfGameConfigCopyWithImpl<GolfGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GolfGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GolfGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.golf(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $GolfGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $GolfGameConfigCopyWith(GolfGameConfig value, $Res Function(GolfGameConfig) _then) = _$GolfGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$GolfGameConfigCopyWithImpl<$Res>
    implements $GolfGameConfigCopyWith<$Res> {
  _$GolfGameConfigCopyWithImpl(this._self, this._then);

  final GolfGameConfig _self;
  final $Res Function(GolfGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(GolfGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ShanghaiGameConfig implements GameConfig {
  const ShanghaiGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'shanghai';
  factory ShanghaiGameConfig.fromJson(Map<String, dynamic> json) => _$ShanghaiGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShanghaiGameConfigCopyWith<ShanghaiGameConfig> get copyWith => _$ShanghaiGameConfigCopyWithImpl<ShanghaiGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShanghaiGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShanghaiGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.shanghai(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $ShanghaiGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $ShanghaiGameConfigCopyWith(ShanghaiGameConfig value, $Res Function(ShanghaiGameConfig) _then) = _$ShanghaiGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$ShanghaiGameConfigCopyWithImpl<$Res>
    implements $ShanghaiGameConfigCopyWith<$Res> {
  _$ShanghaiGameConfigCopyWithImpl(this._self, this._then);

  final ShanghaiGameConfig _self;
  final $Res Function(ShanghaiGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(ShanghaiGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ScramGameConfig implements GameConfig {
  const ScramGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'scram';
  factory ScramGameConfig.fromJson(Map<String, dynamic> json) => _$ScramGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScramGameConfigCopyWith<ScramGameConfig> get copyWith => _$ScramGameConfigCopyWithImpl<ScramGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScramGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScramGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.scram(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $ScramGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $ScramGameConfigCopyWith(ScramGameConfig value, $Res Function(ScramGameConfig) _then) = _$ScramGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$ScramGameConfigCopyWithImpl<$Res>
    implements $ScramGameConfigCopyWith<$Res> {
  _$ScramGameConfigCopyWithImpl(this._self, this._then);

  final ScramGameConfig _self;
  final $Res Function(ScramGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(ScramGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class HalveItGameConfig implements GameConfig {
  const HalveItGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'halveIt';
  factory HalveItGameConfig.fromJson(Map<String, dynamic> json) => _$HalveItGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HalveItGameConfigCopyWith<HalveItGameConfig> get copyWith => _$HalveItGameConfigCopyWithImpl<HalveItGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HalveItGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HalveItGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.halveIt(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $HalveItGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $HalveItGameConfigCopyWith(HalveItGameConfig value, $Res Function(HalveItGameConfig) _then) = _$HalveItGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$HalveItGameConfigCopyWithImpl<$Res>
    implements $HalveItGameConfigCopyWith<$Res> {
  _$HalveItGameConfigCopyWithImpl(this._self, this._then);

  final HalveItGameConfig _self;
  final $Res Function(HalveItGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(HalveItGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class HighScoreGameConfig implements GameConfig {
  const HighScoreGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'highScore';
  factory HighScoreGameConfig.fromJson(Map<String, dynamic> json) => _$HighScoreGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HighScoreGameConfigCopyWith<HighScoreGameConfig> get copyWith => _$HighScoreGameConfigCopyWithImpl<HighScoreGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HighScoreGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighScoreGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.highScore(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $HighScoreGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $HighScoreGameConfigCopyWith(HighScoreGameConfig value, $Res Function(HighScoreGameConfig) _then) = _$HighScoreGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$HighScoreGameConfigCopyWithImpl<$Res>
    implements $HighScoreGameConfigCopyWith<$Res> {
  _$HighScoreGameConfigCopyWithImpl(this._self, this._then);

  final HighScoreGameConfig _self;
  final $Res Function(HighScoreGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(HighScoreGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BlindCricketGameConfig implements GameConfig {
  const BlindCricketGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'blindCricket';
  factory BlindCricketGameConfig.fromJson(Map<String, dynamic> json) => _$BlindCricketGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlindCricketGameConfigCopyWith<BlindCricketGameConfig> get copyWith => _$BlindCricketGameConfigCopyWithImpl<BlindCricketGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlindCricketGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindCricketGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.blindCricket(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $BlindCricketGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $BlindCricketGameConfigCopyWith(BlindCricketGameConfig value, $Res Function(BlindCricketGameConfig) _then) = _$BlindCricketGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$BlindCricketGameConfigCopyWithImpl<$Res>
    implements $BlindCricketGameConfigCopyWith<$Res> {
  _$BlindCricketGameConfigCopyWithImpl(this._self, this._then);

  final BlindCricketGameConfig _self;
  final $Res Function(BlindCricketGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(BlindCricketGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BlindGolfGameConfig implements GameConfig {
  const BlindGolfGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'blindGolf';
  factory BlindGolfGameConfig.fromJson(Map<String, dynamic> json) => _$BlindGolfGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlindGolfGameConfigCopyWith<BlindGolfGameConfig> get copyWith => _$BlindGolfGameConfigCopyWithImpl<BlindGolfGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlindGolfGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindGolfGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.blindGolf(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $BlindGolfGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $BlindGolfGameConfigCopyWith(BlindGolfGameConfig value, $Res Function(BlindGolfGameConfig) _then) = _$BlindGolfGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$BlindGolfGameConfigCopyWithImpl<$Res>
    implements $BlindGolfGameConfigCopyWith<$Res> {
  _$BlindGolfGameConfigCopyWithImpl(this._self, this._then);

  final BlindGolfGameConfig _self;
  final $Res Function(BlindGolfGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(BlindGolfGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BlindKillerGameConfig implements GameConfig {
  const BlindKillerGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'blindKiller';
  factory BlindKillerGameConfig.fromJson(Map<String, dynamic> json) => _$BlindKillerGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlindKillerGameConfigCopyWith<BlindKillerGameConfig> get copyWith => _$BlindKillerGameConfigCopyWithImpl<BlindKillerGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlindKillerGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindKillerGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.blindKiller(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $BlindKillerGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $BlindKillerGameConfigCopyWith(BlindKillerGameConfig value, $Res Function(BlindKillerGameConfig) _then) = _$BlindKillerGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$BlindKillerGameConfigCopyWithImpl<$Res>
    implements $BlindKillerGameConfigCopyWith<$Res> {
  _$BlindKillerGameConfigCopyWithImpl(this._self, this._then);

  final BlindKillerGameConfig _self;
  final $Res Function(BlindKillerGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(BlindKillerGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BlindShanghaiGameConfig implements GameConfig {
  const BlindShanghaiGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'blindShanghai';
  factory BlindShanghaiGameConfig.fromJson(Map<String, dynamic> json) => _$BlindShanghaiGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlindShanghaiGameConfigCopyWith<BlindShanghaiGameConfig> get copyWith => _$BlindShanghaiGameConfigCopyWithImpl<BlindShanghaiGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlindShanghaiGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindShanghaiGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.blindShanghai(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $BlindShanghaiGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $BlindShanghaiGameConfigCopyWith(BlindShanghaiGameConfig value, $Res Function(BlindShanghaiGameConfig) _then) = _$BlindShanghaiGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$BlindShanghaiGameConfigCopyWithImpl<$Res>
    implements $BlindShanghaiGameConfigCopyWith<$Res> {
  _$BlindShanghaiGameConfigCopyWithImpl(this._self, this._then);

  final BlindShanghaiGameConfig _self;
  final $Res Function(BlindShanghaiGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(BlindShanghaiGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChaseTheDragonGameConfig implements GameConfig {
  const ChaseTheDragonGameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'chaseTheDragon';
  factory ChaseTheDragonGameConfig.fromJson(Map<String, dynamic> json) => _$ChaseTheDragonGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChaseTheDragonGameConfigCopyWith<ChaseTheDragonGameConfig> get copyWith => _$ChaseTheDragonGameConfigCopyWithImpl<ChaseTheDragonGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChaseTheDragonGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChaseTheDragonGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.chaseTheDragon(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $ChaseTheDragonGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $ChaseTheDragonGameConfigCopyWith(ChaseTheDragonGameConfig value, $Res Function(ChaseTheDragonGameConfig) _then) = _$ChaseTheDragonGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$ChaseTheDragonGameConfigCopyWithImpl<$Res>
    implements $ChaseTheDragonGameConfigCopyWith<$Res> {
  _$ChaseTheDragonGameConfigCopyWithImpl(this._self, this._then);

  final ChaseTheDragonGameConfig _self;
  final $Res Function(ChaseTheDragonGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(ChaseTheDragonGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Segment {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Segment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Segment()';
}


}

/// @nodoc
class $SegmentCopyWith<$Res>  {
$SegmentCopyWith(Segment _, $Res Function(Segment) __);
}


/// Adds pattern-matching-related methods to [Segment].
extension SegmentPatterns on Segment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SingleSegment value)?  single,TResult Function( DoubleSegment value)?  doubleSegment,TResult Function( TripleSegment value)?  triple,TResult Function( SingleBullSegment value)?  singleBull,TResult Function( DoubleBullSegment value)?  doubleBull,TResult Function( MissSegment value)?  miss,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SingleSegment() when single != null:
return single(_that);case DoubleSegment() when doubleSegment != null:
return doubleSegment(_that);case TripleSegment() when triple != null:
return triple(_that);case SingleBullSegment() when singleBull != null:
return singleBull(_that);case DoubleBullSegment() when doubleBull != null:
return doubleBull(_that);case MissSegment() when miss != null:
return miss(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SingleSegment value)  single,required TResult Function( DoubleSegment value)  doubleSegment,required TResult Function( TripleSegment value)  triple,required TResult Function( SingleBullSegment value)  singleBull,required TResult Function( DoubleBullSegment value)  doubleBull,required TResult Function( MissSegment value)  miss,}){
final _that = this;
switch (_that) {
case SingleSegment():
return single(_that);case DoubleSegment():
return doubleSegment(_that);case TripleSegment():
return triple(_that);case SingleBullSegment():
return singleBull(_that);case DoubleBullSegment():
return doubleBull(_that);case MissSegment():
return miss(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SingleSegment value)?  single,TResult? Function( DoubleSegment value)?  doubleSegment,TResult? Function( TripleSegment value)?  triple,TResult? Function( SingleBullSegment value)?  singleBull,TResult? Function( DoubleBullSegment value)?  doubleBull,TResult? Function( MissSegment value)?  miss,}){
final _that = this;
switch (_that) {
case SingleSegment() when single != null:
return single(_that);case DoubleSegment() when doubleSegment != null:
return doubleSegment(_that);case TripleSegment() when triple != null:
return triple(_that);case SingleBullSegment() when singleBull != null:
return singleBull(_that);case DoubleBullSegment() when doubleBull != null:
return doubleBull(_that);case MissSegment() when miss != null:
return miss(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int number)?  single,TResult Function( int number)?  doubleSegment,TResult Function( int number)?  triple,TResult Function()?  singleBull,TResult Function()?  doubleBull,TResult Function()?  miss,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SingleSegment() when single != null:
return single(_that.number);case DoubleSegment() when doubleSegment != null:
return doubleSegment(_that.number);case TripleSegment() when triple != null:
return triple(_that.number);case SingleBullSegment() when singleBull != null:
return singleBull();case DoubleBullSegment() when doubleBull != null:
return doubleBull();case MissSegment() when miss != null:
return miss();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int number)  single,required TResult Function( int number)  doubleSegment,required TResult Function( int number)  triple,required TResult Function()  singleBull,required TResult Function()  doubleBull,required TResult Function()  miss,}) {final _that = this;
switch (_that) {
case SingleSegment():
return single(_that.number);case DoubleSegment():
return doubleSegment(_that.number);case TripleSegment():
return triple(_that.number);case SingleBullSegment():
return singleBull();case DoubleBullSegment():
return doubleBull();case MissSegment():
return miss();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int number)?  single,TResult? Function( int number)?  doubleSegment,TResult? Function( int number)?  triple,TResult? Function()?  singleBull,TResult? Function()?  doubleBull,TResult? Function()?  miss,}) {final _that = this;
switch (_that) {
case SingleSegment() when single != null:
return single(_that.number);case DoubleSegment() when doubleSegment != null:
return doubleSegment(_that.number);case TripleSegment() when triple != null:
return triple(_that.number);case SingleBullSegment() when singleBull != null:
return singleBull();case DoubleBullSegment() when doubleBull != null:
return doubleBull();case MissSegment() when miss != null:
return miss();case _:
  return null;

}
}

}

/// @nodoc


class SingleSegment extends Segment {
  const SingleSegment(this.number): super._();
  

 final  int number;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SingleSegmentCopyWith<SingleSegment> get copyWith => _$SingleSegmentCopyWithImpl<SingleSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SingleSegment&&(identical(other.number, number) || other.number == number));
}


@override
int get hashCode => Object.hash(runtimeType,number);

@override
String toString() {
  return 'Segment.single(number: $number)';
}


}

/// @nodoc
abstract mixin class $SingleSegmentCopyWith<$Res> implements $SegmentCopyWith<$Res> {
  factory $SingleSegmentCopyWith(SingleSegment value, $Res Function(SingleSegment) _then) = _$SingleSegmentCopyWithImpl;
@useResult
$Res call({
 int number
});




}
/// @nodoc
class _$SingleSegmentCopyWithImpl<$Res>
    implements $SingleSegmentCopyWith<$Res> {
  _$SingleSegmentCopyWithImpl(this._self, this._then);

  final SingleSegment _self;
  final $Res Function(SingleSegment) _then;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? number = null,}) {
  return _then(SingleSegment(
null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class DoubleSegment extends Segment {
  const DoubleSegment(this.number): super._();
  

 final  int number;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DoubleSegmentCopyWith<DoubleSegment> get copyWith => _$DoubleSegmentCopyWithImpl<DoubleSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DoubleSegment&&(identical(other.number, number) || other.number == number));
}


@override
int get hashCode => Object.hash(runtimeType,number);

@override
String toString() {
  return 'Segment.doubleSegment(number: $number)';
}


}

/// @nodoc
abstract mixin class $DoubleSegmentCopyWith<$Res> implements $SegmentCopyWith<$Res> {
  factory $DoubleSegmentCopyWith(DoubleSegment value, $Res Function(DoubleSegment) _then) = _$DoubleSegmentCopyWithImpl;
@useResult
$Res call({
 int number
});




}
/// @nodoc
class _$DoubleSegmentCopyWithImpl<$Res>
    implements $DoubleSegmentCopyWith<$Res> {
  _$DoubleSegmentCopyWithImpl(this._self, this._then);

  final DoubleSegment _self;
  final $Res Function(DoubleSegment) _then;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? number = null,}) {
  return _then(DoubleSegment(
null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class TripleSegment extends Segment {
  const TripleSegment(this.number): super._();
  

 final  int number;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripleSegmentCopyWith<TripleSegment> get copyWith => _$TripleSegmentCopyWithImpl<TripleSegment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripleSegment&&(identical(other.number, number) || other.number == number));
}


@override
int get hashCode => Object.hash(runtimeType,number);

@override
String toString() {
  return 'Segment.triple(number: $number)';
}


}

/// @nodoc
abstract mixin class $TripleSegmentCopyWith<$Res> implements $SegmentCopyWith<$Res> {
  factory $TripleSegmentCopyWith(TripleSegment value, $Res Function(TripleSegment) _then) = _$TripleSegmentCopyWithImpl;
@useResult
$Res call({
 int number
});




}
/// @nodoc
class _$TripleSegmentCopyWithImpl<$Res>
    implements $TripleSegmentCopyWith<$Res> {
  _$TripleSegmentCopyWithImpl(this._self, this._then);

  final TripleSegment _self;
  final $Res Function(TripleSegment) _then;

/// Create a copy of Segment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? number = null,}) {
  return _then(TripleSegment(
null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class SingleBullSegment extends Segment {
  const SingleBullSegment(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SingleBullSegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Segment.singleBull()';
}


}




/// @nodoc


class DoubleBullSegment extends Segment {
  const DoubleBullSegment(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DoubleBullSegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Segment.doubleBull()';
}


}




/// @nodoc


class MissSegment extends Segment {
  const MissSegment(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MissSegment);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Segment.miss()';
}


}




// dart format on
