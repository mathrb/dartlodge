// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_leg_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerLegSnapshot {

 String get gameId; int get legIndex; DateTime get gameDate; double get ppr; double? get checkoutPct; int? get checkoutScore; int? get startingScore; double? get mpt; double? get practiceScore;
/// Create a copy of PlayerLegSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerLegSnapshotCopyWith<PlayerLegSnapshot> get copyWith => _$PlayerLegSnapshotCopyWithImpl<PlayerLegSnapshot>(this as PlayerLegSnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlayerLegSnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerLegSnapshot&&(identical(other.gameId, _this.gameId) || other.gameId == _this.gameId)&&(identical(other.legIndex, _this.legIndex) || other.legIndex == _this.legIndex)&&(identical(other.gameDate, _this.gameDate) || other.gameDate == _this.gameDate)&&(identical(other.ppr, _this.ppr) || other.ppr == _this.ppr)&&(identical(other.checkoutPct, _this.checkoutPct) || other.checkoutPct == _this.checkoutPct)&&(identical(other.checkoutScore, _this.checkoutScore) || other.checkoutScore == _this.checkoutScore)&&(identical(other.startingScore, _this.startingScore) || other.startingScore == _this.startingScore)&&(identical(other.mpt, _this.mpt) || other.mpt == _this.mpt)&&(identical(other.practiceScore, _this.practiceScore) || other.practiceScore == _this.practiceScore));
}


@override
int get hashCode {
  final _this = this as PlayerLegSnapshot;
  return Object.hash(runtimeType,_this.gameId,_this.legIndex,_this.gameDate,_this.ppr,_this.checkoutPct,_this.checkoutScore,_this.startingScore,_this.mpt,_this.practiceScore);
}

@override
String toString() {
  final _this = this as PlayerLegSnapshot;
  return 'PlayerLegSnapshot(gameId: ${_this.gameId}, legIndex: ${_this.legIndex}, gameDate: ${_this.gameDate}, ppr: ${_this.ppr}, checkoutPct: ${_this.checkoutPct}, checkoutScore: ${_this.checkoutScore}, startingScore: ${_this.startingScore}, mpt: ${_this.mpt}, practiceScore: ${_this.practiceScore})';
}


}

