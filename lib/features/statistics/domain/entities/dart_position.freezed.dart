// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dart_position.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DartPosition {

 double get x; double get y; String? get segment;
/// Create a copy of DartPosition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DartPositionCopyWith<DartPosition> get copyWith => _$DartPositionCopyWithImpl<DartPosition>(this as DartPosition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DartPosition&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.segment, segment) || other.segment == segment));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,segment);

@override
String toString() {
  return 'DartPosition(x: $x, y: $y, segment: $segment)';
}


}

/// @nodoc
abstract mixin class $DartPositionCopyWith<$Res>  {
  factory $DartPositionCopyWith(DartPosition value, $Res Function(DartPosition) _then) = _$DartPositionCopyWithImpl;
@useResult
$Res call({
 double x, double y, String? segment
});




}
/// @nodoc
class _$DartPositionCopyWithImpl<$Res>
    implements $DartPositionCopyWith<$Res> {
  _$DartPositionCopyWithImpl(this._self, this._then);

  final DartPosition _self;
  final $Res Function(DartPosition) _then;

/// Create a copy of DartPosition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,Object? segment = freezed,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DartPosition].
extension DartPositionPatterns on DartPosition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DartPosition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DartPosition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DartPosition value)  $default,){
final _that = this;
switch (_that) {
case _DartPosition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DartPosition value)?  $default,){
final _that = this;
switch (_that) {
case _DartPosition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  double y,  String? segment)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DartPosition() when $default != null:
return $default(_that.x,_that.y,_that.segment);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  double y,  String? segment)  $default,) {final _that = this;
switch (_that) {
case _DartPosition():
return $default(_that.x,_that.y,_that.segment);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  double y,  String? segment)?  $default,) {final _that = this;
switch (_that) {
case _DartPosition() when $default != null:
return $default(_that.x,_that.y,_that.segment);case _:
  return null;

}
}

}

/// @nodoc


class _DartPosition implements DartPosition {
  const _DartPosition({required this.x, required this.y, this.segment});
  

@override final  double x;
@override final  double y;
@override final  String? segment;

/// Create a copy of DartPosition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DartPositionCopyWith<_DartPosition> get copyWith => __$DartPositionCopyWithImpl<_DartPosition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DartPosition&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.segment, segment) || other.segment == segment));
}


@override
int get hashCode => Object.hash(runtimeType,x,y,segment);

@override
String toString() {
  return 'DartPosition(x: $x, y: $y, segment: $segment)';
}


}

/// @nodoc
abstract mixin class _$DartPositionCopyWith<$Res> implements $DartPositionCopyWith<$Res> {
  factory _$DartPositionCopyWith(_DartPosition value, $Res Function(_DartPosition) _then) = __$DartPositionCopyWithImpl;
@override @useResult
$Res call({
 double x, double y, String? segment
});




}
/// @nodoc
class __$DartPositionCopyWithImpl<$Res>
    implements _$DartPositionCopyWith<$Res> {
  __$DartPositionCopyWithImpl(this._self, this._then);

  final _DartPosition _self;
  final $Res Function(_DartPosition) _then;

/// Create a copy of DartPosition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? y = null,Object? segment = freezed,}) {
  return _then(_DartPosition(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,segment: freezed == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
