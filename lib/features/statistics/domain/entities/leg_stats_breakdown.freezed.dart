// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leg_stats_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LegStatsBreakdown {

 int get legNumber; String? get winnerCompetitorId; String get winnerName; List<LegCompetitorStats> get byCompetitor;
/// Create a copy of LegStatsBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegStatsBreakdownCopyWith<LegStatsBreakdown> get copyWith => _$LegStatsBreakdownCopyWithImpl<LegStatsBreakdown>(this as LegStatsBreakdown, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LegStatsBreakdown;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegStatsBreakdown&&(identical(other.legNumber, _this.legNumber) || other.legNumber == _this.legNumber)&&(identical(other.winnerCompetitorId, _this.winnerCompetitorId) || other.winnerCompetitorId == _this.winnerCompetitorId)&&(identical(other.winnerName, _this.winnerName) || other.winnerName == _this.winnerName)&&const DeepCollectionEquality().equals(other.byCompetitor, _this.byCompetitor));
}


@override
int get hashCode {
  final _this = this as LegStatsBreakdown;
  return Object.hash(runtimeType,_this.legNumber,_this.winnerCompetitorId,_this.winnerName,const DeepCollectionEquality().hash(_this.byCompetitor));
}

@override
String toString() {
  final _this = this as LegStatsBreakdown;
  return 'LegStatsBreakdown(legNumber: ${_this.legNumber}, winnerCompetitorId: ${_this.winnerCompetitorId}, winnerName: ${_this.winnerName}, byCompetitor: ${_this.byCompetitor})';
}


}

/// @nodoc
abstract mixin class $LegStatsBreakdownCopyWith<$Res>  {
  factory $LegStatsBreakdownCopyWith(LegStatsBreakdown value, $Res Function(LegStatsBreakdown) _then) = _$LegStatsBreakdownCopyWithImpl;
@useResult
$Res call({
 int legNumber, String? winnerCompetitorId, String winnerName, List<LegCompetitorStats> byCompetitor
});




}
/// @nodoc
class _$LegStatsBreakdownCopyWithImpl<$Res>
    implements $LegStatsBreakdownCopyWith<$Res> {
  _$LegStatsBreakdownCopyWithImpl(this._self, this._then);

  final LegStatsBreakdown _self;
  final $Res Function(LegStatsBreakdown) _then;

/// Create a copy of LegStatsBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? legNumber = null,Object? winnerCompetitorId = freezed,Object? winnerName = null,Object? byCompetitor = null,}) {
  return _then(LegStatsBreakdown(
legNumber: null == legNumber ? _self.legNumber : legNumber // ignore: cast_nullable_to_non_nullable
as int,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,winnerName: null == winnerName ? _self.winnerName : winnerName // ignore: cast_nullable_to_non_nullable
as String,byCompetitor: null == byCompetitor ? _self.byCompetitor : byCompetitor // ignore: cast_nullable_to_non_nullable
as List<LegCompetitorStats>,
  ));
}

}


/// Adds pattern-matching-related methods to [LegStatsBreakdown].
extension LegStatsBreakdownPatterns on LegStatsBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegStatsBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegStatsBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegStatsBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _LegStatsBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegStatsBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _LegStatsBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int legNumber,  String? winnerCompetitorId,  String winnerName,  List<LegCompetitorStats> byCompetitor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegStatsBreakdown() when $default != null:
return $default(_that.legNumber,_that.winnerCompetitorId,_that.winnerName,_that.byCompetitor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int legNumber,  String? winnerCompetitorId,  String winnerName,  List<LegCompetitorStats> byCompetitor)  $default,) {final _that = this;
switch (_that) {
case _LegStatsBreakdown():
return $default(_that.legNumber,_that.winnerCompetitorId,_that.winnerName,_that.byCompetitor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int legNumber,  String? winnerCompetitorId,  String winnerName,  List<LegCompetitorStats> byCompetitor)?  $default,) {final _that = this;
switch (_that) {
case _LegStatsBreakdown() when $default != null:
return $default(_that.legNumber,_that.winnerCompetitorId,_that.winnerName,_that.byCompetitor);case _:
  return null;

}
}

}

