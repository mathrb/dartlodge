// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
GameResult _$GameResultFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'aroundTheClock':
          return AroundTheClockResult.fromJson(
            json
          );
                case 'catch40':
          return Catch40Result.fromJson(
            json
          );
                case 'bobs27':
          return Bobs27Result.fromJson(
            json
          );
                case 'checkoutPractice':
          return CheckoutPracticeResult.fromJson(
            json
          );
                case 'shanghai':
          return ShanghaiResult.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'GameResult',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$GameResult {



  /// Serializes this GameResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameResult);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GameResult()';
}


}

/// @nodoc
class $GameResultCopyWith<$Res>  {
$GameResultCopyWith(GameResult _, $Res Function(GameResult) __);
}


/// Adds pattern-matching-related methods to [GameResult].
extension GameResultPatterns on GameResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AroundTheClockResult value)?  aroundTheClock,TResult Function( Catch40Result value)?  catch40,TResult Function( Bobs27Result value)?  bobs27,TResult Function( CheckoutPracticeResult value)?  checkoutPractice,TResult Function( ShanghaiResult value)?  shanghai,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that);case Catch40Result() when catch40 != null:
return catch40(_that);case Bobs27Result() when bobs27 != null:
return bobs27(_that);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that);case ShanghaiResult() when shanghai != null:
return shanghai(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AroundTheClockResult value)  aroundTheClock,required TResult Function( Catch40Result value)  catch40,required TResult Function( Bobs27Result value)  bobs27,required TResult Function( CheckoutPracticeResult value)  checkoutPractice,required TResult Function( ShanghaiResult value)  shanghai,}){
final _that = this;
switch (_that) {
case AroundTheClockResult():
return aroundTheClock(_that);case Catch40Result():
return catch40(_that);case Bobs27Result():
return bobs27(_that);case CheckoutPracticeResult():
return checkoutPractice(_that);case ShanghaiResult():
return shanghai(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AroundTheClockResult value)?  aroundTheClock,TResult? Function( Catch40Result value)?  catch40,TResult? Function( Bobs27Result value)?  bobs27,TResult? Function( CheckoutPracticeResult value)?  checkoutPractice,TResult? Function( ShanghaiResult value)?  shanghai,}){
final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that);case Catch40Result() when catch40 != null:
return catch40(_that);case Bobs27Result() when bobs27 != null:
return bobs27(_that);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that);case ShanghaiResult() when shanghai != null:
return shanghai(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<AtcCompetitorResult> competitors,  String? winnerCompetitorId,  bool doublesOnly)?  aroundTheClock,TResult Function( String competitorName,  int score,  int targetsCleared)?  catch40,TResult Function( String competitorName,  int finalScore,  int roundReached,  bool bustedToZero)?  bobs27,TResult Function( String competitorName,  int attempts,  int successes,  int dartsThrown,  int fromScore)?  checkoutPractice,TResult Function( List<ShanghaiCompetitorResult> competitors,  String? winnerCompetitorId,  int totalRounds)?  shanghai,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that.competitors,_that.winnerCompetitorId,_that.doublesOnly);case Catch40Result() when catch40 != null:
return catch40(_that.competitorName,_that.score,_that.targetsCleared);case Bobs27Result() when bobs27 != null:
return bobs27(_that.competitorName,_that.finalScore,_that.roundReached,_that.bustedToZero);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that.competitorName,_that.attempts,_that.successes,_that.dartsThrown,_that.fromScore);case ShanghaiResult() when shanghai != null:
return shanghai(_that.competitors,_that.winnerCompetitorId,_that.totalRounds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<AtcCompetitorResult> competitors,  String? winnerCompetitorId,  bool doublesOnly)  aroundTheClock,required TResult Function( String competitorName,  int score,  int targetsCleared)  catch40,required TResult Function( String competitorName,  int finalScore,  int roundReached,  bool bustedToZero)  bobs27,required TResult Function( String competitorName,  int attempts,  int successes,  int dartsThrown,  int fromScore)  checkoutPractice,required TResult Function( List<ShanghaiCompetitorResult> competitors,  String? winnerCompetitorId,  int totalRounds)  shanghai,}) {final _that = this;
switch (_that) {
case AroundTheClockResult():
return aroundTheClock(_that.competitors,_that.winnerCompetitorId,_that.doublesOnly);case Catch40Result():
return catch40(_that.competitorName,_that.score,_that.targetsCleared);case Bobs27Result():
return bobs27(_that.competitorName,_that.finalScore,_that.roundReached,_that.bustedToZero);case CheckoutPracticeResult():
return checkoutPractice(_that.competitorName,_that.attempts,_that.successes,_that.dartsThrown,_that.fromScore);case ShanghaiResult():
return shanghai(_that.competitors,_that.winnerCompetitorId,_that.totalRounds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<AtcCompetitorResult> competitors,  String? winnerCompetitorId,  bool doublesOnly)?  aroundTheClock,TResult? Function( String competitorName,  int score,  int targetsCleared)?  catch40,TResult? Function( String competitorName,  int finalScore,  int roundReached,  bool bustedToZero)?  bobs27,TResult? Function( String competitorName,  int attempts,  int successes,  int dartsThrown,  int fromScore)?  checkoutPractice,TResult? Function( List<ShanghaiCompetitorResult> competitors,  String? winnerCompetitorId,  int totalRounds)?  shanghai,}) {final _that = this;
switch (_that) {
case AroundTheClockResult() when aroundTheClock != null:
return aroundTheClock(_that.competitors,_that.winnerCompetitorId,_that.doublesOnly);case Catch40Result() when catch40 != null:
return catch40(_that.competitorName,_that.score,_that.targetsCleared);case Bobs27Result() when bobs27 != null:
return bobs27(_that.competitorName,_that.finalScore,_that.roundReached,_that.bustedToZero);case CheckoutPracticeResult() when checkoutPractice != null:
return checkoutPractice(_that.competitorName,_that.attempts,_that.successes,_that.dartsThrown,_that.fromScore);case ShanghaiResult() when shanghai != null:
return shanghai(_that.competitors,_that.winnerCompetitorId,_that.totalRounds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class AroundTheClockResult implements GameResult {
  const AroundTheClockResult({required final  List<AtcCompetitorResult> competitors, required this.winnerCompetitorId, required this.doublesOnly, final  String? $type}): _competitors = competitors,$type = $type ?? 'aroundTheClock';
  factory AroundTheClockResult.fromJson(Map<String, dynamic> json) => _$AroundTheClockResultFromJson(json);

 final  List<AtcCompetitorResult> _competitors;
 List<AtcCompetitorResult> get competitors {
  if (_competitors is EqualUnmodifiableListView) return _competitors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_competitors);
}

 final  String? winnerCompetitorId;
 final  bool doublesOnly;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AroundTheClockResultCopyWith<AroundTheClockResult> get copyWith => _$AroundTheClockResultCopyWithImpl<AroundTheClockResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AroundTheClockResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AroundTheClockResult&&const DeepCollectionEquality().equals(other._competitors, _competitors)&&(identical(other.winnerCompetitorId, winnerCompetitorId) || other.winnerCompetitorId == winnerCompetitorId)&&(identical(other.doublesOnly, doublesOnly) || other.doublesOnly == doublesOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_competitors),winnerCompetitorId,doublesOnly);

@override
String toString() {
  return 'GameResult.aroundTheClock(competitors: $competitors, winnerCompetitorId: $winnerCompetitorId, doublesOnly: $doublesOnly)';
}


}

/// @nodoc
abstract mixin class $AroundTheClockResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $AroundTheClockResultCopyWith(AroundTheClockResult value, $Res Function(AroundTheClockResult) _then) = _$AroundTheClockResultCopyWithImpl;
@useResult
$Res call({
 List<AtcCompetitorResult> competitors, String? winnerCompetitorId, bool doublesOnly
});




}
/// @nodoc
class _$AroundTheClockResultCopyWithImpl<$Res>
    implements $AroundTheClockResultCopyWith<$Res> {
  _$AroundTheClockResultCopyWithImpl(this._self, this._then);

  final AroundTheClockResult _self;
  final $Res Function(AroundTheClockResult) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? competitors = null,Object? winnerCompetitorId = freezed,Object? doublesOnly = null,}) {
  return _then(AroundTheClockResult(
competitors: null == competitors ? _self._competitors : competitors // ignore: cast_nullable_to_non_nullable
as List<AtcCompetitorResult>,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,doublesOnly: null == doublesOnly ? _self.doublesOnly : doublesOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Catch40Result implements GameResult {
  const Catch40Result({required this.competitorName, required this.score, required this.targetsCleared, final  String? $type}): $type = $type ?? 'catch40';
  factory Catch40Result.fromJson(Map<String, dynamic> json) => _$Catch40ResultFromJson(json);

 final  String competitorName;
 final  int score;
 final  int targetsCleared;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Catch40ResultCopyWith<Catch40Result> get copyWith => _$Catch40ResultCopyWithImpl<Catch40Result>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Catch40ResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Catch40Result&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.score, score) || other.score == score)&&(identical(other.targetsCleared, targetsCleared) || other.targetsCleared == targetsCleared));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,score,targetsCleared);

