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

 StatsTabIndex get activeTab; int? get selectedStartingScore; String? get selectedCricketVariant;// Cricket target-mode cohort filter. Defaults to `'fixed'` so existing
// career stats continue to render the canonical 15..20+Bull board.
// Random/Crazy cohorts are kept separate at the loader level (see
// `StatisticsRepository.getPlayerStats(cricketTargetMode: ...)`); the
// Cricket tab now exposes a segmented selector so the user can switch
// between cohorts (#260).
 String get selectedCricketTargetMode; GameType get selectedPracticeGameType; StatsTimeRange get timeRange;
/// Create a copy of PlayerStatsPageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerStatsPageStateCopyWith<PlayerStatsPageState> get copyWith => _$PlayerStatsPageStateCopyWithImpl<PlayerStatsPageState>(this as PlayerStatsPageState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerStatsPageState&&(identical(other.activeTab, activeTab) || other.activeTab == activeTab)&&(identical(other.selectedStartingScore, selectedStartingScore) || other.selectedStartingScore == selectedStartingScore)&&(identical(other.selectedCricketVariant, selectedCricketVariant) || other.selectedCricketVariant == selectedCricketVariant)&&(identical(other.selectedCricketTargetMode, selectedCricketTargetMode) || other.selectedCricketTargetMode == selectedCricketTargetMode)&&(identical(other.selectedPracticeGameType, selectedPracticeGameType) || other.selectedPracticeGameType == selectedPracticeGameType)&&(identical(other.timeRange, timeRange) || other.timeRange == timeRange));
}


@override
int get hashCode => Object.hash(runtimeType,activeTab,selectedStartingScore,selectedCricketVariant,selectedCricketTargetMode,selectedPracticeGameType,timeRange);

@override
String toString() {
  return 'PlayerStatsPageState(activeTab: $activeTab, selectedStartingScore: $selectedStartingScore, selectedCricketVariant: $selectedCricketVariant, selectedCricketTargetMode: $selectedCricketTargetMode, selectedPracticeGameType: $selectedPracticeGameType, timeRange: $timeRange)';
}


}

