// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_piece.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingPiece {

 int get id;/// What the customer called it. Nullable: a piece can exist with
/// no name on an older booking.
 String? get label;/// The session it was MADE in — not necessarily this booking, when
/// the piece is being read off a paint booking.
@JsonKey(name: 'made_in_booking_id') int? get madeInBookingId;/// `Y-m-d` of that session, printed as received.
@JsonKey(name: 'made_on') String? get madeOn; List<ApiImage> get images;/// Whether it can still be booked into a paint workshop. False
/// once it has been.
@JsonKey(name: 'is_available_to_paint') bool get isAvailableToPaint;/// Where it is going next, or null when it is going nowhere.
///
/// While this is upcoming the collection countdown is OFF — see
/// [PaintingSession].
@JsonKey(name: 'painting_session') PaintingSession? get paintingSession;
/// Create a copy of BookingPiece
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingPieceCopyWith<BookingPiece> get copyWith => _$BookingPieceCopyWithImpl<BookingPiece>(this as BookingPiece, _$identity);

  /// Serializes this BookingPiece to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingPiece&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.madeInBookingId, madeInBookingId) || other.madeInBookingId == madeInBookingId)&&(identical(other.madeOn, madeOn) || other.madeOn == madeOn)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.isAvailableToPaint, isAvailableToPaint) || other.isAvailableToPaint == isAvailableToPaint)&&(identical(other.paintingSession, paintingSession) || other.paintingSession == paintingSession));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,madeInBookingId,madeOn,const DeepCollectionEquality().hash(images),isAvailableToPaint,paintingSession);

@override
String toString() {
  return 'BookingPiece(id: $id, label: $label, madeInBookingId: $madeInBookingId, madeOn: $madeOn, images: $images, isAvailableToPaint: $isAvailableToPaint, paintingSession: $paintingSession)';
}


}

/// @nodoc
abstract mixin class $BookingPieceCopyWith<$Res>  {
  factory $BookingPieceCopyWith(BookingPiece value, $Res Function(BookingPiece) _then) = _$BookingPieceCopyWithImpl;
@useResult
$Res call({
 int id, String? label,@JsonKey(name: 'made_in_booking_id') int? madeInBookingId,@JsonKey(name: 'made_on') String? madeOn, List<ApiImage> images,@JsonKey(name: 'is_available_to_paint') bool isAvailableToPaint,@JsonKey(name: 'painting_session') PaintingSession? paintingSession
});


$PaintingSessionCopyWith<$Res>? get paintingSession;

}
/// @nodoc
class _$BookingPieceCopyWithImpl<$Res>
    implements $BookingPieceCopyWith<$Res> {
  _$BookingPieceCopyWithImpl(this._self, this._then);

  final BookingPiece _self;
  final $Res Function(BookingPiece) _then;

/// Create a copy of BookingPiece
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = freezed,Object? madeInBookingId = freezed,Object? madeOn = freezed,Object? images = null,Object? isAvailableToPaint = null,Object? paintingSession = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,madeInBookingId: freezed == madeInBookingId ? _self.madeInBookingId : madeInBookingId // ignore: cast_nullable_to_non_nullable
as int?,madeOn: freezed == madeOn ? _self.madeOn : madeOn // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,isAvailableToPaint: null == isAvailableToPaint ? _self.isAvailableToPaint : isAvailableToPaint // ignore: cast_nullable_to_non_nullable
as bool,paintingSession: freezed == paintingSession ? _self.paintingSession : paintingSession // ignore: cast_nullable_to_non_nullable
as PaintingSession?,
  ));
}
/// Create a copy of BookingPiece
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaintingSessionCopyWith<$Res>? get paintingSession {
    if (_self.paintingSession == null) {
    return null;
  }

  return $PaintingSessionCopyWith<$Res>(_self.paintingSession!, (value) {
    return _then(_self.copyWith(paintingSession: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingPiece].
extension BookingPiecePatterns on BookingPiece {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingPiece value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingPiece() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingPiece value)  $default,){
final _that = this;
switch (_that) {
case _BookingPiece():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingPiece value)?  $default,){
final _that = this;
switch (_that) {
case _BookingPiece() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? label, @JsonKey(name: 'made_in_booking_id')  int? madeInBookingId, @JsonKey(name: 'made_on')  String? madeOn,  List<ApiImage> images, @JsonKey(name: 'is_available_to_paint')  bool isAvailableToPaint, @JsonKey(name: 'painting_session')  PaintingSession? paintingSession)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingPiece() when $default != null:
return $default(_that.id,_that.label,_that.madeInBookingId,_that.madeOn,_that.images,_that.isAvailableToPaint,_that.paintingSession);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? label, @JsonKey(name: 'made_in_booking_id')  int? madeInBookingId, @JsonKey(name: 'made_on')  String? madeOn,  List<ApiImage> images, @JsonKey(name: 'is_available_to_paint')  bool isAvailableToPaint, @JsonKey(name: 'painting_session')  PaintingSession? paintingSession)  $default,) {final _that = this;
switch (_that) {
case _BookingPiece():
return $default(_that.id,_that.label,_that.madeInBookingId,_that.madeOn,_that.images,_that.isAvailableToPaint,_that.paintingSession);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? label, @JsonKey(name: 'made_in_booking_id')  int? madeInBookingId, @JsonKey(name: 'made_on')  String? madeOn,  List<ApiImage> images, @JsonKey(name: 'is_available_to_paint')  bool isAvailableToPaint, @JsonKey(name: 'painting_session')  PaintingSession? paintingSession)?  $default,) {final _that = this;
switch (_that) {
case _BookingPiece() when $default != null:
return $default(_that.id,_that.label,_that.madeInBookingId,_that.madeOn,_that.images,_that.isAvailableToPaint,_that.paintingSession);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingPiece extends BookingPiece {
  const _BookingPiece({required this.id, this.label, @JsonKey(name: 'made_in_booking_id') this.madeInBookingId, @JsonKey(name: 'made_on') this.madeOn, final  List<ApiImage> images = const <ApiImage>[], @JsonKey(name: 'is_available_to_paint') this.isAvailableToPaint = true, @JsonKey(name: 'painting_session') this.paintingSession}): _images = images,super._();
  factory _BookingPiece.fromJson(Map<String, dynamic> json) => _$BookingPieceFromJson(json);

@override final  int id;
/// What the customer called it. Nullable: a piece can exist with
/// no name on an older booking.
@override final  String? label;
/// The session it was MADE in — not necessarily this booking, when
/// the piece is being read off a paint booking.
@override@JsonKey(name: 'made_in_booking_id') final  int? madeInBookingId;
/// `Y-m-d` of that session, printed as received.
@override@JsonKey(name: 'made_on') final  String? madeOn;
 final  List<ApiImage> _images;
@override@JsonKey() List<ApiImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// Whether it can still be booked into a paint workshop. False
/// once it has been.
@override@JsonKey(name: 'is_available_to_paint') final  bool isAvailableToPaint;
/// Where it is going next, or null when it is going nowhere.
///
/// While this is upcoming the collection countdown is OFF — see
/// [PaintingSession].
@override@JsonKey(name: 'painting_session') final  PaintingSession? paintingSession;

/// Create a copy of BookingPiece
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingPieceCopyWith<_BookingPiece> get copyWith => __$BookingPieceCopyWithImpl<_BookingPiece>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingPieceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingPiece&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.madeInBookingId, madeInBookingId) || other.madeInBookingId == madeInBookingId)&&(identical(other.madeOn, madeOn) || other.madeOn == madeOn)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.isAvailableToPaint, isAvailableToPaint) || other.isAvailableToPaint == isAvailableToPaint)&&(identical(other.paintingSession, paintingSession) || other.paintingSession == paintingSession));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,madeInBookingId,madeOn,const DeepCollectionEquality().hash(_images),isAvailableToPaint,paintingSession);

