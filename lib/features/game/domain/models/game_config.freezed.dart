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



  /// Serializes this GameConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig()';
}


}

/// @nodoc
class $GameConfigCopyWith<$Res>  {
$GameConfigCopyWith(GameConfig _, $Res Function(GameConfig) __);
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int startingScore,  String inStrategy,  String outStrategy)?  x01,TResult Function( String variant,  List<String> numbers,  int pointsToWin)?  cricket,TResult Function()?  aroundTheClock,TResult Function()?  killer,TResult Function()?  baseball,TResult Function()?  golf,TResult Function()?  shanghai,TResult Function()?  scram,TResult Function()?  halveIt,TResult Function()?  highScore,TResult Function()?  blindCricket,TResult Function()?  blindGolf,TResult Function()?  blindKiller,TResult Function()?  blindShanghai,TResult Function()?  chaseTheDragon,required TResult orElse(),}) {final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy);case CricketGameConfig() when cricket != null:
return cricket(_that.variant,_that.numbers,_that.pointsToWin);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock();case KillerGameConfig() when killer != null:
return killer();case BaseballGameConfig() when baseball != null:
return baseball();case GolfGameConfig() when golf != null:
return golf();case ShanghaiGameConfig() when shanghai != null:
return shanghai();case ScramGameConfig() when scram != null:
return scram();case HalveItGameConfig() when halveIt != null:
return halveIt();case HighScoreGameConfig() when highScore != null:
return highScore();case BlindCricketGameConfig() when blindCricket != null:
return blindCricket();case BlindGolfGameConfig() when blindGolf != null:
return blindGolf();case BlindKillerGameConfig() when blindKiller != null:
return blindKiller();case BlindShanghaiGameConfig() when blindShanghai != null:
return blindShanghai();case ChaseTheDragonGameConfig() when chaseTheDragon != null:
return chaseTheDragon();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int startingScore,  String inStrategy,  String outStrategy)  x01,required TResult Function( String variant,  List<String> numbers,  int pointsToWin)  cricket,required TResult Function()  aroundTheClock,required TResult Function()  killer,required TResult Function()  baseball,required TResult Function()  golf,required TResult Function()  shanghai,required TResult Function()  scram,required TResult Function()  halveIt,required TResult Function()  highScore,required TResult Function()  blindCricket,required TResult Function()  blindGolf,required TResult Function()  blindKiller,required TResult Function()  blindShanghai,required TResult Function()  chaseTheDragon,}) {final _that = this;
switch (_that) {
case X01GameConfig():
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy);case CricketGameConfig():
return cricket(_that.variant,_that.numbers,_that.pointsToWin);case AroundTheClockGameConfig():
return aroundTheClock();case KillerGameConfig():
return killer();case BaseballGameConfig():
return baseball();case GolfGameConfig():
return golf();case ShanghaiGameConfig():
return shanghai();case ScramGameConfig():
return scram();case HalveItGameConfig():
return halveIt();case HighScoreGameConfig():
return highScore();case BlindCricketGameConfig():
return blindCricket();case BlindGolfGameConfig():
return blindGolf();case BlindKillerGameConfig():
return blindKiller();case BlindShanghaiGameConfig():
return blindShanghai();case ChaseTheDragonGameConfig():
return chaseTheDragon();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int startingScore,  String inStrategy,  String outStrategy)?  x01,TResult? Function( String variant,  List<String> numbers,  int pointsToWin)?  cricket,TResult? Function()?  aroundTheClock,TResult? Function()?  killer,TResult? Function()?  baseball,TResult? Function()?  golf,TResult? Function()?  shanghai,TResult? Function()?  scram,TResult? Function()?  halveIt,TResult? Function()?  highScore,TResult? Function()?  blindCricket,TResult? Function()?  blindGolf,TResult? Function()?  blindKiller,TResult? Function()?  blindShanghai,TResult? Function()?  chaseTheDragon,}) {final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy);case CricketGameConfig() when cricket != null:
return cricket(_that.variant,_that.numbers,_that.pointsToWin);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock();case KillerGameConfig() when killer != null:
return killer();case BaseballGameConfig() when baseball != null:
return baseball();case GolfGameConfig() when golf != null:
return golf();case ShanghaiGameConfig() when shanghai != null:
return shanghai();case ScramGameConfig() when scram != null:
return scram();case HalveItGameConfig() when halveIt != null:
return halveIt();case HighScoreGameConfig() when highScore != null:
return highScore();case BlindCricketGameConfig() when blindCricket != null:
return blindCricket();case BlindGolfGameConfig() when blindGolf != null:
return blindGolf();case BlindKillerGameConfig() when blindKiller != null:
return blindKiller();case BlindShanghaiGameConfig() when blindShanghai != null:
return blindShanghai();case ChaseTheDragonGameConfig() when chaseTheDragon != null:
return chaseTheDragon();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class X01GameConfig implements GameConfig {
  const X01GameConfig({required this.startingScore, required this.inStrategy, required this.outStrategy, final  String? $type}): $type = $type ?? 'x01';
  factory X01GameConfig.fromJson(Map<String, dynamic> json) => _$X01GameConfigFromJson(json);

 final  int startingScore;
 final  String inStrategy;
// 'straight', 'double', 'master'
 final  String outStrategy;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$X01GameConfigCopyWith<X01GameConfig> get copyWith => _$X01GameConfigCopyWithImpl<X01GameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$X01GameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is X01GameConfig&&(identical(other.startingScore, startingScore) || other.startingScore == startingScore)&&(identical(other.inStrategy, inStrategy) || other.inStrategy == inStrategy)&&(identical(other.outStrategy, outStrategy) || other.outStrategy == outStrategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingScore,inStrategy,outStrategy);

@override
String toString() {
  return 'GameConfig.x01(startingScore: $startingScore, inStrategy: $inStrategy, outStrategy: $outStrategy)';
}


}

