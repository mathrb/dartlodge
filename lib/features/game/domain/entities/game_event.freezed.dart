// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameEvent {

@JsonKey(name: 'event_id') String get eventId;@JsonKey(name: 'game_id') String get gameId;@JsonKey(name: 'event_type') String get eventType;@JsonKey(name: 'local_sequence') int get localSequence;@JsonKey(name: 'occurred_at') DateTime get occurredAt;@JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload) Map<String, dynamic> get payload;@JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt) bool get synced;@JsonKey(name: 'actor_id') String get actorId;@JsonKey(name: 'global_sequence') int? get globalSequence;@JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt) EventSource get source;
/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameEventCopyWith<GameEvent> get copyWith => _$GameEventCopyWithImpl<GameEvent>(this as GameEvent, _$identity);

  /// Serializes this GameEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.localSequence, localSequence) || other.localSequence == localSequence)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.globalSequence, globalSequence) || other.globalSequence == globalSequence)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,gameId,eventType,localSequence,occurredAt,const DeepCollectionEquality().hash(payload),synced,actorId,globalSequence,source);

@override
String toString() {
  return 'GameEvent(eventId: $eventId, gameId: $gameId, eventType: $eventType, localSequence: $localSequence, occurredAt: $occurredAt, payload: $payload, synced: $synced, actorId: $actorId, globalSequence: $globalSequence, source: $source)';
}


}

/// @nodoc
abstract mixin class $GameEventCopyWith<$Res>  {
  factory $GameEventCopyWith(GameEvent value, $Res Function(GameEvent) _then) = _$GameEventCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'event_type') String eventType,@JsonKey(name: 'local_sequence') int localSequence,@JsonKey(name: 'occurred_at') DateTime occurredAt,@JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload) Map<String, dynamic> payload,@JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt) bool synced,@JsonKey(name: 'actor_id') String actorId,@JsonKey(name: 'global_sequence') int? globalSequence,@JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt) EventSource source
});




}
/// @nodoc
class _$GameEventCopyWithImpl<$Res>
    implements $GameEventCopyWith<$Res> {
  _$GameEventCopyWithImpl(this._self, this._then);

  final GameEvent _self;
  final $Res Function(GameEvent) _then;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? gameId = null,Object? eventType = null,Object? localSequence = null,Object? occurredAt = null,Object? payload = null,Object? synced = null,Object? actorId = null,Object? globalSequence = freezed,Object? source = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,localSequence: null == localSequence ? _self.localSequence : localSequence // ignore: cast_nullable_to_non_nullable
as int,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,globalSequence: freezed == globalSequence ? _self.globalSequence : globalSequence // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EventSource,
  ));
}

}


/// Adds pattern-matching-related methods to [GameEvent].
extension GameEventPatterns on GameEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameEvent value)  $default,){
final _that = this;
switch (_that) {
case _GameEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameEvent value)?  $default,){
final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'local_sequence')  int localSequence, @JsonKey(name: 'occurred_at')  DateTime occurredAt, @JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload)  Map<String, dynamic> payload, @JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt)  bool synced, @JsonKey(name: 'actor_id')  String actorId, @JsonKey(name: 'global_sequence')  int? globalSequence, @JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt)  EventSource source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
return $default(_that.eventId,_that.gameId,_that.eventType,_that.localSequence,_that.occurredAt,_that.payload,_that.synced,_that.actorId,_that.globalSequence,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'local_sequence')  int localSequence, @JsonKey(name: 'occurred_at')  DateTime occurredAt, @JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload)  Map<String, dynamic> payload, @JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt)  bool synced, @JsonKey(name: 'actor_id')  String actorId, @JsonKey(name: 'global_sequence')  int? globalSequence, @JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt)  EventSource source)  $default,) {final _that = this;
switch (_that) {
case _GameEvent():
return $default(_that.eventId,_that.gameId,_that.eventType,_that.localSequence,_that.occurredAt,_that.payload,_that.synced,_that.actorId,_that.globalSequence,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'event_id')  String eventId, @JsonKey(name: 'game_id')  String gameId, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'local_sequence')  int localSequence, @JsonKey(name: 'occurred_at')  DateTime occurredAt, @JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload)  Map<String, dynamic> payload, @JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt)  bool synced, @JsonKey(name: 'actor_id')  String actorId, @JsonKey(name: 'global_sequence')  int? globalSequence, @JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt)  EventSource source)?  $default,) {final _that = this;
switch (_that) {
case _GameEvent() when $default != null:
return $default(_that.eventId,_that.gameId,_that.eventType,_that.localSequence,_that.occurredAt,_that.payload,_that.synced,_that.actorId,_that.globalSequence,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameEvent implements GameEvent {
  const _GameEvent({@JsonKey(name: 'event_id') required this.eventId, @JsonKey(name: 'game_id') required this.gameId, @JsonKey(name: 'event_type') required this.eventType, @JsonKey(name: 'local_sequence') required this.localSequence, @JsonKey(name: 'occurred_at') required this.occurredAt, @JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload) required final  Map<String, dynamic> payload, @JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt) required this.synced, @JsonKey(name: 'actor_id') required this.actorId, @JsonKey(name: 'global_sequence') this.globalSequence, @JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt) required this.source}): _payload = payload;
  factory _GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);

