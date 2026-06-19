// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dart_heatmap_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DartHeatmapFilter {

 String get playerId; String? get gameId; GameType? get gameType; DateTime? get from; DateTime? get to;
/// Create a copy of DartHeatmapFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DartHeatmapFilterCopyWith<DartHeatmapFilter> get copyWith => _$DartHeatmapFilterCopyWithImpl<DartHeatmapFilter>(this as DartHeatmapFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DartHeatmapFilter&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,playerId,gameId,gameType,from,to);

@override
String toString() {
  return 'DartHeatmapFilter(playerId: $playerId, gameId: $gameId, gameType: $gameType, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $DartHeatmapFilterCopyWith<$Res>  {
  factory $DartHeatmapFilterCopyWith(DartHeatmapFilter value, $Res Function(DartHeatmapFilter) _then) = _$DartHeatmapFilterCopyWithImpl;
@useResult
$Res call({
 String playerId, String? gameId, GameType? gameType, DateTime? from, DateTime? to
});




}
/// @nodoc
class _$DartHeatmapFilterCopyWithImpl<$Res>
    implements $DartHeatmapFilterCopyWith<$Res> {
  _$DartHeatmapFilterCopyWithImpl(this._self, this._then);

  final DartHeatmapFilter _self;
  final $Res Function(DartHeatmapFilter) _then;

/// Create a copy of DartHeatmapFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? playerId = null,Object? gameId = freezed,Object? gameType = freezed,Object? from = freezed,Object? to = freezed,}) {
  return _then(_self.copyWith(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,gameId: freezed == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String?,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DartHeatmapFilter].
extension DartHeatmapFilterPatterns on DartHeatmapFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DartHeatmapFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DartHeatmapFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DartHeatmapFilter value)  $default,){
final _that = this;
switch (_that) {
case _DartHeatmapFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DartHeatmapFilter value)?  $default,){
final _that = this;
switch (_that) {
case _DartHeatmapFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String playerId,  String? gameId,  GameType? gameType,  DateTime? from,  DateTime? to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DartHeatmapFilter() when $default != null:
return $default(_that.playerId,_that.gameId,_that.gameType,_that.from,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String playerId,  String? gameId,  GameType? gameType,  DateTime? from,  DateTime? to)  $default,) {final _that = this;
switch (_that) {
case _DartHeatmapFilter():
return $default(_that.playerId,_that.gameId,_that.gameType,_that.from,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String playerId,  String? gameId,  GameType? gameType,  DateTime? from,  DateTime? to)?  $default,) {final _that = this;
switch (_that) {
case _DartHeatmapFilter() when $default != null:
return $default(_that.playerId,_that.gameId,_that.gameType,_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc


class _DartHeatmapFilter implements DartHeatmapFilter {
  const _DartHeatmapFilter({required this.playerId, this.gameId, this.gameType, this.from, this.to});
  

@override final  String playerId;
@override final  String? gameId;
@override final  GameType? gameType;
@override final  DateTime? from;
@override final  DateTime? to;

/// Create a copy of DartHeatmapFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DartHeatmapFilterCopyWith<_DartHeatmapFilter> get copyWith => __$DartHeatmapFilterCopyWithImpl<_DartHeatmapFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DartHeatmapFilter&&(identical(other.playerId, playerId) || other.playerId == playerId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.gameType, gameType) || other.gameType == gameType)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode => Object.hash(runtimeType,playerId,gameId,gameType,from,to);

@override
String toString() {
  return 'DartHeatmapFilter(playerId: $playerId, gameId: $gameId, gameType: $gameType, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$DartHeatmapFilterCopyWith<$Res> implements $DartHeatmapFilterCopyWith<$Res> {
  factory _$DartHeatmapFilterCopyWith(_DartHeatmapFilter value, $Res Function(_DartHeatmapFilter) _then) = __$DartHeatmapFilterCopyWithImpl;
@override @useResult
$Res call({
 String playerId, String? gameId, GameType? gameType, DateTime? from, DateTime? to
});




}
/// @nodoc
class __$DartHeatmapFilterCopyWithImpl<$Res>
    implements _$DartHeatmapFilterCopyWith<$Res> {
  __$DartHeatmapFilterCopyWithImpl(this._self, this._then);

  final _DartHeatmapFilter _self;
  final $Res Function(_DartHeatmapFilter) _then;

/// Create a copy of DartHeatmapFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? playerId = null,Object? gameId = freezed,Object? gameType = freezed,Object? from = freezed,Object? to = freezed,}) {
  return _then(_DartHeatmapFilter(
playerId: null == playerId ? _self.playerId : playerId // ignore: cast_nullable_to_non_nullable
as String,gameId: freezed == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String?,gameType: freezed == gameType ? _self.gameType : gameType // ignore: cast_nullable_to_non_nullable
as GameType?,from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as DateTime?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