/// @nodoc


class _LegStatsBreakdown implements LegStatsBreakdown {
  const _LegStatsBreakdown({required this.legNumber, required this.winnerCompetitorId, required this.winnerName, required  List<LegCompetitorStats> byCompetitor}): _byCompetitor = byCompetitor;
  

@override final  int legNumber;
@override final  String? winnerCompetitorId;
@override final  String winnerName;
 final  List<LegCompetitorStats> _byCompetitor;
@override List<LegCompetitorStats> get byCompetitor {
  if (_byCompetitor is EqualUnmodifiableListView) return _byCompetitor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCompetitor);
}


/// Create a copy of LegStatsBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegStatsBreakdownCopyWith<_LegStatsBreakdown> get copyWith => __$LegStatsBreakdownCopyWithImpl<_LegStatsBreakdown>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegStatsBreakdown&&(identical(other.legNumber, legNumber) || other.legNumber == legNumber)&&(identical(other.winnerCompetitorId, winnerCompetitorId) || other.winnerCompetitorId == winnerCompetitorId)&&(identical(other.winnerName, winnerName) || other.winnerName == winnerName)&&const DeepCollectionEquality().equals(other.byCompetitor, _byCompetitor));
}


@override
int get hashCode {
    return Object.hash(runtimeType,legNumber,winnerCompetitorId,winnerName,const DeepCollectionEquality().hash(_byCompetitor));
}

@override
String toString() {
    return 'LegStatsBreakdown(legNumber: $legNumber, winnerCompetitorId: $winnerCompetitorId, winnerName: $winnerName, byCompetitor: $byCompetitor)';
}


}

/// @nodoc
abstract mixin class _$LegStatsBreakdownCopyWith<$Res> implements $LegStatsBreakdownCopyWith<$Res> {
  factory _$LegStatsBreakdownCopyWith(_LegStatsBreakdown value, $Res Function(_LegStatsBreakdown) _then) = __$LegStatsBreakdownCopyWithImpl;
@override @useResult
$Res call({
 int legNumber, String? winnerCompetitorId, String winnerName, List<LegCompetitorStats> byCompetitor
});




}
/// @nodoc
class __$LegStatsBreakdownCopyWithImpl<$Res>
    implements _$LegStatsBreakdownCopyWith<$Res> {
  __$LegStatsBreakdownCopyWithImpl(this._self, this._then);

  final _LegStatsBreakdown _self;
  final $Res Function(_LegStatsBreakdown) _then;

/// Create a copy of LegStatsBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? legNumber = null,Object? winnerCompetitorId = freezed,Object? winnerName = null,Object? byCompetitor = null,}) {
  return _then(_LegStatsBreakdown(
legNumber: null == legNumber ? _self.legNumber : legNumber // ignore: cast_nullable_to_non_nullable
as int,winnerCompetitorId: freezed == winnerCompetitorId ? _self.winnerCompetitorId : winnerCompetitorId // ignore: cast_nullable_to_non_nullable
as String?,winnerName: null == winnerName ? _self.winnerName : winnerName // ignore: cast_nullable_to_non_nullable
as String,byCompetitor: null == byCompetitor ? _self._byCompetitor : byCompetitor // ignore: cast_nullable_to_non_nullable
as List<LegCompetitorStats>,
  ));
}


}