@override@JsonKey(name: 'event_id') final  String eventId;
@override@JsonKey(name: 'game_id') final  String gameId;
@override@JsonKey(name: 'event_type') final  String eventType;
@override@JsonKey(name: 'local_sequence') final  int localSequence;
@override@JsonKey(name: 'occurred_at') final  DateTime occurredAt;
 final  Map<String, dynamic> _payload;
@override@JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload) Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override@JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt) final  bool synced;
@override@JsonKey(name: 'actor_id') final  String actorId;
@override@JsonKey(name: 'global_sequence') final  int? globalSequence;
@override@JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt) final  EventSource source;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameEventCopyWith<_GameEvent> get copyWith => __$GameEventCopyWithImpl<_GameEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.localSequence, localSequence) || other.localSequence == localSequence)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.synced, synced) || other.synced == synced)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.globalSequence, globalSequence) || other.globalSequence == globalSequence)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,gameId,eventType,localSequence,occurredAt,const DeepCollectionEquality().hash(_payload),synced,actorId,globalSequence,source);

@override
String toString() {
  return 'GameEvent(eventId: $eventId, gameId: $gameId, eventType: $eventType, localSequence: $localSequence, occurredAt: $occurredAt, payload: $payload, synced: $synced, actorId: $actorId, globalSequence: $globalSequence, source: $source)';
}


}

/// @nodoc
abstract mixin class _$GameEventCopyWith<$Res> implements $GameEventCopyWith<$Res> {
  factory _$GameEventCopyWith(_GameEvent value, $Res Function(_GameEvent) _then) = __$GameEventCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'event_id') String eventId,@JsonKey(name: 'game_id') String gameId,@JsonKey(name: 'event_type') String eventType,@JsonKey(name: 'local_sequence') int localSequence,@JsonKey(name: 'occurred_at') DateTime occurredAt,@JsonKey(name: 'payload_json', fromJson: _parsePayload, toJson: _stringifyPayload) Map<String, dynamic> payload,@JsonKey(name: 'synced', fromJson: _parseBool, toJson: _boolToInt) bool synced,@JsonKey(name: 'actor_id') String actorId,@JsonKey(name: 'global_sequence') int? globalSequence,@JsonKey(name: 'source', fromJson: _parseSource, toJson: _sourceToInt) EventSource source
});




}
/// @nodoc
class __$GameEventCopyWithImpl<$Res>
    implements _$GameEventCopyWith<$Res> {
  __$GameEventCopyWithImpl(this._self, this._then);

  final _GameEvent _self;
  final $Res Function(_GameEvent) _then;

/// Create a copy of GameEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? gameId = null,Object? eventType = null,Object? localSequence = null,Object? occurredAt = null,Object? payload = null,Object? synced = null,Object? actorId = null,Object? globalSequence = freezed,Object? source = null,}) {
  return _then(_GameEvent(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,localSequence: null == localSequence ? _self.localSequence : localSequence // ignore: cast_nullable_to_non_nullable
as int,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,synced: null == synced ? _self.synced : synced // ignore: cast_nullable_to_non_nullable
as bool,actorId: null == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String,globalSequence: freezed == globalSequence ? _self.globalSequence : globalSequence // ignore: cast_nullable_to_non_nullable
as int?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as EventSource,
  ));
}


}

// dart format on