/// @nodoc
abstract mixin class $X01GameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $X01GameConfigCopyWith(X01GameConfig value, $Res Function(X01GameConfig) _then) = _$X01GameConfigCopyWithImpl;
@useResult
$Res call({
 int startingScore, String inStrategy, String outStrategy
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
@pragma('vm:prefer-inline') $Res call({Object? startingScore = null,Object? inStrategy = null,Object? outStrategy = null,}) {
  return _then(X01GameConfig(
startingScore: null == startingScore ? _self.startingScore : startingScore // ignore: cast_nullable_to_non_nullable
as int,inStrategy: null == inStrategy ? _self.inStrategy : inStrategy // ignore: cast_nullable_to_non_nullable
as String,outStrategy: null == outStrategy ? _self.outStrategy : outStrategy // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CricketGameConfig implements GameConfig {
  const CricketGameConfig({required this.variant, required final  List<String> numbers, required this.pointsToWin, final  String? $type}): _numbers = numbers,$type = $type ?? 'cricket';
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

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CricketGameConfigCopyWith<CricketGameConfig> get copyWith => _$CricketGameConfigCopyWithImpl<CricketGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CricketGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CricketGameConfig&&(identical(other.variant, variant) || other.variant == variant)&&const DeepCollectionEquality().equals(other._numbers, _numbers)&&(identical(other.pointsToWin, pointsToWin) || other.pointsToWin == pointsToWin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,variant,const DeepCollectionEquality().hash(_numbers),pointsToWin);

@override
String toString() {
  return 'GameConfig.cricket(variant: $variant, numbers: $numbers, pointsToWin: $pointsToWin)';
}


}

/// @nodoc
abstract mixin class $CricketGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $CricketGameConfigCopyWith(CricketGameConfig value, $Res Function(CricketGameConfig) _then) = _$CricketGameConfigCopyWithImpl;
@useResult
$Res call({
 String variant, List<String> numbers, int pointsToWin
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
@pragma('vm:prefer-inline') $Res call({Object? variant = null,Object? numbers = null,Object? pointsToWin = null,}) {
  return _then(CricketGameConfig(
variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String,numbers: null == numbers ? _self._numbers : numbers // ignore: cast_nullable_to_non_nullable
as List<String>,pointsToWin: null == pointsToWin ? _self.pointsToWin : pointsToWin // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class AroundTheClockGameConfig implements GameConfig {
  const AroundTheClockGameConfig({final  String? $type}): $type = $type ?? 'aroundTheClock';
  factory AroundTheClockGameConfig.fromJson(Map<String, dynamic> json) => _$AroundTheClockGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$AroundTheClockGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AroundTheClockGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.aroundTheClock()';
}


}




/// @nodoc
@JsonSerializable()

class KillerGameConfig implements GameConfig {
  const KillerGameConfig({final  String? $type}): $type = $type ?? 'killer';
  factory KillerGameConfig.fromJson(Map<String, dynamic> json) => _$KillerGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$KillerGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KillerGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.killer()';
}


}




/// @nodoc
@JsonSerializable()

class BaseballGameConfig implements GameConfig {
  const BaseballGameConfig({final  String? $type}): $type = $type ?? 'baseball';
  factory BaseballGameConfig.fromJson(Map<String, dynamic> json) => _$BaseballGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BaseballGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BaseballGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.baseball()';
}


}




/// @nodoc
@JsonSerializable()

class GolfGameConfig implements GameConfig {
  const GolfGameConfig({final  String? $type}): $type = $type ?? 'golf';
  factory GolfGameConfig.fromJson(Map<String, dynamic> json) => _$GolfGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$GolfGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GolfGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.golf()';
}


}




/// @nodoc
@JsonSerializable()

class ShanghaiGameConfig implements GameConfig {
  const ShanghaiGameConfig({final  String? $type}): $type = $type ?? 'shanghai';
  factory ShanghaiGameConfig.fromJson(Map<String, dynamic> json) => _$ShanghaiGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ShanghaiGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShanghaiGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.shanghai()';
}


}




/// @nodoc
@JsonSerializable()

class ScramGameConfig implements GameConfig {
  const ScramGameConfig({final  String? $type}): $type = $type ?? 'scram';
  factory ScramGameConfig.fromJson(Map<String, dynamic> json) => _$ScramGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ScramGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScramGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.scram()';
}


}




/// @nodoc
@JsonSerializable()

class HalveItGameConfig implements GameConfig {
  const HalveItGameConfig({final  String? $type}): $type = $type ?? 'halveIt';
  factory HalveItGameConfig.fromJson(Map<String, dynamic> json) => _$HalveItGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$HalveItGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HalveItGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.halveIt()';
}


}




/// @nodoc
@JsonSerializable()

class HighScoreGameConfig implements GameConfig {
  const HighScoreGameConfig({final  String? $type}): $type = $type ?? 'highScore';
  factory HighScoreGameConfig.fromJson(Map<String, dynamic> json) => _$HighScoreGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$HighScoreGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HighScoreGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.highScore()';
}


}