/// @nodoc
mixin _$LegCompetitorStats {

 String get competitorId; String get competitorName; int get dartsThrown; double? get threeDartAverage; double? get checkoutPercentage; int? get highestCheckout; int get oneEightyTurns; int get sixtyPlusTurns; int get oneHundredPlusTurns; int get oneFortyPlusTurns; double? get marksPerRound; double? get firstNineMarksPerRound; int get fiveMarkTurns; int get sixMarkTurns; int get sevenMarkTurns; int get eightMarkTurns; int get nineMarkTurns;
/// Create a copy of LegCompetitorStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegCompetitorStatsCopyWith<LegCompetitorStats> get copyWith => _$LegCompetitorStatsCopyWithImpl<LegCompetitorStats>(this as LegCompetitorStats, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LegCompetitorStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegCompetitorStats&&(identical(other.competitorId, _this.competitorId) || other.competitorId == _this.competitorId)&&(identical(other.competitorName, _this.competitorName) || other.competitorName == _this.competitorName)&&(identical(other.dartsThrown, _this.dartsThrown) || other.dartsThrown == _this.dartsThrown)&&(identical(other.threeDartAverage, _this.threeDartAverage) || other.threeDartAverage == _this.threeDartAverage)&&(identical(other.checkoutPercentage, _this.checkoutPercentage) || other.checkoutPercentage == _this.checkoutPercentage)&&(identical(other.highestCheckout, _this.highestCheckout) || other.highestCheckout == _this.highestCheckout)&&(identical(other.oneEightyTurns, _this.oneEightyTurns) || other.oneEightyTurns == _this.oneEightyTurns)&&(identical(other.sixtyPlusTurns, _this.sixtyPlusTurns) || other.sixtyPlusTurns == _this.sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, _this.oneHundredPlusTurns) || other.oneHundredPlusTurns == _this.oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, _this.oneFortyPlusTurns) || other.oneFortyPlusTurns == _this.oneFortyPlusTurns)&&(identical(other.marksPerRound, _this.marksPerRound) || other.marksPerRound == _this.marksPerRound)&&(identical(other.firstNineMarksPerRound, _this.firstNineMarksPerRound) || other.firstNineMarksPerRound == _this.firstNineMarksPerRound)&&(identical(other.fiveMarkTurns, _this.fiveMarkTurns) || other.fiveMarkTurns == _this.fiveMarkTurns)&&(identical(other.sixMarkTurns, _this.sixMarkTurns) || other.sixMarkTurns == _this.sixMarkTurns)&&(identical(other.sevenMarkTurns, _this.sevenMarkTurns) || other.sevenMarkTurns == _this.sevenMarkTurns)&&(identical(other.eightMarkTurns, _this.eightMarkTurns) || other.eightMarkTurns == _this.eightMarkTurns)&&(identical(other.nineMarkTurns, _this.nineMarkTurns) || other.nineMarkTurns == _this.nineMarkTurns));
}


@override
int get hashCode {
  final _this = this as LegCompetitorStats;
  return Object.hash(runtimeType,_this.competitorId,_this.competitorName,_this.dartsThrown,_this.threeDartAverage,_this.checkoutPercentage,_this.highestCheckout,_this.oneEightyTurns,_this.sixtyPlusTurns,_this.oneHundredPlusTurns,_this.oneFortyPlusTurns,_this.marksPerRound,_this.firstNineMarksPerRound,_this.fiveMarkTurns,_this.sixMarkTurns,_this.sevenMarkTurns,_this.eightMarkTurns,_this.nineMarkTurns);
}

@override
String toString() {
  final _this = this as LegCompetitorStats;
  return 'LegCompetitorStats(competitorId: ${_this.competitorId}, competitorName: ${_this.competitorName}, dartsThrown: ${_this.dartsThrown}, threeDartAverage: ${_this.threeDartAverage}, checkoutPercentage: ${_this.checkoutPercentage}, highestCheckout: ${_this.highestCheckout}, oneEightyTurns: ${_this.oneEightyTurns}, sixtyPlusTurns: ${_this.sixtyPlusTurns}, oneHundredPlusTurns: ${_this.oneHundredPlusTurns}, oneFortyPlusTurns: ${_this.oneFortyPlusTurns}, marksPerRound: ${_this.marksPerRound}, firstNineMarksPerRound: ${_this.firstNineMarksPerRound}, fiveMarkTurns: ${_this.fiveMarkTurns}, sixMarkTurns: ${_this.sixMarkTurns}, sevenMarkTurns: ${_this.sevenMarkTurns}, eightMarkTurns: ${_this.eightMarkTurns}, nineMarkTurns: ${_this.nineMarkTurns})';
}


}