@override
String toString() {
  return 'BookingPiece(id: $id, label: $label, madeInBookingId: $madeInBookingId, madeOn: $madeOn, images: $images, isAvailableToPaint: $isAvailableToPaint, paintingSession: $paintingSession)';
}


}

/// @nodoc
abstract mixin class _$BookingPieceCopyWith<$Res> implements $BookingPieceCopyWith<$Res> {
  factory _$BookingPieceCopyWith(_BookingPiece value, $Res Function(_BookingPiece) _then) = __$BookingPieceCopyWithImpl;
@override @useResult
$Res call({
 int id, String? label,@JsonKey(name: 'made_in_booking_id') int? madeInBookingId,@JsonKey(name: 'made_on') String? madeOn, List<ApiImage> images,@JsonKey(name: 'is_available_to_paint') bool isAvailableToPaint,@JsonKey(name: 'painting_session') PaintingSession? paintingSession
});


@override $PaintingSessionCopyWith<$Res>? get paintingSession;

}
/// @nodoc
class __$BookingPieceCopyWithImpl<$Res>
    implements _$BookingPieceCopyWith<$Res> {
  __$BookingPieceCopyWithImpl(this._self, this._then);

  final _BookingPiece _self;
  final $Res Function(_BookingPiece) _then;

/// Create a copy of BookingPiece
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = freezed,Object? madeInBookingId = freezed,Object? madeOn = freezed,Object? images = null,Object? isAvailableToPaint = null,Object? paintingSession = freezed,}) {
  return _then(_BookingPiece(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,madeInBookingId: freezed == madeInBookingId ? _self.madeInBookingId : madeInBookingId // ignore: cast_nullable_to_non_nullable
as int?,madeOn: freezed == madeOn ? _self.madeOn : madeOn // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,isAvailableToPaint: null == isAvailableToPaint ? _self.isAvailableToPaint : isAvailableToPaint // ignore: cast_nullable_to_non_nullable
as bool,paintingSession: freezed == paintingSession ? _self.paintingSession : paintingSession // ignore: cast_nullable_to_non_nullable
as PaintingSession?,
  ));
}

/// Create a copy of BookingPiece
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaintingSessionCopyWith<$Res>? get paintingSession {
    if (_self.paintingSession == null) {
    return null;
  }

  return $PaintingSessionCopyWith<$Res>(_self.paintingSession!, (value) {
    return _then(_self.copyWith(paintingSession: value));
  });
}
}

// dart format on