@override
String toString() {
  return 'GameResult.catch40(competitorName: $competitorName, score: $score, targetsCleared: $targetsCleared)';
}


}

/// @nodoc
abstract mixin class $Catch40ResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $Catch40ResultCopyWith(Catch40Result value, $Res Function(Catch40Result) _then) = _$Catch40ResultCopyWithImpl;
@useResult
$Res call({
 String competitorName, int score, int targetsCleared
});




}
/// @nodoc
class _$Catch40ResultCopyWithImpl<$Res>
    implements $Catch40ResultCopyWith<$Res> {
  _$Catch40ResultCopyWithImpl(this._self, this._then);

  final Catch40Result _self;
  final $Res Function(Catch40Result) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? score = null,Object? targetsCleared = null,}) {
  return _then(Catch40Result(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,targetsCleared: null == targetsCleared ? _self.targetsCleared : targetsCleared // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Bobs27Result implements GameResult {
  const Bobs27Result({required this.competitorName, required this.finalScore, required this.roundReached, required this.bustedToZero, final  String? $type}): $type = $type ?? 'bobs27';
  factory Bobs27Result.fromJson(Map<String, dynamic> json) => _$Bobs27ResultFromJson(json);

 final  String competitorName;
 final  int finalScore;
 final  int roundReached;
 final  bool bustedToZero;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Bobs27ResultCopyWith<Bobs27Result> get copyWith => _$Bobs27ResultCopyWithImpl<Bobs27Result>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Bobs27ResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bobs27Result&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.finalScore, finalScore) || other.finalScore == finalScore)&&(identical(other.roundReached, roundReached) || other.roundReached == roundReached)&&(identical(other.bustedToZero, bustedToZero) || other.bustedToZero == bustedToZero));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,finalScore,roundReached,bustedToZero);