/// @nodoc
abstract mixin class $LegCompetitorStatsCopyWith<$Res>  {
  factory $LegCompetitorStatsCopyWith(LegCompetitorStats value, $Res Function(LegCompetitorStats) _then) = _$LegCompetitorStatsCopyWithImpl;
@useResult
$Res call({
 String competitorId, String competitorName, int dartsThrown, double? threeDartAverage, double? checkoutPercentage, int? highestCheckout, int oneEightyTurns, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns, double? marksPerRound, double? firstNineMarksPerRound, int fiveMarkTurns, int sixMarkTurns, int sevenMarkTurns, int eightMarkTurns, int nineMarkTurns
});




}
/// @nodoc
class _$LegCompetitorStatsCopyWithImpl<$Res>
    implements $LegCompetitorStatsCopyWith<$Res> {
  _$LegCompetitorStatsCopyWithImpl(this._self, this._then);

  final LegCompetitorStats _self;
  final $Res Function(LegCompetitorStats) _then;

/// Create a copy of LegCompetitorStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competitorId = null,Object? competitorName = null,Object? dartsThrown = null,Object? threeDartAverage = freezed,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? oneEightyTurns = null,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,Object? marksPerRound = freezed,Object? firstNineMarksPerRound = freezed,Object? fiveMarkTurns = null,Object? sixMarkTurns = null,Object? sevenMarkTurns = null,Object? eightMarkTurns = null,Object? nineMarkTurns = null,}) {
  return _then(LegCompetitorStats(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,dartsThrown: null == dartsThrown ? _self.dartsThrown : dartsThrown // ignore: cast_nullable_to_non_nullable
as int,threeDartAverage: freezed == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double?,checkoutPercentage: freezed == checkoutPercentage ? _self.checkoutPercentage : checkoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,highestCheckout: freezed == highestCheckout ? _self.highestCheckout : highestCheckout // ignore: cast_nullable_to_non_nullable
as int?,oneEightyTurns: null == oneEightyTurns ? _self.oneEightyTurns : oneEightyTurns // ignore: cast_nullable_to_non_nullable
as int,sixtyPlusTurns: null == sixtyPlusTurns ? _self.sixtyPlusTurns : sixtyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneHundredPlusTurns: null == oneHundredPlusTurns ? _self.oneHundredPlusTurns : oneHundredPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneFortyPlusTurns: null == oneFortyPlusTurns ? _self.oneFortyPlusTurns : oneFortyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,marksPerRound: freezed == marksPerRound ? _self.marksPerRound : marksPerRound // ignore: cast_nullable_to_non_nullable
as double?,firstNineMarksPerRound: freezed == firstNineMarksPerRound ? _self.firstNineMarksPerRound : firstNineMarksPerRound // ignore: cast_nullable_to_non_nullable
as double?,fiveMarkTurns: null == fiveMarkTurns ? _self.fiveMarkTurns : fiveMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sixMarkTurns: null == sixMarkTurns ? _self.sixMarkTurns : sixMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sevenMarkTurns: null == sevenMarkTurns ? _self.sevenMarkTurns : sevenMarkTurns // ignore: cast_nullable_to_non_nullable
as int,eightMarkTurns: null == eightMarkTurns ? _self.eightMarkTurns : eightMarkTurns // ignore: cast_nullable_to_non_nullable
as int,nineMarkTurns: null == nineMarkTurns ? _self.nineMarkTurns : nineMarkTurns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LegCompetitorStats].
extension LegCompetitorStatsPatterns on LegCompetitorStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegCompetitorStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegCompetitorStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegCompetitorStats value)  $default,){
final _that = this;
switch (_that) {
case _LegCompetitorStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegCompetitorStats value)?  $default,){
final _that = this;
switch (_that) {
case _LegCompetitorStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  int dartsThrown,  double? threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int oneEightyTurns,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  double? marksPerRound,  double? firstNineMarksPerRound,  int fiveMarkTurns,  int sixMarkTurns,  int sevenMarkTurns,  int eightMarkTurns,  int nineMarkTurns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegCompetitorStats() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.dartsThrown,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.oneEightyTurns,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.marksPerRound,_that.firstNineMarksPerRound,_that.fiveMarkTurns,_that.sixMarkTurns,_that.sevenMarkTurns,_that.eightMarkTurns,_that.nineMarkTurns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String competitorId,  String competitorName,  int dartsThrown,  double? threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int oneEightyTurns,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  double? marksPerRound,  double? firstNineMarksPerRound,  int fiveMarkTurns,  int sixMarkTurns,  int sevenMarkTurns,  int eightMarkTurns,  int nineMarkTurns)  $default,) {final _that = this;
switch (_that) {
case _LegCompetitorStats():
return $default(_that.competitorId,_that.competitorName,_that.dartsThrown,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.oneEightyTurns,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.marksPerRound,_that.firstNineMarksPerRound,_that.fiveMarkTurns,_that.sixMarkTurns,_that.sevenMarkTurns,_that.eightMarkTurns,_that.nineMarkTurns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String competitorId,  String competitorName,  int dartsThrown,  double? threeDartAverage,  double? checkoutPercentage,  int? highestCheckout,  int oneEightyTurns,  int sixtyPlusTurns,  int oneHundredPlusTurns,  int oneFortyPlusTurns,  double? marksPerRound,  double? firstNineMarksPerRound,  int fiveMarkTurns,  int sixMarkTurns,  int sevenMarkTurns,  int eightMarkTurns,  int nineMarkTurns)?  $default,) {final _that = this;
switch (_that) {
case _LegCompetitorStats() when $default != null:
return $default(_that.competitorId,_that.competitorName,_that.dartsThrown,_that.threeDartAverage,_that.checkoutPercentage,_that.highestCheckout,_that.oneEightyTurns,_that.sixtyPlusTurns,_that.oneHundredPlusTurns,_that.oneFortyPlusTurns,_that.marksPerRound,_that.firstNineMarksPerRound,_that.fiveMarkTurns,_that.sixMarkTurns,_that.sevenMarkTurns,_that.eightMarkTurns,_that.nineMarkTurns);case _:
  return null;

}
}

}

