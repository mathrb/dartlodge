// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_stats_page_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlayerStatsPageState {

 StatsTabIndex get activeTab; int? get selectedStartingScore; StatsTimeRange get timeRange; bool get showCheckoutOverlay;
/// Create a copy of PlayerStatsPageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStatsPageStateCopyWith<PlayerStatsPageState> get copyWith => _$PlayerStatsPageStateCopyWithImpl<PlayerStatsPageState>(this as PlayerStatsPageState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerStatsPageState&&(identical(other.activeTab, activeTab) || other.activeTab == activeTab)&&(identical(other.selectedStartingScore, selectedStartingScore) || other.selectedStartingScore == selectedStartingScore)&&(identical(other.timeRange, timeRange) || other.timeRange == timeRange)&&(identical(other.showCheckoutOverlay, showCheckoutOverlay) || other.showCheckoutOverlay == showCheckoutOverlay));
}


@override
int get hashCode => Object.hash(runtimeType,activeTab,selectedStartingScore,timeRange,showCheckoutOverlay);

@override
String toString() {
  return 'PlayerStatsPageState(activeTab: $activeTab, selectedStartingScore: $selectedStartingScore, timeRange: $timeRange, showCheckoutOverlay: $showCheckoutOverlay)';
}


}

/// @nodoc
abstract mixin class $PlayerStatsPageStateCopyWith<$Res>  {
  factory $PlayerStatsPageStateCopyWith(PlayerStatsPageState value, $Res Function(PlayerStatsPageState) _then) = _$PlayerStatsPageStateCopyWithImpl;
@useResult
$Res call({
 StatsTabIndex activeTab, int? selectedStartingScore, StatsTimeRange timeRange, bool showCheckoutOverlay
});




}
/// @nodoc
class _$PlayerStatsPageStateCopyWithImpl<$Res>
    implements $PlayerStatsPageStateCopyWith<$Res> {
  _$PlayerStatsPageStateCopyWithImpl(this._self, this._then);

  final PlayerStatsPageState _self;
  final $Res Function(PlayerStatsPageState) _then;

/// Create a copy of PlayerStatsPageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeTab = null,Object? selectedStartingScore = freezed,Object? timeRange = null,Object? showCheckoutOverlay = null,}) {
  return _then(_self.copyWith(
activeTab: null == activeTab ? _self.activeTab : activeTab // ignore: cast_nullable_to_non_nullable
as StatsTabIndex,selectedStartingScore: freezed == selectedStartingScore ? _self.selectedStartingScore : selectedStartingScore // ignore: cast_nullable_to_non_nullable
as int?,timeRange: null == timeRange ? _self.timeRange : timeRange // ignore: cast_nullable_to_non_nullable
as StatsTimeRange,showCheckoutOverlay: null == showCheckoutOverlay ? _self.showCheckoutOverlay : showCheckoutOverlay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerStatsPageState].
extension PlayerStatsPageStatePatterns on PlayerStatsPageState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerStatsPageState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerStatsPageState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerStatsPageState value)  $default,){
final _that = this;
switch (_that) {
case _PlayerStatsPageState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerStatsPageState value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerStatsPageState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StatsTabIndex activeTab,  int? selectedStartingScore,  StatsTimeRange timeRange,  bool showCheckoutOverlay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerStatsPageState() when $default != null:
return $default(_that.activeTab,_that.selectedStartingScore,_that.timeRange,_that.showCheckoutOverlay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StatsTabIndex activeTab,  int? selectedStartingScore,  StatsTimeRange timeRange,  bool showCheckoutOverlay)  $default,) {final _that = this;
switch (_that) {
case _PlayerStatsPageState():
return $default(_that.activeTab,_that.selectedStartingScore,_that.timeRange,_that.showCheckoutOverlay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StatsTabIndex activeTab,  int? selectedStartingScore,  StatsTimeRange timeRange,  bool showCheckoutOverlay)?  $default,) {final _that = this;
switch (_that) {
case _PlayerStatsPageState() when $default != null:
return $default(_that.activeTab,_that.selectedStartingScore,_that.timeRange,_that.showCheckoutOverlay);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerStatsPageState implements PlayerStatsPageState {
  const _PlayerStatsPageState({this.activeTab = StatsTabIndex.x01, this.selectedStartingScore = null, this.timeRange = StatsTimeRange.all, this.showCheckoutOverlay = false});
  

@override@JsonKey() final  StatsTabIndex activeTab;
@override@JsonKey() final  int? selectedStartingScore;
@override@JsonKey() final  StatsTimeRange timeRange;
@override@JsonKey() final  bool showCheckoutOverlay;

/// Create a copy of PlayerStatsPageState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStatsPageStateCopyWith<_PlayerStatsPageState> get copyWith => __$PlayerStatsPageStateCopyWithImpl<_PlayerStatsPageState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerStatsPageState&&(identical(other.activeTab, activeTab) || other.activeTab == activeTab)&&(identical(other.selectedStartingScore, selectedStartingScore) || other.selectedStartingScore == selectedStartingScore)&&(identical(other.timeRange, timeRange) || other.timeRange == timeRange)&&(identical(other.showCheckoutOverlay, showCheckoutOverlay) || other.showCheckoutOverlay == showCheckoutOverlay));
}


@override
int get hashCode => Object.hash(runtimeType,activeTab,selectedStartingScore,timeRange,showCheckoutOverlay);

@override
String toString() {
  return 'PlayerStatsPageState(activeTab: $activeTab, selectedStartingScore: $selectedStartingScore, timeRange: $timeRange, showCheckoutOverlay: $showCheckoutOverlay)';
}


}

/// @nodoc
abstract mixin class _$PlayerStatsPageStateCopyWith<$Res> implements $PlayerStatsPageStateCopyWith<$Res> {
  factory _$PlayerStatsPageStateCopyWith(_PlayerStatsPageState value, $Res Function(_PlayerStatsPageState) _then) = __$PlayerStatsPageStateCopyWithImpl;
@override @useResult
$Res call({
 StatsTabIndex activeTab, int? selectedStartingScore, StatsTimeRange timeRange, bool showCheckoutOverlay
});




}
/// @nodoc
class __$PlayerStatsPageStateCopyWithImpl<$Res>
    implements _$PlayerStatsPageStateCopyWith<$Res> {
  __$PlayerStatsPageStateCopyWithImpl(this._self, this._then);

  final _PlayerStatsPageState _self;
  final $Res Function(_PlayerStatsPageState) _then;

/// Create a copy of PlayerStatsPageState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeTab = null,Object? selectedStartingScore = freezed,Object? timeRange = null,Object? showCheckoutOverlay = null,}) {
  return _then(_PlayerStatsPageState(
activeTab: null == activeTab ? _self.activeTab : activeTab // ignore: cast_nullable_to_non_nullable
as StatsTabIndex,selectedStartingScore: freezed == selectedStartingScore ? _self.selectedStartingScore : selectedStartingScore // ignore: cast_nullable_to_non_nullable
as int?,timeRange: null == timeRange ? _self.timeRange : timeRange // ignore: cast_nullable_to_non_nullable
as StatsTimeRange,showCheckoutOverlay: null == showCheckoutOverlay ? _self.showCheckoutOverlay : showCheckoutOverlay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