@override
String toString() {
  return 'GameResult.bobs27(competitorName: $competitorName, finalScore: $finalScore, roundReached: $roundReached, bustedToZero: $bustedToZero)';
}


}

/// @nodoc
abstract mixin class $Bobs27ResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $Bobs27ResultCopyWith(Bobs27Result value, $Res Function(Bobs27Result) _then) = _$Bobs27ResultCopyWithImpl;
@useResult
$Res call({
 String competitorName, int finalScore, int roundReached, bool bustedToZero
});




}
/// @nodoc
class _$Bobs27ResultCopyWithImpl<$Res>
    implements $Bobs27ResultCopyWith<$Res> {
  _$Bobs27ResultCopyWithImpl(this._self, this._then);

  final Bobs27Result _self;
  final $Res Function(Bobs27Result) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? finalScore = null,Object? roundReached = null,Object? bustedToZero = null,}) {
  return _then(Bobs27Result(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,finalScore: null == finalScore ? _self.finalScore : finalScore // ignore: cast_nullable_to_non_nullable
as int,roundReached: null == roundReached ? _self.roundReached : roundReached // ignore: cast_nullable_to_non_nullable
as int,bustedToZero: null == bustedToZero ? _self.bustedToZero : bustedToZero // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CheckoutPracticeResult implements GameResult {
  const CheckoutPracticeResult({required this.competitorName, required this.attempts, required this.successes, required this.dartsThrown, required this.fromScore, final  String? $type}): $type = $type ?? 'checkoutPractice';
  factory CheckoutPracticeResult.fromJson(Map<String, dynamic> json) => _$CheckoutPracticeResultFromJson(json);

 final  String competitorName;
 final  int attempts;
 final  int successes;
 final  int dartsThrown;
 final  int fromScore;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutPracticeResultCopyWith<CheckoutPracticeResult> get copyWith => _$CheckoutPracticeResultCopyWithImpl<CheckoutPracticeResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutPracticeResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutPracticeResult&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.successes, successes) || other.successes == successes)&&(identical(other.dartsThrown, dartsThrown) || other.dartsThrown == dartsThrown)&&(identical(other.fromScore, fromScore) || other.fromScore == fromScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorName,attempts,successes,dartsThrown,fromScore);

@override
String toString() {
  return 'GameResult.checkoutPractice(competitorName: $competitorName, attempts: $attempts, successes: $successes, dartsThrown: $dartsThrown, fromScore: $fromScore)';
}


}