/// @nodoc


class _LegCompetitorStats implements LegCompetitorStats {
  const _LegCompetitorStats({required this.competitorId, required this.competitorName, required this.dartsThrown, this.threeDartAverage, this.checkoutPercentage, this.highestCheckout, this.oneEightyTurns = 0, this.sixtyPlusTurns = 0, this.oneHundredPlusTurns = 0, this.oneFortyPlusTurns = 0, this.marksPerRound, this.firstNineMarksPerRound, this.fiveMarkTurns = 0, this.sixMarkTurns = 0, this.sevenMarkTurns = 0, this.eightMarkTurns = 0, this.nineMarkTurns = 0});
  

@override final  String competitorId;
@override final  String competitorName;
@override final  int dartsThrown;
@override final  double? threeDartAverage;
@override final  double? checkoutPercentage;
@override final  int? highestCheckout;
@override@JsonKey() final  int oneEightyTurns;
@override@JsonKey() final  int sixtyPlusTurns;
@override@JsonKey() final  int oneHundredPlusTurns;
@override@JsonKey() final  int oneFortyPlusTurns;
@override final  double? marksPerRound;
@override final  double? firstNineMarksPerRound;
@override@JsonKey() final  int fiveMarkTurns;
@override@JsonKey() final  int sixMarkTurns;
@override@JsonKey() final  int sevenMarkTurns;
@override@JsonKey() final  int eightMarkTurns;
@override@JsonKey() final  int nineMarkTurns;

/// Create a copy of LegCompetitorStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegCompetitorStatsCopyWith<_LegCompetitorStats> get copyWith => __$LegCompetitorStatsCopyWithImpl<_LegCompetitorStats>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegCompetitorStats&&(identical(other.competitorId, competitorId) || other.competitorId == competitorId)&&(identical(other.competitorName, competitorName) || other.competitorName == competitorName)&&(identical(other.dartsThrown, dartsThrown) || other.dartsThrown == dartsThrown)&&(identical(other.threeDartAverage, threeDartAverage) || other.threeDartAverage == threeDartAverage)&&(identical(other.checkoutPercentage, checkoutPercentage) || other.checkoutPercentage == checkoutPercentage)&&(identical(other.highestCheckout, highestCheckout) || other.highestCheckout == highestCheckout)&&(identical(other.oneEightyTurns, oneEightyTurns) || other.oneEightyTurns == oneEightyTurns)&&(identical(other.sixtyPlusTurns, sixtyPlusTurns) || other.sixtyPlusTurns == sixtyPlusTurns)&&(identical(other.oneHundredPlusTurns, oneHundredPlusTurns) || other.oneHundredPlusTurns == oneHundredPlusTurns)&&(identical(other.oneFortyPlusTurns, oneFortyPlusTurns) || other.oneFortyPlusTurns == oneFortyPlusTurns)&&(identical(other.marksPerRound, marksPerRound) || other.marksPerRound == marksPerRound)&&(identical(other.firstNineMarksPerRound, firstNineMarksPerRound) || other.firstNineMarksPerRound == firstNineMarksPerRound)&&(identical(other.fiveMarkTurns, fiveMarkTurns) || other.fiveMarkTurns == fiveMarkTurns)&&(identical(other.sixMarkTurns, sixMarkTurns) || other.sixMarkTurns == sixMarkTurns)&&(identical(other.sevenMarkTurns, sevenMarkTurns) || other.sevenMarkTurns == sevenMarkTurns)&&(identical(other.eightMarkTurns, eightMarkTurns) || other.eightMarkTurns == eightMarkTurns)&&(identical(other.nineMarkTurns, nineMarkTurns) || other.nineMarkTurns == nineMarkTurns));
}