/// @nodoc
@JsonSerializable()

class BlindCricketGameConfig implements GameConfig {
  const BlindCricketGameConfig({final  String? $type}): $type = $type ?? 'blindCricket';
  factory BlindCricketGameConfig.fromJson(Map<String, dynamic> json) => _$BlindCricketGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BlindCricketGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindCricketGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.blindCricket()';
}


}




/// @nodoc
@JsonSerializable()

class BlindGolfGameConfig implements GameConfig {
  const BlindGolfGameConfig({final  String? $type}): $type = $type ?? 'blindGolf';
  factory BlindGolfGameConfig.fromJson(Map<String, dynamic> json) => _$BlindGolfGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BlindGolfGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindGolfGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.blindGolf()';
}


}




/// @nodoc
@JsonSerializable()

class BlindKillerGameConfig implements GameConfig {
  const BlindKillerGameConfig({final  String? $type}): $type = $type ?? 'blindKiller';
  factory BlindKillerGameConfig.fromJson(Map<String, dynamic> json) => _$BlindKillerGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BlindKillerGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindKillerGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.blindKiller()';
}


}




/// @nodoc
@JsonSerializable()

class BlindShanghaiGameConfig implements GameConfig {
  const BlindShanghaiGameConfig({final  String? $type}): $type = $type ?? 'blindShanghai';
  factory BlindShanghaiGameConfig.fromJson(Map<String, dynamic> json) => _$BlindShanghaiGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$BlindShanghaiGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlindShanghaiGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.blindShanghai()';
}


}




/// @nodoc
@JsonSerializable()

class ChaseTheDragonGameConfig implements GameConfig {
  const ChaseTheDragonGameConfig({final  String? $type}): $type = $type ?? 'chaseTheDragon';
  factory ChaseTheDragonGameConfig.fromJson(Map<String, dynamic> json) => _$ChaseTheDragonGameConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ChaseTheDragonGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChaseTheDragonGameConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameConfig.chaseTheDragon()';
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
