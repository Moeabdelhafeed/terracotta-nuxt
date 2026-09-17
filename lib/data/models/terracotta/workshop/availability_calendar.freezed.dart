// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'availability_calendar.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvailabilityCalendar {

/// The largest bookable seat count anywhere in the queried range.
/// Use as the stepper's max, not as a per-day remaining count.
 int get maxAvailableSeats;/// Bare `yyyy-MM-dd` dates that CANNOT be booked. Everything not
/// listed is open. Defaults to empty so a missing or null key reads
/// as "nothing blocked" rather than throwing.
 List<String> get blockedDates;
/// Create a copy of AvailabilityCalendar
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilityCalendarCopyWith<AvailabilityCalendar> get copyWith => _$AvailabilityCalendarCopyWithImpl<AvailabilityCalendar>(this as AvailabilityCalendar, _$identity);

  /// Serializes this AvailabilityCalendar to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityCalendar&&(identical(other.maxAvailableSeats, maxAvailableSeats) || other.maxAvailableSeats == maxAvailableSeats)&&const DeepCollectionEquality().equals(other.blockedDates, blockedDates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxAvailableSeats,const DeepCollectionEquality().hash(blockedDates));

@override
String toString() {
  return 'AvailabilityCalendar(maxAvailableSeats: $maxAvailableSeats, blockedDates: $blockedDates)';
}


}

/// @nodoc
abstract mixin class $AvailabilityCalendarCopyWith<$Res>  {
  factory $AvailabilityCalendarCopyWith(AvailabilityCalendar value, $Res Function(AvailabilityCalendar) _then) = _$AvailabilityCalendarCopyWithImpl;
@useResult
$Res call({
 int maxAvailableSeats, List<String> blockedDates
});




}
/// @nodoc
class _$AvailabilityCalendarCopyWithImpl<$Res>
    implements $AvailabilityCalendarCopyWith<$Res> {
  _$AvailabilityCalendarCopyWithImpl(this._self, this._then);

  final AvailabilityCalendar _self;
  final $Res Function(AvailabilityCalendar) _then;

/// Create a copy of AvailabilityCalendar
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxAvailableSeats = null,Object? blockedDates = null,}) {
  return _then(_self.copyWith(
maxAvailableSeats: null == maxAvailableSeats ? _self.maxAvailableSeats : maxAvailableSeats // ignore: cast_nullable_to_non_nullable
as int,blockedDates: null == blockedDates ? _self.blockedDates : blockedDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AvailabilityCalendar].
extension AvailabilityCalendarPatterns on AvailabilityCalendar {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailabilityCalendar value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailabilityCalendar() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailabilityCalendar value)  $default,){
final _that = this;
switch (_that) {
case _AvailabilityCalendar():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailabilityCalendar value)?  $default,){
final _that = this;
switch (_that) {
case _AvailabilityCalendar() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int maxAvailableSeats,  List<String> blockedDates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailabilityCalendar() when $default != null:
return $default(_that.maxAvailableSeats,_that.blockedDates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int maxAvailableSeats,  List<String> blockedDates)  $default,) {final _that = this;
switch (_that) {
case _AvailabilityCalendar():
return $default(_that.maxAvailableSeats,_that.blockedDates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int maxAvailableSeats,  List<String> blockedDates)?  $default,) {final _that = this;
switch (_that) {
case _AvailabilityCalendar() when $default != null:
return $default(_that.maxAvailableSeats,_that.blockedDates);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvailabilityCalendar extends AvailabilityCalendar {
  const _AvailabilityCalendar({required this.maxAvailableSeats, final  List<String> blockedDates = const <String>[]}): _blockedDates = blockedDates,super._();
  factory _AvailabilityCalendar.fromJson(Map<String, dynamic> json) => _$AvailabilityCalendarFromJson(json);

/// The largest bookable seat count anywhere in the queried range.
/// Use as the stepper's max, not as a per-day remaining count.
@override final  int maxAvailableSeats;
/// Bare `yyyy-MM-dd` dates that CANNOT be booked. Everything not
/// listed is open. Defaults to empty so a missing or null key reads
/// as "nothing blocked" rather than throwing.
 final  List<String> _blockedDates;
/// Bare `yyyy-MM-dd` dates that CANNOT be booked. Everything not
/// listed is open. Defaults to empty so a missing or null key reads
/// as "nothing blocked" rather than throwing.
@override@JsonKey() List<String> get blockedDates {
  if (_blockedDates is EqualUnmodifiableListView) return _blockedDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blockedDates);
}


/// Create a copy of AvailabilityCalendar
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailabilityCalendarCopyWith<_AvailabilityCalendar> get copyWith => __$AvailabilityCalendarCopyWithImpl<_AvailabilityCalendar>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailabilityCalendarToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailabilityCalendar&&(identical(other.maxAvailableSeats, maxAvailableSeats) || other.maxAvailableSeats == maxAvailableSeats)&&const DeepCollectionEquality().equals(other._blockedDates, _blockedDates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,maxAvailableSeats,const DeepCollectionEquality().hash(_blockedDates));

@override
String toString() {
  return 'AvailabilityCalendar(maxAvailableSeats: $maxAvailableSeats, blockedDates: $blockedDates)';
}


}

/// @nodoc
abstract mixin class _$AvailabilityCalendarCopyWith<$Res> implements $AvailabilityCalendarCopyWith<$Res> {
  factory _$AvailabilityCalendarCopyWith(_AvailabilityCalendar value, $Res Function(_AvailabilityCalendar) _then) = __$AvailabilityCalendarCopyWithImpl;
@override @useResult
$Res call({
 int maxAvailableSeats, List<String> blockedDates
});




}
/// @nodoc
class __$AvailabilityCalendarCopyWithImpl<$Res>
    implements _$AvailabilityCalendarCopyWith<$Res> {
  __$AvailabilityCalendarCopyWithImpl(this._self, this._then);

  final _AvailabilityCalendar _self;
  final $Res Function(_AvailabilityCalendar) _then;

/// Create a copy of AvailabilityCalendar
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxAvailableSeats = null,Object? blockedDates = null,}) {
  return _then(_AvailabilityCalendar(
maxAvailableSeats: null == maxAvailableSeats ? _self.maxAvailableSeats : maxAvailableSeats // ignore: cast_nullable_to_non_nullable
as int,blockedDates: null == blockedDates ? _self._blockedDates : blockedDates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