@override
int get hashCode {
    return Object.hash(runtimeType,competitorId,competitorName,dartsThrown,threeDartAverage,checkoutPercentage,highestCheckout,oneEightyTurns,sixtyPlusTurns,oneHundredPlusTurns,oneFortyPlusTurns,marksPerRound,firstNineMarksPerRound,fiveMarkTurns,sixMarkTurns,sevenMarkTurns,eightMarkTurns,nineMarkTurns);
}

@override
String toString() {
    return 'LegCompetitorStats(competitorId: $competitorId, competitorName: $competitorName, dartsThrown: $dartsThrown, threeDartAverage: $threeDartAverage, checkoutPercentage: $checkoutPercentage, highestCheckout: $highestCheckout, oneEightyTurns: $oneEightyTurns, sixtyPlusTurns: $sixtyPlusTurns, oneHundredPlusTurns: $oneHundredPlusTurns, oneFortyPlusTurns: $oneFortyPlusTurns, marksPerRound: $marksPerRound, firstNineMarksPerRound: $firstNineMarksPerRound, fiveMarkTurns: $fiveMarkTurns, sixMarkTurns: $sixMarkTurns, sevenMarkTurns: $sevenMarkTurns, eightMarkTurns: $eightMarkTurns, nineMarkTurns: $nineMarkTurns)';
}


}

