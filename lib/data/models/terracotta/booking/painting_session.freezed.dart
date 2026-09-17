// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'painting_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaintingSession {

@JsonKey(name: 'booking_id') int? get bookingId;/// `Y-m-d`, the studio's clock. Printed as received.
 String? get date;@JsonKey(name: 'workshop_title') String? get workshopTitle;@JsonKey(name: 'is_upcoming') bool get isUpcoming;
/// Create a copy of PaintingSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaintingSessionCopyWith<PaintingSession> get copyWith => _$PaintingSessionCopyWithImpl<PaintingSession>(this as PaintingSession, _$identity);

  /// Serializes this PaintingSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaintingSession&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.date, date) || other.date == date)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.isUpcoming, isUpcoming) || other.isUpcoming == isUpcoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId,date,workshopTitle,isUpcoming);

@override
String toString() {
  return 'PaintingSession(bookingId: $bookingId, date: $date, workshopTitle: $workshopTitle, isUpcoming: $isUpcoming)';
}


}

/// @nodoc
abstract mixin class $PaintingSessionCopyWith<$Res>  {
  factory $PaintingSessionCopyWith(PaintingSession value, $Res Function(PaintingSession) _then) = _$PaintingSessionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'booking_id') int? bookingId, String? date,@JsonKey(name: 'workshop_title') String? workshopTitle,@JsonKey(name: 'is_upcoming') bool isUpcoming
});




}
/// @nodoc
class _$PaintingSessionCopyWithImpl<$Res>
    implements $PaintingSessionCopyWith<$Res> {
  _$PaintingSessionCopyWithImpl(this._self, this._then);

  final PaintingSession _self;
  final $Res Function(PaintingSession) _then;

/// Create a copy of PaintingSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookingId = freezed,Object? date = freezed,Object? workshopTitle = freezed,Object? isUpcoming = null,}) {
  return _then(_self.copyWith(
bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,workshopTitle: freezed == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String?,isUpcoming: null == isUpcoming ? _self.isUpcoming : isUpcoming // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaintingSession].
extension PaintingSessionPatterns on PaintingSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaintingSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaintingSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaintingSession value)  $default,){
final _that = this;
switch (_that) {
case _PaintingSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaintingSession value)?  $default,){
final _that = this;
switch (_that) {
case _PaintingSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  int? bookingId,  String? date, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'is_upcoming')  bool isUpcoming)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaintingSession() when $default != null:
return $default(_that.bookingId,_that.date,_that.workshopTitle,_that.isUpcoming);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  int? bookingId,  String? date, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'is_upcoming')  bool isUpcoming)  $default,) {final _that = this;
switch (_that) {
case _PaintingSession():
return $default(_that.bookingId,_that.date,_that.workshopTitle,_that.isUpcoming);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'booking_id')  int? bookingId,  String? date, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'is_upcoming')  bool isUpcoming)?  $default,) {final _that = this;
switch (_that) {
case _PaintingSession() when $default != null:
return $default(_that.bookingId,_that.date,_that.workshopTitle,_that.isUpcoming);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaintingSession implements PaintingSession {
  const _PaintingSession({@JsonKey(name: 'booking_id') this.bookingId, this.date, @JsonKey(name: 'workshop_title') this.workshopTitle, @JsonKey(name: 'is_upcoming') this.isUpcoming = false});
  factory _PaintingSession.fromJson(Map<String, dynamic> json) => _$PaintingSessionFromJson(json);

@override@JsonKey(name: 'booking_id') final  int? bookingId;
/// `Y-m-d`, the studio's clock. Printed as received.
@override final  String? date;
@override@JsonKey(name: 'workshop_title') final  String? workshopTitle;
@override@JsonKey(name: 'is_upcoming') final  bool isUpcoming;

/// Create a copy of PaintingSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaintingSessionCopyWith<_PaintingSession> get copyWith => __$PaintingSessionCopyWithImpl<_PaintingSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaintingSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaintingSession&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.date, date) || other.date == date)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.isUpcoming, isUpcoming) || other.isUpcoming == isUpcoming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId,date,workshopTitle,isUpcoming);

@override
String toString() {
  return 'PaintingSession(bookingId: $bookingId, date: $date, workshopTitle: $workshopTitle, isUpcoming: $isUpcoming)';
}


}

/// @nodoc
abstract mixin class _$PaintingSessionCopyWith<$Res> implements $PaintingSessionCopyWith<$Res> {
  factory _$PaintingSessionCopyWith(_PaintingSession value, $Res Function(_PaintingSession) _then) = __$PaintingSessionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'booking_id') int? bookingId, String? date,@JsonKey(name: 'workshop_title') String? workshopTitle,@JsonKey(name: 'is_upcoming') bool isUpcoming
});




}
/// @nodoc
class __$PaintingSessionCopyWithImpl<$Res>
    implements _$PaintingSessionCopyWith<$Res> {
  __$PaintingSessionCopyWithImpl(this._self, this._then);

  final _PaintingSession _self;
  final $Res Function(_PaintingSession) _then;

/// Create a copy of PaintingSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookingId = freezed,Object? date = freezed,Object? workshopTitle = freezed,Object? isUpcoming = null,}) {
  return _then(_PaintingSession(
bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,workshopTitle: freezed == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String?,isUpcoming: null == isUpcoming ? _self.isUpcoming : isUpcoming // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
