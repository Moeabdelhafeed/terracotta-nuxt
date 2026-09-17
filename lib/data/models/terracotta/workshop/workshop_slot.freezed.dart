// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkshopSlot {

/// The slot identity — sent as `workshop_slot_id`, NOT `id`. This
/// is the value the price and booking-create calls take.
 int get workshopSlotId;/// Session start as an Asia/Riyadh CLOCK string (`"13:00"`).
/// Never a `DateTime` — see the class doc.
 String? get startTime;/// Session end as an Asia/Riyadh CLOCK string (`"14:30"`).
/// Never a `DateTime` — see the class doc.
 String? get endTime;/// Total seats in the session.
 int? get capacity;/// Seats already taken.
 int? get booked;/// Seats left — this is the number the picker shows the customer
/// ("٤ / ٦ مقاعد"). Do NOT recompute it from capacity - booked; a
/// held-but-unpaid booking occupies a seat and the server accounts
/// for that here.
 int? get remaining;/// The session is at capacity. Grey it out.
 bool? get isFull;/// True when the signed-in customer already has an overlapping
/// booking. Read it through [isConflicting].
 bool? get hasConflict;/// **Whether booking THIS session can ever be cancelled.**
///
/// Per slot, not per workshop: a workshop's
/// `cancellation_window_hours` is measured back from the session's
/// own start, so the same workshop is cancellable on next week's
/// session and not on tomorrow's. Probed live on 2026-09-09 — the
/// availability rows carry it alongside [cancelUntil].
///
/// The booking screens read it BEFORE the money moves, because
/// afterwards is too late to be told. `can_cancel` on the created
/// booking is the same rule looked at from the other side.
 bool? get isNonCancellable;/// The deadline, **as the server wrote it** — an ISO string with
/// the studio's offset, `2026-09-10T13:00:00+03:00`.
///
/// KEPT AS A STRING on purpose, like every other time on this API.
/// `DateTime.parse` converts an offset-bearing string to UTC, so
/// parsing this to display it turned 13:00 in Riyadh into 10:00
/// and the app told a customer their deadline was three hours
/// earlier than it is. The studio's wall clock is the one that
/// counts; read it with [cancelUntilLabel], and compare instants
/// with [cancelUntilAt].
@JsonKey(name: 'cancel_until') String? get cancelUntil;
/// Create a copy of WorkshopSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopSlotCopyWith<WorkshopSlot> get copyWith => _$WorkshopSlotCopyWithImpl<WorkshopSlot>(this as WorkshopSlot, _$identity);

  /// Serializes this WorkshopSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopSlot&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.booked, booked) || other.booked == booked)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.isFull, isFull) || other.isFull == isFull)&&(identical(other.hasConflict, hasConflict) || other.hasConflict == hasConflict)&&(identical(other.isNonCancellable, isNonCancellable) || other.isNonCancellable == isNonCancellable)&&(identical(other.cancelUntil, cancelUntil) || other.cancelUntil == cancelUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workshopSlotId,startTime,endTime,capacity,booked,remaining,isFull,hasConflict,isNonCancellable,cancelUntil);

@override
String toString() {
  return 'WorkshopSlot(workshopSlotId: $workshopSlotId, startTime: $startTime, endTime: $endTime, capacity: $capacity, booked: $booked, remaining: $remaining, isFull: $isFull, hasConflict: $hasConflict, isNonCancellable: $isNonCancellable, cancelUntil: $cancelUntil)';
}


}