/// @nodoc
abstract mixin class $CheckoutPracticeResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $CheckoutPracticeResultCopyWith(CheckoutPracticeResult value, $Res Function(CheckoutPracticeResult) _then) = _$CheckoutPracticeResultCopyWithImpl;
@useResult
$Res call({
 String competitorName, int attempts, int successes, int dartsThrown, int fromScore
});




}
/// @nodoc
class _$CheckoutPracticeResultCopyWithImpl<$Res>
    implements $CheckoutPracticeResultCopyWith<$Res> {
  _$CheckoutPracticeResultCopyWithImpl(this._self, this._then);

  final CheckoutPracticeResult _self;
  final $Res Function(CheckoutPracticeResult) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? competitorName = null,Object? attempts = null,Object? successes = null,Object? dartsThrown = null,Object? fromScore = null,}) {
  return _then(CheckoutPracticeResult(
competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,successes: null == successes ? _self.successes : successes // ignore: cast_nullable_to_non_nullable
as int,dartsThrown: null == dartsThrown ? _self.dartsThrown : dartsThrown // ignore: cast_nullable_to_non_nullable
as int,fromScore: null == fromScore ? _self.fromScore : fromScore // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ShanghaiResult implements GameResult {
  const ShanghaiResult({required final  List<ShanghaiCompetitorResult> competitors, required this.winnerCompetitorId, required this.totalRounds, final  String? $type}): _competitors = competitors,$type = $type ?? 'shanghai';
  factory ShanghaiResult.fromJson(Map<String, dynamic> json) => _$ShanghaiResultFromJson(json);

 final  List<ShanghaiCompetitorResult> _competitors;
 List<ShanghaiCompetitorResult> get competitors {
  if (_competitors is EqualUnmodifiableListView) return _competitors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_competitors);
}

 final  String? winnerCompetitorId;
 final  int totalRounds;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShanghaiResultCopyWith<ShanghaiResult> get copyWith => _$ShanghaiResultCopyWithImpl<ShanghaiResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShanghaiResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShanghaiResult&&const DeepCollectionEquality().equals(other._competitors, _competitors)&&(identical(other.winnerCompetitorId, winnerCompetitorId) || other.winnerCompetitorId == winnerCompetitorId)&&(identical(other.totalRounds, totalRounds) || other.totalRounds == totalRounds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_competitors),winnerCompetitorId,totalRounds);

@override
String toString() {
  return 'GameResult.shanghai(competitors: $competitors, winnerCompetitorId: $winnerCompetitorId, totalRounds: $totalRounds)';
}


}