/// @nodoc
abstract mixin class _$LegCompetitorStatsCopyWith<$Res> implements $LegCompetitorStatsCopyWith<$Res> {
  factory _$LegCompetitorStatsCopyWith(_LegCompetitorStats value, $Res Function(_LegCompetitorStats) _then) = __$LegCompetitorStatsCopyWithImpl;
@override @useResult
$Res call({
 String competitorId, String competitorName, int dartsThrown, double? threeDartAverage, double? checkoutPercentage, int? highestCheckout, int oneEightyTurns, int sixtyPlusTurns, int oneHundredPlusTurns, int oneFortyPlusTurns, double? marksPerRound, double? firstNineMarksPerRound, int fiveMarkTurns, int sixMarkTurns, int sevenMarkTurns, int eightMarkTurns, int nineMarkTurns
});




}
/// @nodoc
class __$LegCompetitorStatsCopyWithImpl<$Res>
    implements _$LegCompetitorStatsCopyWith<$Res> {
  __$LegCompetitorStatsCopyWithImpl(this._self, this._then);

  final _LegCompetitorStats _self;
  final $Res Function(_LegCompetitorStats) _then;

/// Create a copy of LegCompetitorStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competitorId = null,Object? competitorName = null,Object? dartsThrown = null,Object? threeDartAverage = freezed,Object? checkoutPercentage = freezed,Object? highestCheckout = freezed,Object? oneEightyTurns = null,Object? sixtyPlusTurns = null,Object? oneHundredPlusTurns = null,Object? oneFortyPlusTurns = null,Object? marksPerRound = freezed,Object? firstNineMarksPerRound = freezed,Object? fiveMarkTurns = null,Object? sixMarkTurns = null,Object? sevenMarkTurns = null,Object? eightMarkTurns = null,Object? nineMarkTurns = null,}) {
  return _then(_LegCompetitorStats(
competitorId: null == competitorId ? _self.competitorId : competitorId // ignore: cast_nullable_to_non_nullable
as String,competitorName: null == competitorName ? _self.competitorName : competitorName // ignore: cast_nullable_to_non_nullable
as String,dartsThrown: null == dartsThrown ? _self.dartsThrown : dartsThrown // ignore: cast_nullable_to_non_nullable
as int,threeDartAverage: freezed == threeDartAverage ? _self.threeDartAverage : threeDartAverage // ignore: cast_nullable_to_non_nullable
as double?,checkoutPercentage: freezed == checkoutPercentage ? _self.checkoutPercentage : checkoutPercentage // ignore: cast_nullable_to_non_nullable
as double?,highestCheckout: freezed == highestCheckout ? _self.highestCheckout : highestCheckout // ignore: cast_nullable_to_non_nullable
as int?,oneEightyTurns: null == oneEightyTurns ? _self.oneEightyTurns : oneEightyTurns // ignore: cast_nullable_to_non_nullable
as int,sixtyPlusTurns: null == sixtyPlusTurns ? _self.sixtyPlusTurns : sixtyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneHundredPlusTurns: null == oneHundredPlusTurns ? _self.oneHundredPlusTurns : oneHundredPlusTurns // ignore: cast_nullable_to_non_nullable
as int,oneFortyPlusTurns: null == oneFortyPlusTurns ? _self.oneFortyPlusTurns : oneFortyPlusTurns // ignore: cast_nullable_to_non_nullable
as int,marksPerRound: freezed == marksPerRound ? _self.marksPerRound : marksPerRound // ignore: cast_nullable_to_non_nullable
as double?,firstNineMarksPerRound: freezed == firstNineMarksPerRound ? _self.firstNineMarksPerRound : firstNineMarksPerRound // ignore: cast_nullable_to_non_nullable
as double?,fiveMarkTurns: null == fiveMarkTurns ? _self.fiveMarkTurns : fiveMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sixMarkTurns: null == sixMarkTurns ? _self.sixMarkTurns : sixMarkTurns // ignore: cast_nullable_to_non_nullable
as int,sevenMarkTurns: null == sevenMarkTurns ? _self.sevenMarkTurns : sevenMarkTurns // ignore: cast_nullable_to_non_nullable
as int,eightMarkTurns: null == eightMarkTurns ? _self.eightMarkTurns : eightMarkTurns // ignore: cast_nullable_to_non_nullable
as int,nineMarkTurns: null == nineMarkTurns ? _self.nineMarkTurns : nineMarkTurns // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