/// @nodoc
abstract mixin class $WorkshopSlotCopyWith<$Res>  {
  factory $WorkshopSlotCopyWith(WorkshopSlot value, $Res Function(WorkshopSlot) _then) = _$WorkshopSlotCopyWithImpl;
@useResult
$Res call({
 int workshopSlotId, String? startTime, String? endTime, int? capacity, int? booked, int? remaining, bool? isFull, bool? hasConflict, bool? isNonCancellable,@JsonKey(name: 'cancel_until') String? cancelUntil
});




}
/// @nodoc
class _$WorkshopSlotCopyWithImpl<$Res>
    implements $WorkshopSlotCopyWith<$Res> {
  _$WorkshopSlotCopyWithImpl(this._self, this._then);

  final WorkshopSlot _self;
  final $Res Function(WorkshopSlot) _then;

/// Create a copy of WorkshopSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workshopSlotId = null,Object? startTime = freezed,Object? endTime = freezed,Object? capacity = freezed,Object? booked = freezed,Object? remaining = freezed,Object? isFull = freezed,Object? hasConflict = freezed,Object? isNonCancellable = freezed,Object? cancelUntil = freezed,}) {
  return _then(_self.copyWith(
workshopSlotId: null == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,booked: freezed == booked ? _self.booked : booked // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,isFull: freezed == isFull ? _self.isFull : isFull // ignore: cast_nullable_to_non_nullable
as bool?,hasConflict: freezed == hasConflict ? _self.hasConflict : hasConflict // ignore: cast_nullable_to_non_nullable
as bool?,isNonCancellable: freezed == isNonCancellable ? _self.isNonCancellable : isNonCancellable // ignore: cast_nullable_to_non_nullable
as bool?,cancelUntil: freezed == cancelUntil ? _self.cancelUntil : cancelUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkshopSlot].
extension WorkshopSlotPatterns on WorkshopSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopSlot value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopSlot value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int workshopSlotId,  String? startTime,  String? endTime,  int? capacity,  int? booked,  int? remaining,  bool? isFull,  bool? hasConflict,  bool? isNonCancellable, @JsonKey(name: 'cancel_until')  String? cancelUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopSlot() when $default != null:
return $default(_that.workshopSlotId,_that.startTime,_that.endTime,_that.capacity,_that.booked,_that.remaining,_that.isFull,_that.hasConflict,_that.isNonCancellable,_that.cancelUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int workshopSlotId,  String? startTime,  String? endTime,  int? capacity,  int? booked,  int? remaining,  bool? isFull,  bool? hasConflict,  bool? isNonCancellable, @JsonKey(name: 'cancel_until')  String? cancelUntil)  $default,) {final _that = this;
switch (_that) {
case _WorkshopSlot():
return $default(_that.workshopSlotId,_that.startTime,_that.endTime,_that.capacity,_that.booked,_that.remaining,_that.isFull,_that.hasConflict,_that.isNonCancellable,_that.cancelUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int workshopSlotId,  String? startTime,  String? endTime,  int? capacity,  int? booked,  int? remaining,  bool? isFull,  bool? hasConflict,  bool? isNonCancellable, @JsonKey(name: 'cancel_until')  String? cancelUntil)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopSlot() when $default != null:
return $default(_that.workshopSlotId,_that.startTime,_that.endTime,_that.capacity,_that.booked,_that.remaining,_that.isFull,_that.hasConflict,_that.isNonCancellable,_that.cancelUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkshopSlot extends WorkshopSlot {
  const _WorkshopSlot({required this.workshopSlotId, this.startTime, this.endTime, this.capacity, this.booked, this.remaining, this.isFull, this.hasConflict, this.isNonCancellable, @JsonKey(name: 'cancel_until') this.cancelUntil}): super._();
  factory _WorkshopSlot.fromJson(Map<String, dynamic> json) => _$WorkshopSlotFromJson(json);

/// The slot identity — sent as `workshop_slot_id`, NOT `id`. This
/// is the value the price and booking-create calls take.
@override final  int workshopSlotId;
/// Session start as an Asia/Riyadh CLOCK string (`"13:00"`).
/// Never a `DateTime` — see the class doc.
@override final  String? startTime;
/// Session end as an Asia/Riyadh CLOCK string (`"14:30"`).
/// Never a `DateTime` — see the class doc.
@override final  String? endTime;
/// Total seats in the session.
@override final  int? capacity;
/// Seats already taken.
@override final  int? booked;
/// Seats left — this is the number the picker shows the customer
/// ("٤ / ٦ مقاعد"). Do NOT recompute it from capacity - booked; a
/// held-but-unpaid booking occupies a seat and the server accounts
/// for that here.
@override final  int? remaining;
/// The session is at capacity. Grey it out.
@override final  bool? isFull;
/// True when the signed-in customer already has an overlapping
/// booking. Read it through [isConflicting].
@override final  bool? hasConflict;
/// **Whether booking THIS session can ever be cancelled.**
///
/// Per slot, not per workshop: a workshop's
/// `cancellation_window_hours` is measured back from the session's
/// own start, so the same workshop is cancellable on next week's
/// session and not on tomorrow's. Probed live on 2026-09-09 — the
/// availability rows carry it alongside [cancelUntil].
///
/// The booking screens read it BEFORE the money moves, because
/// afterwards is too late to be told. `can_cancel` on the created
/// booking is the same rule looked at from the other side.
@override final  bool? isNonCancellable;
/// The deadline, **as the server wrote it** — an ISO string with
/// the studio's offset, `2026-09-10T13:00:00+03:00`.
///
/// KEPT AS A STRING on purpose, like every other time on this API.
/// `DateTime.parse` converts an offset-bearing string to UTC, so
/// parsing this to display it turned 13:00 in Riyadh into 10:00
/// and the app told a customer their deadline was three hours
/// earlier than it is. The studio's wall clock is the one that
/// counts; read it with [cancelUntilLabel], and compare instants
/// with [cancelUntilAt].
@override@JsonKey(name: 'cancel_until') final  String? cancelUntil;

/// Create a copy of WorkshopSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopSlotCopyWith<_WorkshopSlot> get copyWith => __$WorkshopSlotCopyWithImpl<_WorkshopSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopSlot&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.booked, booked) || other.booked == booked)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.isFull, isFull) || other.isFull == isFull)&&(identical(other.hasConflict, hasConflict) || other.hasConflict == hasConflict)&&(identical(other.isNonCancellable, isNonCancellable) || other.isNonCancellable == isNonCancellable)&&(identical(other.cancelUntil, cancelUntil) || other.cancelUntil == cancelUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workshopSlotId,startTime,endTime,capacity,booked,remaining,isFull,hasConflict,isNonCancellable,cancelUntil);

@override
String toString() {
  return 'WorkshopSlot(workshopSlotId: $workshopSlotId, startTime: $startTime, endTime: $endTime, capacity: $capacity, booked: $booked, remaining: $remaining, isFull: $isFull, hasConflict: $hasConflict, isNonCancellable: $isNonCancellable, cancelUntil: $cancelUntil)';
}


}

/// @nodoc
abstract mixin class _$WorkshopSlotCopyWith<$Res> implements $WorkshopSlotCopyWith<$Res> {
  factory _$WorkshopSlotCopyWith(_WorkshopSlot value, $Res Function(_WorkshopSlot) _then) = __$WorkshopSlotCopyWithImpl;
@override @useResult
$Res call({
 int workshopSlotId, String? startTime, String? endTime, int? capacity, int? booked, int? remaining, bool? isFull, bool? hasConflict, bool? isNonCancellable,@JsonKey(name: 'cancel_until') String? cancelUntil
});




}
/// @nodoc
class __$WorkshopSlotCopyWithImpl<$Res>
    implements _$WorkshopSlotCopyWith<$Res> {
  __$WorkshopSlotCopyWithImpl(this._self, this._then);

  final _WorkshopSlot _self;
  final $Res Function(_WorkshopSlot) _then;

/// Create a copy of WorkshopSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workshopSlotId = null,Object? startTime = freezed,Object? endTime = freezed,Object? capacity = freezed,Object? booked = freezed,Object? remaining = freezed,Object? isFull = freezed,Object? hasConflict = freezed,Object? isNonCancellable = freezed,Object? cancelUntil = freezed,}) {
  return _then(_WorkshopSlot(
workshopSlotId: null == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,booked: freezed == booked ? _self.booked : booked // ignore: cast_nullable_to_non_nullable
as int?,remaining: freezed == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int?,isFull: freezed == isFull ? _self.isFull : isFull // ignore: cast_nullable_to_non_nullable
as bool?,hasConflict: freezed == hasConflict ? _self.hasConflict : hasConflict // ignore: cast_nullable_to_non_nullable
as bool?,isNonCancellable: freezed == isNonCancellable ? _self.isNonCancellable : isNonCancellable // ignore: cast_nullable_to_non_nullable
as bool?,cancelUntil: freezed == cancelUntil ? _self.cancelUntil : cancelUntil // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