/// @nodoc
abstract mixin class $ShanghaiResultCopyWith<$Res> implements $GameResultCopyWith<$Res> {
  factory $ShanghaiResultCopyWith(ShanghaiResult value, $Res Function(ShanghaiResult) _then) = _$ShanghaiResultCopyWithImpl;
@useResult
$Res call({
 List<ShanghaiCompetitorResult> competitors, String? winnerCompetitorId, int totalRounds
});




}
/// @nodoc
class _$ShanghaiResultCopyWithImpl<$Res>
    implements $ShanghaiResultCopyWith<$Res> {
  _$ShanghaiResultCopyWithImpl(this._self, this._then);

  final ShanghaiResult _self;
  final $Res Function(ShanghaiResult) _then;

/// Create a copy of GameResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? competitors = null,Object? winnerCompetitorId = freezed,Object? totalRounds = null,}) {
  return _then(ShanghaiResult(
competitors: null == competitors ? _self._competitors : competitors // ignore: cast_nullable_to_non_nullable
as List<ShanghaiCompetitorResult>,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,totalRounds: null == totalRounds ? _self.totalRounds : totalRounds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AtcCompetitorResult {

 String get competitorId; String get competitorName; int get turnsCompleted; int get totalDarts; int get lastTargetHit; bool get finished;
/// Create a copy of AtcCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AtcCompetitorResultCopyWith<AtcCompetitorResult> get copyWith => _$AtcCompetitorResultCopyWithImpl<AtcCompetitorResult>(this as AtcCompetitorResult, _$identity);

  /// Serializes this AtcCompetitorResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AtcCompetitorResult&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.turnsCompleted, turnsCompleted) || other.turnsCompleted == turnsCompleted)&&(identical(other.totalDarts, totalDarts) || other.totalDarts == totalDarts)&&(identical(other.lastTargetHit, lastTargetHit) || other.lastTargetHit == lastTargetHit)&&(identical(other.finished, finished) || other.finished == finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,competitorName,turnsCompleted,totalDarts,lastTargetHit,finished);

@override
String toString() {
  return 'AtcCompetitorResult(competitorId: $competitorId, competitorName: $competitorName, turnsCompleted: $turnsCompleted, totalDarts: $totalDarts, lastTargetHit: $lastTargetHit, finished: $finished)';
}


}

/// @nodoc
abstract mixin class $AtcCompetitorResultCopyWith<$Res>  {
  factory $AtcCompetitorResultCopyWith(AtcCompetitorResult value, $Res Function(AtcCompetitorResult) _then) = _$AtcCompetitorResultCopyWithImpl;
@useResult
$Res call({
 String competitorId, String competitorName, int turnsCompleted, int totalDarts, int lastTargetHit, bool finished
});




}
/// @nodoc
class _$AtcCompetitorResultCopyWithImpl<$Res>
    implements $AtcCompetitorResultCopyWith<$Res> {
  _$AtcCompetitorResultCopyWithImpl(this._self, this._then);

  final AtcCompetitorResult _self;
  final $Res Function(AtcCompetitorResult) _then;

/// Create a copy of AtcCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competitorId = null,Object? competitorName = null,Object? turnsCompleted = null,Object? totalDarts = null,Object? lastTargetHit = null,Object? finished = null,}) {
  return _then(_self.copyWith(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,turnsCompleted: null == turnsCompleted ? _self.turnsCompleted : turnsCompleted // ignore: cast_nullable_to_non_nullable
as int,totalDarts: null == totalDarts ? _self.totalDarts : totalDarts // ignore: cast_nullable_to_non_nullable
as int,lastTargetHit: null == lastTargetHit ? _self.lastTargetHit : lastTargetHit // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AtcCompetitorResult].
extension AtcCompetitorResultPatterns on AtcCompetitorResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AtcCompetitorResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AtcCompetitorResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AtcCompetitorResult value)  $default,){
final _that = this;
switch (_that) {
case _AtcCompetitorResult():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AtcCompetitorResult value)?  $default,){
final _that = this;
switch (_that) {
case _AtcCompetitorResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  int turnsCompleted,  int totalDarts,  int lastTargetHit,  bool finished)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AtcCompetitorResult() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.turnsCompleted,_that.totalDarts,_that.lastTargetHit,_that.finished);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  int turnsCompleted,  int totalDarts,  int lastTargetHit,  bool finished)  $default,) {final _that = this;
switch (_that) {
case _AtcCompetitorResult():
return $default(_that.competitorId,_that.competitorName,_that.turnsCompleted,_that.totalDarts,_that.lastTargetHit,_that.finished);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String competitorId,  String competitorName,  int turnsCompleted,  int totalDarts,  int lastTargetHit,  bool finished)?  $default,) {final _that = this;
switch (_that) {
case _AtcCompetitorResult() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.turnsCompleted,_that.totalDarts,_that.lastTargetHit,_that.finished);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AtcCompetitorResult implements AtcCompetitorResult {
  const _AtcCompetitorResult({required this.competitorId, required this.competitorName, required this.turnsCompleted, required this.totalDarts, required this.lastTargetHit, required this.finished});
  factory _AtcCompetitorResult.fromJson(Map<String, dynamic> json) => _$AtcCompetitorResultFromJson(json);

@override final  String competitorId;
@override final  String competitorName;
@override final  int turnsCompleted;
@override final  int totalDarts;
@override final  int lastTargetHit;
@override final  bool finished;

/// Create a copy of AtcCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AtcCompetitorResultCopyWith<_AtcCompetitorResult> get copyWith => __$AtcCompetitorResultCopyWithImpl<_AtcCompetitorResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AtcCompetitorResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AtcCompetitorResult&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.turnsCompleted, turnsCompleted) || other.turnsCompleted == turnsCompleted)&&(identical(other.totalDarts, totalDarts) || other.totalDarts == totalDarts)&&(identical(other.lastTargetHit, lastTargetHit) || other.lastTargetHit == lastTargetHit)&&(identical(other.finished, finished) || other.finished == finished));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,competitorName,turnsCompleted,totalDarts,lastTargetHit,finished);

@override
String toString() {
  return 'AtcCompetitorResult(competitorId: $competitorId, competitorName: $competitorName, turnsCompleted: $turnsCompleted, totalDarts: $totalDarts, lastTargetHit: $lastTargetHit, finished: $finished)';
}


}

/// @nodoc
abstract mixin class _$AtcCompetitorResultCopyWith<$Res> implements $AtcCompetitorResultCopyWith<$Res> {
  factory _$AtcCompetitorResultCopyWith(_AtcCompetitorResult value, $Res Function(_AtcCompetitorResult) _then) = __$AtcCompetitorResultCopyWithImpl;
@override @useResult
$Res call({
 String competitorId, String competitorName, int turnsCompleted, int totalDarts, int lastTargetHit, bool finished
});




}
/// @nodoc
class __$AtcCompetitorResultCopyWithImpl<$Res>
    implements _$AtcCompetitorResultCopyWith<$Res> {
  __$AtcCompetitorResultCopyWithImpl(this._self, this._then);

  final _AtcCompetitorResult _self;
  final $Res Function(_AtcCompetitorResult) _then;

/// Create a copy of AtcCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorId = null,Object? competitorName = null,Object? turnsCompleted = null,Object? totalDarts = null,Object? lastTargetHit = null,Object? finished = null,}) {
  return _then(_AtcCompetitorResult(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,turnsCompleted: null == turnsCompleted ? _self.turnsCompleted : turnsCompleted // ignore: cast_nullable_to_non_nullable
as int,totalDarts: null == totalDarts ? _self.totalDarts : totalDarts // ignore: cast_nullable_to_non_nullable
as int,lastTargetHit: null == lastTargetHit ? _self.lastTargetHit : lastTargetHit // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ShanghaiCompetitorResult {

 String get competitorId; String get competitorName; int get totalScore; int get shanghaiBonuses; int get bestRound; int get roundsPlayed;
/// Create a copy of ShanghaiCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShanghaiCompetitorResultCopyWith<ShanghaiCompetitorResult> get copyWith => _$ShanghaiCompetitorResultCopyWithImpl<ShanghaiCompetitorResult>(this as ShanghaiCompetitorResult, _$identity);

  /// Serializes this ShanghaiCompetitorResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShanghaiCompetitorResult&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&(identical(other.shanghaiBonuses, shanghaiBonuses) || other.shanghaiBonuses == shanghaiBonuses)&&(identical(other.bestRound, bestRound) || other.bestRound == bestRound)&&(identical(other.roundsPlayed, roundsPlayed) || other.roundsPlayed == roundsPlayed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,competitorName,totalScore,shanghaiBonuses,bestRound,roundsPlayed);

@override
String toString() {
  return 'ShanghaiCompetitorResult(competitorId: $competitorId, competitorName: $competitorName, totalScore: $totalScore, shanghaiBonuses: $shanghaiBonuses, bestRound: $bestRound, roundsPlayed: $roundsPlayed)';
}


}

/// @nodoc
abstract mixin class $ShanghaiCompetitorResultCopyWith<$Res>  {
  factory $ShanghaiCompetitorResultCopyWith(ShanghaiCompetitorResult value, $Res Function(ShanghaiCompetitorResult) _then) = _$ShanghaiCompetitorResultCopyWithImpl;
@useResult
$Res call({
 String competitorId, String competitorName, int totalScore, int shanghaiBonuses, int bestRound, int roundsPlayed
});




}
/// @nodoc
class _$ShanghaiCompetitorResultCopyWithImpl<$Res>
    implements $ShanghaiCompetitorResultCopyWith<$Res> {
  _$ShanghaiCompetitorResultCopyWithImpl(this._self, this._then);

  final ShanghaiCompetitorResult _self;
  final $Res Function(ShanghaiCompetitorResult) _then;

/// Create a copy of ShanghaiCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competitorId = null,Object? competitorName = null,Object? totalScore = null,Object? shanghaiBonuses = null,Object? bestRound = null,Object? roundsPlayed = null,}) {
  return _then(_self.copyWith(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,shanghaiBonuses: null == shanghaiBonuses ? _self.shanghaiBonuses : shanghaiBonuses // ignore: cast_nullable_to_non_nullable
as int,bestRound: null == bestRound ? _self.bestRound : bestRound // ignore: cast_nullable_to_non_nullable
as int,roundsPlayed: null == roundsPlayed ? _self.roundsPlayed : roundsPlayed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ShanghaiCompetitorResult].
extension ShanghaiCompetitorResultPatterns on ShanghaiCompetitorResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShanghaiCompetitorResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShanghaiCompetitorResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShanghaiCompetitorResult value)  $default,){
final _that = this;
switch (_that) {
case _ShanghaiCompetitorResult():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShanghaiCompetitorResult value)?  $default,){
final _that = this;
switch (_that) {
case _ShanghaiCompetitorResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  int totalScore,  int shanghaiBonuses,  int bestRound,  int roundsPlayed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShanghaiCompetitorResult() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.totalScore,_that.shanghaiBonuses,_that.bestRound,_that.roundsPlayed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  int totalScore,  int shanghaiBonuses,  int bestRound,  int roundsPlayed)  $default,) {final _that = this;
switch (_that) {
case _ShanghaiCompetitorResult():
return $default(_that.competitorId,_that.competitorName,_that.totalScore,_that.shanghaiBonuses,_that.bestRound,_that.roundsPlayed);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String competitorId,  String competitorName,  int totalScore,  int shanghaiBonuses,  int bestRound,  int roundsPlayed)?  $default,) {final _that = this;
switch (_that) {
case _ShanghaiCompetitorResult() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.totalScore,_that.shanghaiBonuses,_that.bestRound,_that.roundsPlayed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShanghaiCompetitorResult implements ShanghaiCompetitorResult {
  const _ShanghaiCompetitorResult({required this.competitorId, required this.competitorName, required this.totalScore, required this.shanghaiBonuses, required this.bestRound, required this.roundsPlayed});
  factory _ShanghaiCompetitorResult.fromJson(Map<String, dynamic> json) => _$ShanghaiCompetitorResultFromJson(json);

@override final  String competitorId;
@override final  String competitorName;
@override final  int totalScore;
@override final  int shanghaiBonuses;
@override final  int bestRound;
@override final  int roundsPlayed;

/// Create a copy of ShanghaiCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShanghaiCompetitorResultCopyWith<_ShanghaiCompetitorResult> get copyWith => __$ShanghaiCompetitorResultCopyWithImpl<_ShanghaiCompetitorResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShanghaiCompetitorResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShanghaiCompetitorResult&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.totalScore, totalScore) || other.totalScore == totalScore)&&(identical(other.shanghaiBonuses, shanghaiBonuses) || other.shanghaiBonuses == shanghaiBonuses)&&(identical(other.bestRound, bestRound) || other.bestRound == bestRound)&&(identical(other.roundsPlayed, roundsPlayed) || other.roundsPlayed == roundsPlayed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competitorId,competitorName,totalScore,shanghaiBonuses,bestRound,roundsPlayed);

@override
String toString() {
  return 'ShanghaiCompetitorResult(competitorId: $competitorId, competitorName: $competitorName, totalScore: $totalScore, shanghaiBonuses: $shanghaiBonuses, bestRound: $bestRound, roundsPlayed: $roundsPlayed)';
}


}

/// @nodoc
abstract mixin class _$ShanghaiCompetitorResultCopyWith<$Res> implements $ShanghaiCompetitorResultCopyWith<$Res> {
  factory _$ShanghaiCompetitorResultCopyWith(_ShanghaiCompetitorResult value, $Res Function(_ShanghaiCompetitorResult) _then) = __$ShanghaiCompetitorResultCopyWithImpl;
@override @useResult
$Res call({
 String competitorId, String competitorName, int totalScore, int shanghaiBonuses, int bestRound, int roundsPlayed
});




}
/// @nodoc
class __$ShanghaiCompetitorResultCopyWithImpl<$Res>
    implements _$ShanghaiCompetitorResultCopyWith<$Res> {
  __$ShanghaiCompetitorResultCopyWithImpl(this._self, this._then);

  final _ShanghaiCompetitorResult _self;
  final $Res Function(_ShanghaiCompetitorResult) _then;

/// Create a copy of ShanghaiCompetitorResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorId = null,Object? competitorName = null,Object? totalScore = null,Object? shanghaiBonuses = null,Object? bestRound = null,Object? roundsPlayed = null,}) {
  return _then(_ShanghaiCompetitorResult(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,totalScore: null == totalScore ? _self.totalScore : totalScore // ignore: cast_nullable_to_non_nullable
as int,shanghaiBonuses: null == shanghaiBonuses ? _self.shanghaiBonuses : shanghaiBonuses // ignore: cast_nullable_to_non_nullable
as int,bestRound: null == bestRound ? _self.bestRound : bestRound // ignore: cast_nullable_to_non_nullable
as int,roundsPlayed: null == roundsPlayed ? _self.roundsPlayed : roundsPlayed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