/// @nodoc
abstract mixin class $PlayerStatsPageStateCopyWith<$Res>  {
  factory $PlayerStatsPageStateCopyWith(PlayerStatsPageState value, $Res Function(PlayerStatsPageState) _then) = _$PlayerStatsPageStateCopyWithImpl;
@useResult
$Res call({
 StatsTabIndex activeTab, int? selectedStartingScore, String? selectedCricketVariant, String selectedCricketTargetMode, GameType selectedPracticeGameType, StatsTimeRange timeRange
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
@pragma('vm:prefer-inline') @override $Res call({Object? activeTab = null,Object? selectedStartingScore = freezed,Object? selectedCricketVariant = freezed,Object? selectedCricketTargetMode = null,Object? selectedPracticeGameType = null,Object? timeRange = null,}) {
  return _then(_self.copyWith(
activeTab: null == activeTab ? _self.activeTab : activeTab // ignore: cast_nullable_to_non_nullable
as StatsTabIndex,selectedStartingScore: freezed == selectedStartingScore ? _self.selectedStartingScore : selectedStartingScore // ignore: cast_nullable_to_non_nullable
as int?,selectedCricketVariant: freezed == selectedCricketVariant ? _self.selectedCricketVariant : selectedCricketVariant // ignore: cast_nullable_to_non_nullable
as String?,selectedCricketTargetMode: null == selectedCricketTargetMode ? _self.selectedCricketTargetMode : selectedCricketTargetMode // ignore: cast_nullable_to_non_nullable
as String,selectedPracticeGameType: null == selectedPracticeGameType ? _self.selectedPracticeGameType : selectedPracticeGameType // ignore: cast_nullable_to_non_nullable
as GameType,timeRange: null == timeRange ? _self.timeRange : timeRange // ignore: cast_nullable_to_non_nullable
as StatsTimeRange,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StatsTabIndex activeTab,  int? selectedStartingScore,  String? selectedCricketVariant,  String selectedCricketTargetMode,  GameType selectedPracticeGameType,  StatsTimeRange timeRange)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerStatsPageState() when $default != null:
return $default(_that.activeTab,_that.selectedStartingScore,_that.selectedCricketVariant,_that.selectedCricketTargetMode,_that.selectedPracticeGameType,_that.timeRange);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StatsTabIndex activeTab,  int? selectedStartingScore,  String? selectedCricketVariant,  String selectedCricketTargetMode,  GameType selectedPracticeGameType,  StatsTimeRange timeRange)  $default,) {final _that = this;
switch (_that) {
case _PlayerStatsPageState():
return $default(_that.activeTab,_that.selectedStartingScore,_that.selectedCricketVariant,_that.selectedCricketTargetMode,_that.selectedPracticeGameType,_that.timeRange);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StatsTabIndex activeTab,  int? selectedStartingScore,  String? selectedCricketVariant,  String selectedCricketTargetMode,  GameType selectedPracticeGameType,  StatsTimeRange timeRange)?  $default,) {final _that = this;
switch (_that) {
case _PlayerStatsPageState() when $default != null:
return $default(_that.activeTab,_that.selectedStartingScore,_that.selectedCricketVariant,_that.selectedCricketTargetMode,_that.selectedPracticeGameType,_that.timeRange);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerStatsPageState implements PlayerStatsPageState {
  const _PlayerStatsPageState({this.activeTab = StatsTabIndex.x01, this.selectedStartingScore = null, this.selectedCricketVariant = null, this.selectedCricketTargetMode = 'fixed', this.selectedPracticeGameType = GameType.aroundTheClock, this.timeRange = StatsTimeRange.all});
  

@override@JsonKey() final  StatsTabIndex activeTab;
@override@JsonKey() final  int? selectedStartingScore;
@override@JsonKey() final  String? selectedCricketVariant;
// Cricket target-mode cohort filter. Defaults to `'fixed'` so existing
// career stats continue to render the canonical 15..20+Bull board.
// Random/Crazy cohorts are kept separate at the loader level (see
// `StatisticsRepository.getPlayerStats(cricketTargetMode: ...)`); the
// Cricket tab now exposes a segmented selector so the user can switch
// between cohorts (#260).
@override@JsonKey() final  String selectedCricketTargetMode;
@override@JsonKey() final  GameType selectedPracticeGameType;
@override@JsonKey() final  StatsTimeRange timeRange;

/// Create a copy of PlayerStatsPageState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerStatsPageStateCopyWith<_PlayerStatsPageState> get copyWith => __$PlayerStatsPageStateCopyWithImpl<_PlayerStatsPageState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerStatsPageState&&(identical(other.activeTab, activeTab) || other.activeTab == activeTab)&&(identical(other.selectedStartingScore, selectedStartingScore) || other.selectedStartingScore == selectedStartingScore)&&(identical(other.selectedCricketVariant, selectedCricketVariant) || other.selectedCricketVariant == selectedCricketVariant)&&(identical(other.selectedCricketTargetMode, selectedCricketTargetMode) || other.selectedCricketTargetMode == selectedCricketTargetMode)&&(identical(other.selectedPracticeGameType, selectedPracticeGameType) || other.selectedPracticeGameType == selectedPracticeGameType)&&(identical(other.timeRange, timeRange) || other.timeRange == timeRange));
}


@override
int get hashCode => Object.hash(runtimeType,activeTab,selectedStartingScore,selectedCricketVariant,selectedCricketTargetMode,selectedPracticeGameType,timeRange);

@override
String toString() {
  return 'PlayerStatsPageState(activeTab: $activeTab, selectedStartingScore: $selectedStartingScore, selectedCricketVariant: $selectedCricketVariant, selectedCricketTargetMode: $selectedCricketTargetMode, selectedPracticeGameType: $selectedPracticeGameType, timeRange: $timeRange)';
}


}

/// @nodoc
abstract mixin class _$PlayerStatsPageStateCopyWith<$Res> implements $PlayerStatsPageStateCopyWith<$Res> {
  factory _$PlayerStatsPageStateCopyWith(_PlayerStatsPageState value, $Res Function(_PlayerStatsPageState) _then) = __$PlayerStatsPageStateCopyWithImpl;
@override @useResult
$Res call({
 StatsTabIndex activeTab, int? selectedStartingScore, String? selectedCricketVariant, String selectedCricketTargetMode, GameType selectedPracticeGameType, StatsTimeRange timeRange
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
@override @pragma('vm:prefer-inline') $Res call({Object? activeTab = null,Object? selectedStartingScore = freezed,Object? selectedCricketVariant = freezed,Object? selectedCricketTargetMode = null,Object? selectedPracticeGameType = null,Object? timeRange = null,}) {
  return _then(_PlayerStatsPageState(
activeTab: null == activeTab ? _self.activeTab : activeTab // ignore: cast_nullable_to_non_nullable
as StatsTabIndex,selectedStartingScore: freezed == selectedStartingScore ? _self.selectedStartingScore : selectedStartingScore // ignore: cast_nullable_to_non_nullable
as int?,selectedCricketVariant: freezed == selectedCricketVariant ? _self.selectedCricketVariant : selectedCricketVariant // ignore: cast_nullable_to_non_nullable
as String?,selectedCricketTargetMode: null == selectedCricketTargetMode ? _self.selectedCricketTargetMode : selectedCricketTargetMode // ignore: cast_nullable_to_non_nullable
as String,selectedPracticeGameType: null == selectedPracticeGameType ? _self.selectedPracticeGameType : selectedPracticeGameType // ignore: cast_nullable_to_non_nullable
as GameType,timeRange: null == timeRange ? _self.timeRange : timeRange // ignore: cast_nullable_to_non_nullable
as StatsTimeRange,
  ));
}


}

// dart format on
