// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerFormState {

 String get name; String? get nameError; bool get isSubmitting;
/// Create a copy of PlayerFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerFormStateCopyWith<PlayerFormState> get copyWith => _$PlayerFormStateCopyWithImpl<PlayerFormState>(this as PlayerFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerFormState&&(identical(other.name, name) || other.name == name)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,name,nameError,isSubmitting);

@override
String toString() {
  return 'PlayerFormState(name: $name, nameError: $nameError, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class $PlayerFormStateCopyWith<$Res>  {
  factory $PlayerFormStateCopyWith(PlayerFormState value, $Res Function(PlayerFormState) _then) = _$PlayerFormStateCopyWithImpl;
@useResult
$Res call({
 String name, String? nameError, bool isSubmitting
});




}
/// @nodoc
class _$PlayerFormStateCopyWithImpl<$Res>
    implements $PlayerFormStateCopyWith<$Res> {
  _$PlayerFormStateCopyWithImpl(this._self, this._then);

  final PlayerFormState _self;
  final $Res Function(PlayerFormState) _then;

/// Create a copy of PlayerFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? nameError = freezed,Object? isSubmitting = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as String?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerFormState].
extension PlayerFormStatePatterns on PlayerFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerFormState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerFormState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? nameError,  bool isSubmitting)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerFormState() when $default != null:
return $default(_that.name,_that.nameError,_that.isSubmitting);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? nameError,  bool isSubmitting)  $default,) {final _that = this;
switch (_that) {
case _PlayerFormState():
return $default(_that.name,_that.nameError,_that.isSubmitting);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? nameError,  bool isSubmitting)?  $default,) {final _that = this;
switch (_that) {
case _PlayerFormState() when $default != null:
return $default(_that.name,_that.nameError,_that.isSubmitting);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerFormState implements PlayerFormState {
  const _PlayerFormState({required this.name, this.nameError, required this.isSubmitting});
  

@override final  String name;
@override final  String? nameError;
@override final  bool isSubmitting;

/// Create a copy of PlayerFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerFormStateCopyWith<_PlayerFormState> get copyWith => __$PlayerFormStateCopyWithImpl<_PlayerFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerFormState&&(identical(other.name, name) || other.name == name)&&(identical(other.nameError, nameError) || other.nameError == nameError)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,name,nameError,isSubmitting);

@override
String toString() {
  return 'PlayerFormState(name: $name, nameError: $nameError, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class _$PlayerFormStateCopyWith<$Res> implements $PlayerFormStateCopyWith<$Res> {
  factory _$PlayerFormStateCopyWith(_PlayerFormState value, $Res Function(_PlayerFormState) _then) = __$PlayerFormStateCopyWithImpl;
@override @useResult
$Res call({
 String name, String? nameError, bool isSubmitting
});




}
/// @nodoc
class __$PlayerFormStateCopyWithImpl<$Res>
    implements _$PlayerFormStateCopyWith<$Res> {
  __$PlayerFormStateCopyWithImpl(this._self, this._then);

  final _PlayerFormState _self;
  final $Res Function(_PlayerFormState) _then;

/// Create a copy of PlayerFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? nameError = freezed,Object? isSubmitting = null,}) {
  return _then(_PlayerFormState(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameError: freezed == nameError ? _self.nameError : nameError // ignore: cast_nullable_to_non_nullable
as String?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
