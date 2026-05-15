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
                case 'shanghai':
          return ShanghaiGameConfig.fromJson(
            json
          );
                case 'catch40':
          return Catch40GameConfig.fromJson(
            json
          );
                case 'bobs27':
          return Bobs27GameConfig.fromJson(
            json
          );
                case 'checkoutPractice':
          return CheckoutPracticeGameConfig.fromJson(
            json
          );
                case 'countUp':
          return CountUpGameConfig.fromJson(
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

// 'standard', 'reverse', 'doublesOnly'
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( X01GameConfig value)?  x01,TResult Function( CricketGameConfig value)?  cricket,TResult Function( AroundTheClockGameConfig value)?  aroundTheClock,TResult Function( ShanghaiGameConfig value)?  shanghai,TResult Function( Catch40GameConfig value)?  catch40,TResult Function( Bobs27GameConfig value)?  bobs27,TResult Function( CheckoutPracticeGameConfig value)?  checkoutPractice,TResult Function( CountUpGameConfig value)?  countUp,required TResult orElse(),}){
final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that);case CricketGameConfig() when cricket != null:
return cricket(_that);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that);case Catch40GameConfig() when catch40 != null:
return catch40(_that);case Bobs27GameConfig() when bobs27 != null:
return bobs27(_that);case CheckoutPracticeGameConfig() when checkoutPractice != null:
return checkoutPractice(_that);case CountUpGameConfig() when countUp != null:
return countUp(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( X01GameConfig value)  x01,required TResult Function( CricketGameConfig value)  cricket,required TResult Function( AroundTheClockGameConfig value)  aroundTheClock,required TResult Function( ShanghaiGameConfig value)  shanghai,required TResult Function( Catch40GameConfig value)  catch40,required TResult Function( Bobs27GameConfig value)  bobs27,required TResult Function( CheckoutPracticeGameConfig value)  checkoutPractice,required TResult Function( CountUpGameConfig value)  countUp,}){
final _that = this;
switch (_that) {
case X01GameConfig():
return x01(_that);case CricketGameConfig():
return cricket(_that);case AroundTheClockGameConfig():
return aroundTheClock(_that);case ShanghaiGameConfig():
return shanghai(_that);case Catch40GameConfig():
return catch40(_that);case Bobs27GameConfig():
return bobs27(_that);case CheckoutPracticeGameConfig():
return checkoutPractice(_that);case CountUpGameConfig():
return countUp(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( X01GameConfig value)?  x01,TResult? Function( CricketGameConfig value)?  cricket,TResult? Function( AroundTheClockGameConfig value)?  aroundTheClock,TResult? Function( ShanghaiGameConfig value)?  shanghai,TResult? Function( Catch40GameConfig value)?  catch40,TResult? Function( Bobs27GameConfig value)?  bobs27,TResult? Function( CheckoutPracticeGameConfig value)?  checkoutPractice,TResult? Function( CountUpGameConfig value)?  countUp,}){
final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that);case CricketGameConfig() when cricket != null:
return cricket(_that);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that);case Catch40GameConfig() when catch40 != null:
return catch40(_that);case Bobs27GameConfig() when bobs27 != null:
return bobs27(_that);case CheckoutPracticeGameConfig() when checkoutPractice != null:
return checkoutPractice(_that);case CountUpGameConfig() when countUp != null:
return countUp(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int startingScore,  String inStrategy,  String outStrategy,  int legsToWin,  int? totalRounds,  String? startingPlayerId,  Map<String, int> handicaps)?  x01,TResult Function( String variant,  List<String> numbers,  int legsToWin,  int? totalRounds,  String? startingPlayerId)?  cricket,TResult Function( String variant,  String? startingPlayerId)?  aroundTheClock,TResult Function( int totalRounds,  String? startingPlayerId)?  shanghai,TResult Function( String? startingPlayerId)?  catch40,TResult Function( String? startingPlayerId)?  bobs27,TResult Function( String? startingPlayerId,  bool randomOrder,  int? targetSuccesses)?  checkoutPractice,TResult Function( int totalRounds,  Map<String, int> handicaps,  String? startingPlayerId)?  countUp,required TResult orElse(),}) {final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy,_that.legsToWin,_that.totalRounds,_that.startingPlayerId,_that.handicaps);case CricketGameConfig() when cricket != null:
return cricket(_that.variant,_that.numbers,_that.legsToWin,_that.totalRounds,_that.startingPlayerId);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that.variant,_that.startingPlayerId);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that.totalRounds,_that.startingPlayerId);case Catch40GameConfig() when catch40 != null:
return catch40(_that.startingPlayerId);case Bobs27GameConfig() when bobs27 != null:
return bobs27(_that.startingPlayerId);case CheckoutPracticeGameConfig() when checkoutPractice != null:
return checkoutPractice(_that.startingPlayerId,_that.randomOrder,_that.targetSuccesses);case CountUpGameConfig() when countUp != null:
return countUp(_that.totalRounds,_that.handicaps,_that.startingPlayerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int startingScore,  String inStrategy,  String outStrategy,  int legsToWin,  int? totalRounds,  String? startingPlayerId,  Map<String, int> handicaps)  x01,required TResult Function( String variant,  List<String> numbers,  int legsToWin,  int? totalRounds,  String? startingPlayerId)  cricket,required TResult Function( String variant,  String? startingPlayerId)  aroundTheClock,required TResult Function( int totalRounds,  String? startingPlayerId)  shanghai,required TResult Function( String? startingPlayerId)  catch40,required TResult Function( String? startingPlayerId)  bobs27,required TResult Function( String? startingPlayerId,  bool randomOrder,  int? targetSuccesses)  checkoutPractice,required TResult Function( int totalRounds,  Map<String, int> handicaps,  String? startingPlayerId)  countUp,}) {final _that = this;
switch (_that) {
case X01GameConfig():
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy,_that.legsToWin,_that.totalRounds,_that.startingPlayerId,_that.handicaps);case CricketGameConfig():
return cricket(_that.variant,_that.numbers,_that.legsToWin,_that.totalRounds,_that.startingPlayerId);case AroundTheClockGameConfig():
return aroundTheClock(_that.variant,_that.startingPlayerId);case ShanghaiGameConfig():
return shanghai(_that.totalRounds,_that.startingPlayerId);case Catch40GameConfig():
return catch40(_that.startingPlayerId);case Bobs27GameConfig():
return bobs27(_that.startingPlayerId);case CheckoutPracticeGameConfig():
return checkoutPractice(_that.startingPlayerId,_that.randomOrder,_that.targetSuccesses);case CountUpGameConfig():
return countUp(_that.totalRounds,_that.handicaps,_that.startingPlayerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int startingScore,  String inStrategy,  String outStrategy,  int legsToWin,  int? totalRounds,  String? startingPlayerId,  Map<String, int> handicaps)?  x01,TResult? Function( String variant,  List<String> numbers,  int legsToWin,  int? totalRounds,  String? startingPlayerId)?  cricket,TResult? Function( String variant,  String? startingPlayerId)?  aroundTheClock,TResult? Function( int totalRounds,  String? startingPlayerId)?  shanghai,TResult? Function( String? startingPlayerId)?  catch40,TResult? Function( String? startingPlayerId)?  bobs27,TResult? Function( String? startingPlayerId,  bool randomOrder,  int? targetSuccesses)?  checkoutPractice,TResult? Function( int totalRounds,  Map<String, int> handicaps,  String? startingPlayerId)?  countUp,}) {final _that = this;
switch (_that) {
case X01GameConfig() when x01 != null:
return x01(_that.startingScore,_that.inStrategy,_that.outStrategy,_that.legsToWin,_that.totalRounds,_that.startingPlayerId,_that.handicaps);case CricketGameConfig() when cricket != null:
return cricket(_that.variant,_that.numbers,_that.legsToWin,_that.totalRounds,_that.startingPlayerId);case AroundTheClockGameConfig() when aroundTheClock != null:
return aroundTheClock(_that.variant,_that.startingPlayerId);case ShanghaiGameConfig() when shanghai != null:
return shanghai(_that.totalRounds,_that.startingPlayerId);case Catch40GameConfig() when catch40 != null:
return catch40(_that.startingPlayerId);case Bobs27GameConfig() when bobs27 != null:
return bobs27(_that.startingPlayerId);case CheckoutPracticeGameConfig() when checkoutPractice != null:
return checkoutPractice(_that.startingPlayerId,_that.randomOrder,_that.targetSuccesses);case CountUpGameConfig() when countUp != null:
return countUp(_that.totalRounds,_that.handicaps,_that.startingPlayerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class X01GameConfig implements GameConfig {
  const X01GameConfig({required this.startingScore, required this.inStrategy, required this.outStrategy, this.legsToWin = 1, this.totalRounds = null, this.startingPlayerId = null, final  Map<String, int> handicaps = const <String, int>{}, final  String? $type}): _handicaps = handicaps,$type = $type ?? 'x01';
  factory X01GameConfig.fromJson(Map<String, dynamic> json) => _$X01GameConfigFromJson(json);

 final  int startingScore;
 final  String inStrategy;
// 'straight', 'double', 'master'
 final  String outStrategy;
// 'straight', 'double', 'master'
@JsonKey() final  int legsToWin;
@JsonKey() final  int? totalRounds;
@override@JsonKey() final  String? startingPlayerId;
 final  Map<String, int> _handicaps;
@JsonKey() Map<String, int> get handicaps {
  if (_handicaps is EqualUnmodifiableMapView) return _handicaps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_handicaps);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is X01GameConfig&&(identical(other.startingScore, startingScore) || other.startingScore == startingScore)&&(identical(other.inStrategy, inStrategy) || other.inStrategy == inStrategy)&&(identical(other.outStrategy, outStrategy) || other.outStrategy == outStrategy)&&(identical(other.legsToWin, legsToWin) || other.legsToWin == legsToWin)&&(identical(other.totalRounds, totalRounds) || other.totalRounds == totalRounds)&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId)&&const DeepCollectionEquality().equals(other._handicaps, _handicaps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingScore,inStrategy,outStrategy,legsToWin,totalRounds,startingPlayerId,const DeepCollectionEquality().hash(_handicaps));

@override
String toString() {
  return 'GameConfig.x01(startingScore: $startingScore, inStrategy: $inStrategy, outStrategy: $outStrategy, legsToWin: $legsToWin, totalRounds: $totalRounds, startingPlayerId: $startingPlayerId, handicaps: $handicaps)';
}


}

/// @nodoc
abstract mixin class $X01GameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $X01GameConfigCopyWith(X01GameConfig value, $Res Function(X01GameConfig) _then) = _$X01GameConfigCopyWithImpl;
@override @useResult
$Res call({
 int startingScore, String inStrategy, String outStrategy, int legsToWin, int? totalRounds, String? startingPlayerId, Map<String, int> handicaps
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
@override @pragma('vm:prefer-inline') $Res call({Object? startingScore = null,Object? inStrategy = null,Object? outStrategy = null,Object? legsToWin = null,Object? totalRounds = freezed,Object? startingPlayerId = freezed,Object? handicaps = null,}) {
  return _then(X01GameConfig(
startingScore: null == startingScore ? _self.startingScore : startingScore // ignore: cast_nullable_to_non_nullable
as int,inStrategy: null == inStrategy ? _self.inStrategy : inStrategy // ignore: cast_nullable_to_non_nullable
as String,outStrategy: null == outStrategy ? _self.outStrategy : outStrategy // ignore: cast_nullable_to_non_nullable
as String,legsToWin: null == legsToWin ? _self.legsToWin : legsToWin // ignore: cast_nullable_to_non_nullable
as int,totalRounds: freezed == totalRounds ? _self.totalRounds : totalRounds // ignore: cast_nullable_to_non_nullable
as int?,startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,handicaps: null == handicaps ? _self._handicaps : handicaps // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CricketGameConfig implements GameConfig {
  const CricketGameConfig({required this.variant, required final  List<String> numbers, this.legsToWin = 1, this.totalRounds = null, this.startingPlayerId = null, final  String? $type}): _numbers = numbers,$type = $type ?? 'cricket';
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
@JsonKey() final  int legsToWin;
@JsonKey() final  int? totalRounds;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CricketGameConfig&&(identical(other.variant, variant) || other.variant == variant)&&const DeepCollectionEquality().equals(other._numbers, _numbers)&&(identical(other.legsToWin, legsToWin) || other.legsToWin == legsToWin)&&(identical(other.totalRounds, totalRounds) || other.totalRounds == totalRounds)&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,variant,const DeepCollectionEquality().hash(_numbers),legsToWin,totalRounds,startingPlayerId);

@override
String toString() {
  return 'GameConfig.cricket(variant: $variant, numbers: $numbers, legsToWin: $legsToWin, totalRounds: $totalRounds, startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $CricketGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $CricketGameConfigCopyWith(CricketGameConfig value, $Res Function(CricketGameConfig) _then) = _$CricketGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String variant, List<String> numbers, int legsToWin, int? totalRounds, String? startingPlayerId
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
@override @pragma('vm:prefer-inline') $Res call({Object? variant = null,Object? numbers = null,Object? legsToWin = null,Object? totalRounds = freezed,Object? startingPlayerId = freezed,}) {
  return _then(CricketGameConfig(
variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String,numbers: null == numbers ? _self._numbers : numbers // ignore: cast_nullable_to_non_nullable
as List<String>,legsToWin: null == legsToWin ? _self.legsToWin : legsToWin // ignore: cast_nullable_to_non_nullable
as int,totalRounds: freezed == totalRounds ? _self.totalRounds : totalRounds // ignore: cast_nullable_to_non_nullable
as int?,startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class AroundTheClockGameConfig implements GameConfig {
  const AroundTheClockGameConfig({this.variant = 'standard', this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'aroundTheClock';
  factory AroundTheClockGameConfig.fromJson(Map<String, dynamic> json) => _$AroundTheClockGameConfigFromJson(json);

@JsonKey() final  String variant;
// 'standard', 'reverse', 'doublesOnly'
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AroundTheClockGameConfig&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,variant,startingPlayerId);

@override
String toString() {
  return 'GameConfig.aroundTheClock(variant: $variant, startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $AroundTheClockGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $AroundTheClockGameConfigCopyWith(AroundTheClockGameConfig value, $Res Function(AroundTheClockGameConfig) _then) = _$AroundTheClockGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String variant, String? startingPlayerId
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
@override @pragma('vm:prefer-inline') $Res call({Object? variant = null,Object? startingPlayerId = freezed,}) {
  return _then(AroundTheClockGameConfig(
variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as String,startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ShanghaiGameConfig implements GameConfig {
  const ShanghaiGameConfig({this.totalRounds = 7, this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'shanghai';
  factory ShanghaiGameConfig.fromJson(Map<String, dynamic> json) => _$ShanghaiGameConfigFromJson(json);

@JsonKey() final  int totalRounds;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShanghaiGameConfig&&(identical(other.totalRounds, totalRounds) || other.totalRounds == totalRounds)&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalRounds,startingPlayerId);

@override
String toString() {
  return 'GameConfig.shanghai(totalRounds: $totalRounds, startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $ShanghaiGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $ShanghaiGameConfigCopyWith(ShanghaiGameConfig value, $Res Function(ShanghaiGameConfig) _then) = _$ShanghaiGameConfigCopyWithImpl;
@override @useResult
$Res call({
 int totalRounds, String? startingPlayerId
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
@override @pragma('vm:prefer-inline') $Res call({Object? totalRounds = null,Object? startingPlayerId = freezed,}) {
  return _then(ShanghaiGameConfig(
totalRounds: null == totalRounds ? _self.totalRounds : totalRounds // ignore: cast_nullable_to_non_nullable
as int,startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Catch40GameConfig implements GameConfig {
  const Catch40GameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'catch40';
  factory Catch40GameConfig.fromJson(Map<String, dynamic> json) => _$Catch40GameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Catch40GameConfigCopyWith<Catch40GameConfig> get copyWith => _$Catch40GameConfigCopyWithImpl<Catch40GameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Catch40GameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Catch40GameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.catch40(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $Catch40GameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $Catch40GameConfigCopyWith(Catch40GameConfig value, $Res Function(Catch40GameConfig) _then) = _$Catch40GameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$Catch40GameConfigCopyWithImpl<$Res>
    implements $Catch40GameConfigCopyWith<$Res> {
  _$Catch40GameConfigCopyWithImpl(this._self, this._then);

  final Catch40GameConfig _self;
  final $Res Function(Catch40GameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(Catch40GameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Bobs27GameConfig implements GameConfig {
  const Bobs27GameConfig({this.startingPlayerId = null, final  String? $type}): $type = $type ?? 'bobs27';
  factory Bobs27GameConfig.fromJson(Map<String, dynamic> json) => _$Bobs27GameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Bobs27GameConfigCopyWith<Bobs27GameConfig> get copyWith => _$Bobs27GameConfigCopyWithImpl<Bobs27GameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Bobs27GameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bobs27GameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId);

@override
String toString() {
  return 'GameConfig.bobs27(startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $Bobs27GameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $Bobs27GameConfigCopyWith(Bobs27GameConfig value, $Res Function(Bobs27GameConfig) _then) = _$Bobs27GameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId
});




}
/// @nodoc
class _$Bobs27GameConfigCopyWithImpl<$Res>
    implements $Bobs27GameConfigCopyWith<$Res> {
  _$Bobs27GameConfigCopyWithImpl(this._self, this._then);

  final Bobs27GameConfig _self;
  final $Res Function(Bobs27GameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,}) {
  return _then(Bobs27GameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CheckoutPracticeGameConfig implements GameConfig {
  const CheckoutPracticeGameConfig({this.startingPlayerId = null, this.randomOrder = false, this.targetSuccesses = null, final  String? $type}): $type = $type ?? 'checkoutPractice';
  factory CheckoutPracticeGameConfig.fromJson(Map<String, dynamic> json) => _$CheckoutPracticeGameConfigFromJson(json);

@override@JsonKey() final  String? startingPlayerId;
@JsonKey() final  bool randomOrder;
@JsonKey() final  int? targetSuccesses;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutPracticeGameConfigCopyWith<CheckoutPracticeGameConfig> get copyWith => _$CheckoutPracticeGameConfigCopyWithImpl<CheckoutPracticeGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutPracticeGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutPracticeGameConfig&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId)&&(identical(other.randomOrder, randomOrder) || other.randomOrder == randomOrder)&&(identical(other.targetSuccesses, targetSuccesses) || other.targetSuccesses == targetSuccesses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startingPlayerId,randomOrder,targetSuccesses);

@override
String toString() {
  return 'GameConfig.checkoutPractice(startingPlayerId: $startingPlayerId, randomOrder: $randomOrder, targetSuccesses: $targetSuccesses)';
}


}

/// @nodoc
abstract mixin class $CheckoutPracticeGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $CheckoutPracticeGameConfigCopyWith(CheckoutPracticeGameConfig value, $Res Function(CheckoutPracticeGameConfig) _then) = _$CheckoutPracticeGameConfigCopyWithImpl;
@override @useResult
$Res call({
 String? startingPlayerId, bool randomOrder, int? targetSuccesses
});




}
/// @nodoc
class _$CheckoutPracticeGameConfigCopyWithImpl<$Res>
    implements $CheckoutPracticeGameConfigCopyWith<$Res> {
  _$CheckoutPracticeGameConfigCopyWithImpl(this._self, this._then);

  final CheckoutPracticeGameConfig _self;
  final $Res Function(CheckoutPracticeGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startingPlayerId = freezed,Object? randomOrder = null,Object? targetSuccesses = freezed,}) {
  return _then(CheckoutPracticeGameConfig(
startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
as String?,randomOrder: null == randomOrder ? _self.randomOrder : randomOrder // ignore: cast_nullable_to_non_nullable
as bool,targetSuccesses: freezed == targetSuccesses ? _self.targetSuccesses : targetSuccesses // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CountUpGameConfig implements GameConfig {
  const CountUpGameConfig({this.totalRounds = 8, final  Map<String, int> handicaps = const <String, int>{}, this.startingPlayerId = null, final  String? $type}): _handicaps = handicaps,$type = $type ?? 'countUp';
  factory CountUpGameConfig.fromJson(Map<String, dynamic> json) => _$CountUpGameConfigFromJson(json);

@JsonKey() final  int totalRounds;
 final  Map<String, int> _handicaps;
@JsonKey() Map<String, int> get handicaps {
  if (_handicaps is EqualUnmodifiableMapView) return _handicaps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_handicaps);
}

@override@JsonKey() final  String? startingPlayerId;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CountUpGameConfigCopyWith<CountUpGameConfig> get copyWith => _$CountUpGameConfigCopyWithImpl<CountUpGameConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CountUpGameConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CountUpGameConfig&&(identical(other.totalRounds, totalRounds) || other.totalRounds == totalRounds)&&const DeepCollectionEquality().equals(other._handicaps, _handicaps)&&(identical(other.startingPlayerId, startingPlayerId) || other.startingPlayerId == startingPlayerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalRounds,const DeepCollectionEquality().hash(_handicaps),startingPlayerId);

@override
String toString() {
  return 'GameConfig.countUp(totalRounds: $totalRounds, handicaps: $handicaps, startingPlayerId: $startingPlayerId)';
}


}

/// @nodoc
abstract mixin class $CountUpGameConfigCopyWith<$Res> implements $GameConfigCopyWith<$Res> {
  factory $CountUpGameConfigCopyWith(CountUpGameConfig value, $Res Function(CountUpGameConfig) _then) = _$CountUpGameConfigCopyWithImpl;
@override @useResult
$Res call({
 int totalRounds, Map<String, int> handicaps, String? startingPlayerId
});




}
/// @nodoc
class _$CountUpGameConfigCopyWithImpl<$Res>
    implements $CountUpGameConfigCopyWith<$Res> {
  _$CountUpGameConfigCopyWithImpl(this._self, this._then);

  final CountUpGameConfig _self;
  final $Res Function(CountUpGameConfig) _then;

/// Create a copy of GameConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalRounds = null,Object? handicaps = null,Object? startingPlayerId = freezed,}) {
  return _then(CountUpGameConfig(
totalRounds: null == totalRounds ? _self.totalRounds : totalRounds // ignore: cast_nullable_to_non_nullable
as int,handicaps: null == handicaps ? _self._handicaps : handicaps // ignore: cast_nullable_to_non_nullable
as Map<String, int>,startingPlayerId: freezed == startingPlayerId ? _self.startingPlayerId : startingPlayerId // ignore: cast_nullable_to_non_nullable
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