/// @nodoc
abstract mixin class $PlayerLegSnapshotCopyWith<$Res>  {
  factory $PlayerLegSnapshotCopyWith(PlayerLegSnapshot value, $Res Function(PlayerLegSnapshot) _then) = _$PlayerLegSnapshotCopyWithImpl;
@useResult
$Res call({
 String gameId, int legIndex, DateTime gameDate, double ppr, double? checkoutPct, int? checkoutScore, int? startingScore, double? mpt, double? practiceScore
});




}
/// @nodoc
class _$PlayerLegSnapshotCopyWithImpl<$Res>
    implements $PlayerLegSnapshotCopyWith<$Res> {
  _$PlayerLegSnapshotCopyWithImpl(this._self, this._then);

  final PlayerLegSnapshot _self;
  final $Res Function(PlayerLegSnapshot) _then;

/// Create a copy of PlayerLegSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? legIndex = null,Object? gameDate = null,Object? ppr = null,Object? checkoutPct = freezed,Object? checkoutScore = freezed,Object? startingScore = freezed,Object? mpt = freezed,Object? practiceScore = freezed,}) {
  return _then(PlayerLegSnapshot(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,legIndex: null == legIndex ? _self.legIndex : legIndex // ignore: cast_nullable_to_non_nullable
as int,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,ppr: null == ppr ? _self.ppr : ppr // ignore: cast_nullable_to_non_nullable
as double,checkoutPct: freezed == checkoutPct ? _self.checkoutPct : checkoutPct // ignore: cast_nullable_to_non_nullable
as double?,checkoutScore: freezed == checkoutScore ? _self.checkoutScore : checkoutScore // ignore: cast_nullable_to_non_nullable
as int?,startingScore: freezed == startingScore ? _self.startingScore : startingScore // ignore: cast_nullable_to_non_nullable
as int?,mpt: freezed == mpt ? _self.mpt : mpt // ignore: cast_nullable_to_non_nullable
as double?,practiceScore: freezed == practiceScore ? _self.practiceScore : practiceScore // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerLegSnapshot].
extension PlayerLegSnapshotPatterns on PlayerLegSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerLegSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerLegSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerLegSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _PlayerLegSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerLegSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerLegSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  int legIndex,  DateTime gameDate,  double ppr,  double? checkoutPct,  int? checkoutScore,  int? startingScore,  double? mpt,  double? practiceScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerLegSnapshot() when $default != null:
return $default(_that.gameId,_that.legIndex,_that.gameDate,_that.ppr,_that.checkoutPct,_that.checkoutScore,_that.startingScore,_that.mpt,_that.practiceScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  int legIndex,  DateTime gameDate,  double ppr,  double? checkoutPct,  int? checkoutScore,  int? startingScore,  double? mpt,  double? practiceScore)  $default,) {final _that = this;
switch (_that) {
case _PlayerLegSnapshot():
return $default(_that.gameId,_that.legIndex,_that.gameDate,_that.ppr,_that.checkoutPct,_that.checkoutScore,_that.startingScore,_that.mpt,_that.practiceScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  int legIndex,  DateTime gameDate,  double ppr,  double? checkoutPct,  int? checkoutScore,  int? startingScore,  double? mpt,  double? practiceScore)?  $default,) {final _that = this;
switch (_that) {
case _PlayerLegSnapshot() when $default != null:
return $default(_that.gameId,_that.legIndex,_that.gameDate,_that.ppr,_that.checkoutPct,_that.checkoutScore,_that.startingScore,_that.mpt,_that.practiceScore);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerLegSnapshot implements PlayerLegSnapshot {
  const _PlayerLegSnapshot({required this.gameId, required this.legIndex, required this.gameDate, required this.ppr, this.checkoutPct, this.checkoutScore, this.startingScore, this.mpt, this.practiceScore});
  

@override final  String gameId;
@override final  int legIndex;
@override final  DateTime gameDate;
@override final  double ppr;
@override final  double? checkoutPct;
@override final  int? checkoutScore;
@override final  int? startingScore;
@override final  double? mpt;
@override final  double? practiceScore;

/// Create a copy of PlayerLegSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerLegSnapshotCopyWith<_PlayerLegSnapshot> get copyWith => __$PlayerLegSnapshotCopyWithImpl<_PlayerLegSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerLegSnapshot&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.legIndex, legIndex) || other.legIndex == legIndex)&&(identical(other.gameDate, gameDate) || other.gameDate == gameDate)&&(identical(other.ppr, ppr) || other.ppr == ppr)&&(identical(other.checkoutPct, checkoutPct) || other.checkoutPct == checkoutPct)&&(identical(other.checkoutScore, checkoutScore) || other.checkoutScore == checkoutScore)&&(identical(other.startingScore, startingScore) || other.startingScore == startingScore)&&(identical(other.mpt, mpt) || other.mpt == mpt)&&(identical(other.practiceScore, practiceScore) || other.practiceScore == practiceScore));
}


@override
int get hashCode {
    return Object.hash(runtimeType,gameId,legIndex,gameDate,ppr,checkoutPct,checkoutScore,startingScore,mpt,practiceScore);
}

@override
String toString() {
    return 'PlayerLegSnapshot(gameId: $gameId, legIndex: $legIndex, gameDate: $gameDate, ppr: $ppr, checkoutPct: $checkoutPct, checkoutScore: $checkoutScore, startingScore: $startingScore, mpt: $mpt, practiceScore: $practiceScore)';
}


}

/// @nodoc
abstract mixin class _$PlayerLegSnapshotCopyWith<$Res> implements $PlayerLegSnapshotCopyWith<$Res> {
  factory _$PlayerLegSnapshotCopyWith(_PlayerLegSnapshot value, $Res Function(_PlayerLegSnapshot) _then) = __$PlayerLegSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String gameId, int legIndex, DateTime gameDate, double ppr, double? checkoutPct, int? checkoutScore, int? startingScore, double? mpt, double? practiceScore
});




}
/// @nodoc
class __$PlayerLegSnapshotCopyWithImpl<$Res>
    implements _$PlayerLegSnapshotCopyWith<$Res> {
  __$PlayerLegSnapshotCopyWithImpl(this._self, this._then);

  final _PlayerLegSnapshot _self;
  final $Res Function(_PlayerLegSnapshot) _then;

/// Create a copy of PlayerLegSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? legIndex = null,Object? gameDate = null,Object? ppr = null,Object? checkoutPct = freezed,Object? checkoutScore = freezed,Object? startingScore = freezed,Object? mpt = freezed,Object? practiceScore = freezed,}) {
  return _then(_PlayerLegSnapshot(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,legIndex: null == legIndex ? _self.legIndex : legIndex // ignore: cast_nullable_to_non_nullable
as int,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,ppr: null == ppr ? _self.ppr : ppr // ignore: cast_nullable_to_non_nullable
as double,checkoutPct: freezed == checkoutPct ? _self.checkoutPct : checkoutPct // ignore: cast_nullable_to_non_nullable
as double?,checkoutScore: freezed == checkoutScore ? _self.checkoutScore : checkoutScore // ignore: cast_nullable_to_non_nullable
as int?,startingScore: freezed == startingScore ? _self.startingScore : startingScore // ignore: cast_nullable_to_non_nullable
as int?,mpt: freezed == mpt ? _self.mpt : mpt // ignore: cast_nullable_to_non_nullable
as double?,practiceScore: freezed == practiceScore ? _self.practiceScore : practiceScore // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
