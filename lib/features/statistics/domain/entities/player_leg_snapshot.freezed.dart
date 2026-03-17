// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_leg_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerLegSnapshot {

 String get gameId; int get legIndex; DateTime get gameDate; double get ppr; double? get checkoutPct; int? get startingScore; double? get mpt;
/// Create a copy of PlayerLegSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerLegSnapshotCopyWith<PlayerLegSnapshot> get copyWith => _$PlayerLegSnapshotCopyWithImpl<PlayerLegSnapshot>(this as PlayerLegSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerLegSnapshot&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.legIndex, legIndex) || other.legIndex == legIndex)&&(identical(other.gameDate, gameDate) || other.gameDate == gameDate)&&(identical(other.ppr, ppr) || other.ppr == ppr)&&(identical(other.checkoutPct, checkoutPct) || other.checkoutPct == checkoutPct)&&(identical(other.startingScore, startingScore) || other.startingScore == startingScore)&&(identical(other.mpt, mpt) || other.mpt == mpt));
}


@override
int get hashCode => Object.hash(runtimeType,gameId,legIndex,gameDate,ppr,checkoutPct,startingScore,mpt);

@override
String toString() {
  return 'PlayerLegSnapshot(gameId: $gameId, legIndex: $legIndex, gameDate: $gameDate, ppr: $ppr, checkoutPct: $checkoutPct, startingScore: $startingScore, mpt: $mpt)';
}


}

/// @nodoc
abstract mixin class $PlayerLegSnapshotCopyWith<$Res>  {
  factory $PlayerLegSnapshotCopyWith(PlayerLegSnapshot value, $Res Function(PlayerLegSnapshot) _then) = _$PlayerLegSnapshotCopyWithImpl;
@useResult
$Res call({
 String gameId, int legIndex, DateTime gameDate, double ppr, double? checkoutPct, int? startingScore, double? mpt
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
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? legIndex = null,Object? gameDate = null,Object? ppr = null,Object? checkoutPct = freezed,Object? startingScore = freezed,Object? mpt = freezed,}) {
  return _then(_self.copyWith(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,legIndex: null == legIndex ? _self.legIndex : legIndex // ignore: cast_nullable_to_non_nullable
as int,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,ppr: null == ppr ? _self.ppr : ppr // ignore: cast_nullable_to_non_nullable
as double,checkoutPct: freezed == checkoutPct ? _self.checkoutPct : checkoutPct // ignore: cast_nullable_to_non_nullable
as double?,startingScore: freezed == startingScore ? _self.startingScore : startingScore // ignore: cast_nullable_to_non_nullable
as int?,mpt: freezed == mpt ? _self.mpt : mpt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  int legIndex,  DateTime gameDate,  double ppr,  double? checkoutPct,  int? startingScore,  double? mpt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerLegSnapshot() when $default != null:
return $default(_that.gameId,_that.legIndex,_that.gameDate,_that.ppr,_that.checkoutPct,_that.startingScore,_that.mpt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  int legIndex,  DateTime gameDate,  double ppr,  double? checkoutPct,  int? startingScore,  double? mpt)  $default,) {final _that = this;
switch (_that) {
case _PlayerLegSnapshot():
return $default(_that.gameId,_that.legIndex,_that.gameDate,_that.ppr,_that.checkoutPct,_that.startingScore,_that.mpt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  int legIndex,  DateTime gameDate,  double ppr,  double? checkoutPct,  int? startingScore,  double? mpt)?  $default,) {final _that = this;
switch (_that) {
case _PlayerLegSnapshot() when $default != null:
return $default(_that.gameId,_that.legIndex,_that.gameDate,_that.ppr,_that.checkoutPct,_that.startingScore,_that.mpt);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerLegSnapshot implements PlayerLegSnapshot {
  const _PlayerLegSnapshot({required this.gameId, required this.legIndex, required this.gameDate, required this.ppr, this.checkoutPct, this.startingScore, this.mpt});
  

@override final  String gameId;
@override final  int legIndex;
@override final  DateTime gameDate;
@override final  double ppr;
@override final  double? checkoutPct;
@override final  int? startingScore;
@override final  double? mpt;

/// Create a copy of PlayerLegSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerLegSnapshotCopyWith<_PlayerLegSnapshot> get copyWith => __$PlayerLegSnapshotCopyWithImpl<_PlayerLegSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerLegSnapshot&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.legIndex, legIndex) || other.legIndex == legIndex)&&(identical(other.gameDate, gameDate) || other.gameDate == gameDate)&&(identical(other.ppr, ppr) || other.ppr == ppr)&&(identical(other.checkoutPct, checkoutPct) || other.checkoutPct == checkoutPct)&&(identical(other.startingScore, startingScore) || other.startingScore == startingScore)&&(identical(other.mpt, mpt) || other.mpt == mpt));
}


@override
int get hashCode => Object.hash(runtimeType,gameId,legIndex,gameDate,ppr,checkoutPct,startingScore,mpt);

@override
String toString() {
  return 'PlayerLegSnapshot(gameId: $gameId, legIndex: $legIndex, gameDate: $gameDate, ppr: $ppr, checkoutPct: $checkoutPct, startingScore: $startingScore, mpt: $mpt)';
}


}

/// @nodoc
abstract mixin class _$PlayerLegSnapshotCopyWith<$Res> implements $PlayerLegSnapshotCopyWith<$Res> {
  factory _$PlayerLegSnapshotCopyWith(_PlayerLegSnapshot value, $Res Function(_PlayerLegSnapshot) _then) = __$PlayerLegSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String gameId, int legIndex, DateTime gameDate, double ppr, double? checkoutPct, int? startingScore, double? mpt
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
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? legIndex = null,Object? gameDate = null,Object? ppr = null,Object? checkoutPct = freezed,Object? startingScore = freezed,Object? mpt = freezed,}) {
  return _then(_PlayerLegSnapshot(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,legIndex: null == legIndex ? _self.legIndex : legIndex // ignore: cast_nullable_to_non_nullable
as int,gameDate: null == gameDate ? _self.gameDate : gameDate // ignore: cast_nullable_to_non_nullable
as DateTime,ppr: null == ppr ? _self.ppr : ppr // ignore: cast_nullable_to_non_nullable
as double,checkoutPct: freezed == checkoutPct ? _self.checkoutPct : checkoutPct // ignore: cast_nullable_to_non_nullable
as double?,startingScore: freezed == startingScore ? _self.startingScore : startingScore // ignore: cast_nullable_to_non_nullable
as int?,mpt: freezed == mpt ? _self.mpt : mpt // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
