// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop_own_pieces.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkshopOwnPieces {

/// The flat rate for bringing one of your own, as a decimal STRING
/// (`"60.00"`). It replaces a catalogue product's price on the
/// line, and the customer pays it per piece.
 String get price;/// How many are available. The server counts them, so a paginated
/// or trimmed [pieces] list still says the truth.
 int get count;/// The pieces themselves, newest first. Empty for a guest.
 List<WorkshopOwnPiece> get pieces;
/// Create a copy of WorkshopOwnPieces
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopOwnPiecesCopyWith<WorkshopOwnPieces> get copyWith => _$WorkshopOwnPiecesCopyWithImpl<WorkshopOwnPieces>(this as WorkshopOwnPieces, _$identity);

  /// Serializes this WorkshopOwnPieces to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopOwnPieces&&(identical(other.price, price) || other.price == price)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.pieces, pieces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,price,count,const DeepCollectionEquality().hash(pieces));

@override
String toString() {
  return 'WorkshopOwnPieces(price: $price, count: $count, pieces: $pieces)';
}


}

/// @nodoc
abstract mixin class $WorkshopOwnPiecesCopyWith<$Res>  {
  factory $WorkshopOwnPiecesCopyWith(WorkshopOwnPieces value, $Res Function(WorkshopOwnPieces) _then) = _$WorkshopOwnPiecesCopyWithImpl;
@useResult
$Res call({
 String price, int count, List<WorkshopOwnPiece> pieces
});




}
/// @nodoc
class _$WorkshopOwnPiecesCopyWithImpl<$Res>
    implements $WorkshopOwnPiecesCopyWith<$Res> {
  _$WorkshopOwnPiecesCopyWithImpl(this._self, this._then);

  final WorkshopOwnPieces _self;
  final $Res Function(WorkshopOwnPieces) _then;

/// Create a copy of WorkshopOwnPieces
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? price = null,Object? count = null,Object? pieces = null,}) {
  return _then(_self.copyWith(
price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as List<WorkshopOwnPiece>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkshopOwnPieces].
extension WorkshopOwnPiecesPatterns on WorkshopOwnPieces {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopOwnPieces value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopOwnPieces() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopOwnPieces value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopOwnPieces():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopOwnPieces value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopOwnPieces() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String price,  int count,  List<WorkshopOwnPiece> pieces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopOwnPieces() when $default != null:
return $default(_that.price,_that.count,_that.pieces);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String price,  int count,  List<WorkshopOwnPiece> pieces)  $default,) {final _that = this;
switch (_that) {
case _WorkshopOwnPieces():
return $default(_that.price,_that.count,_that.pieces);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String price,  int count,  List<WorkshopOwnPiece> pieces)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopOwnPieces() when $default != null:
return $default(_that.price,_that.count,_that.pieces);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkshopOwnPieces extends WorkshopOwnPieces {
  const _WorkshopOwnPieces({required this.price, this.count = 0, final  List<WorkshopOwnPiece> pieces = const <WorkshopOwnPiece>[]}): _pieces = pieces,super._();
  factory _WorkshopOwnPieces.fromJson(Map<String, dynamic> json) => _$WorkshopOwnPiecesFromJson(json);

/// The flat rate for bringing one of your own, as a decimal STRING
/// (`"60.00"`). It replaces a catalogue product's price on the
/// line, and the customer pays it per piece.
@override final  String price;
/// How many are available. The server counts them, so a paginated
/// or trimmed [pieces] list still says the truth.
@override@JsonKey() final  int count;
/// The pieces themselves, newest first. Empty for a guest.
 final  List<WorkshopOwnPiece> _pieces;
/// The pieces themselves, newest first. Empty for a guest.
@override@JsonKey() List<WorkshopOwnPiece> get pieces {
  if (_pieces is EqualUnmodifiableListView) return _pieces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pieces);
}


/// Create a copy of WorkshopOwnPieces
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopOwnPiecesCopyWith<_WorkshopOwnPieces> get copyWith => __$WorkshopOwnPiecesCopyWithImpl<_WorkshopOwnPieces>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopOwnPiecesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopOwnPieces&&(identical(other.price, price) || other.price == price)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._pieces, _pieces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,price,count,const DeepCollectionEquality().hash(_pieces));

@override
String toString() {
  return 'WorkshopOwnPieces(price: $price, count: $count, pieces: $pieces)';
}


}

/// @nodoc
abstract mixin class _$WorkshopOwnPiecesCopyWith<$Res> implements $WorkshopOwnPiecesCopyWith<$Res> {
  factory _$WorkshopOwnPiecesCopyWith(_WorkshopOwnPieces value, $Res Function(_WorkshopOwnPieces) _then) = __$WorkshopOwnPiecesCopyWithImpl;
@override @useResult
$Res call({
 String price, int count, List<WorkshopOwnPiece> pieces
});




}
/// @nodoc
class __$WorkshopOwnPiecesCopyWithImpl<$Res>
    implements _$WorkshopOwnPiecesCopyWith<$Res> {
  __$WorkshopOwnPiecesCopyWithImpl(this._self, this._then);

  final _WorkshopOwnPieces _self;
  final $Res Function(_WorkshopOwnPieces) _then;

/// Create a copy of WorkshopOwnPieces
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? price = null,Object? count = null,Object? pieces = null,}) {
  return _then(_WorkshopOwnPieces(
price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,pieces: null == pieces ? _self._pieces : pieces // ignore: cast_nullable_to_non_nullable
as List<WorkshopOwnPiece>,
  ));
}


}


/// @nodoc
mixin _$WorkshopOwnPiece {

/// `workshop_booking_piece_id` — what a booking line names when it
/// brings this piece back. Quantity is ignored for it: a specific
/// object is always one.
 int get id;/// What the customer called it when they uploaded the photos —
/// "Sara's mug". Nullable: the label is what groups the photos, and
/// an older row may have none.
 String? get label;/// The booking it was made in, and the day that was. Both are for
/// telling two similar cups apart.
 int? get madeInBookingId; String? get madeOn;/// The photos of it. Empty is possible — a piece whose last photo
/// was deleted is deleted too, but a trimmed payload can still say
/// nothing.
 List<ApiImage> get images;/// Whether it can still be booked in.
///
/// False once it has been painted in another booking
/// (`painted_in_booking_id` is set). The server refuses a claimed
/// piece with `api.workshop_piece_unavailable`, so a screen that
/// offers one is a screen that 422s.
 bool get isAvailableToPaint;
/// Create a copy of WorkshopOwnPiece
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopOwnPieceCopyWith<WorkshopOwnPiece> get copyWith => _$WorkshopOwnPieceCopyWithImpl<WorkshopOwnPiece>(this as WorkshopOwnPiece, _$identity);

  /// Serializes this WorkshopOwnPiece to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopOwnPiece&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.madeInBookingId, madeInBookingId) || other.madeInBookingId == madeInBookingId)&&(identical(other.madeOn, madeOn) || other.madeOn == madeOn)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.isAvailableToPaint, isAvailableToPaint) || other.isAvailableToPaint == isAvailableToPaint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,madeInBookingId,madeOn,const DeepCollectionEquality().hash(images),isAvailableToPaint);

@override
String toString() {
  return 'WorkshopOwnPiece(id: $id, label: $label, madeInBookingId: $madeInBookingId, madeOn: $madeOn, images: $images, isAvailableToPaint: $isAvailableToPaint)';
}


}

/// @nodoc
abstract mixin class $WorkshopOwnPieceCopyWith<$Res>  {
  factory $WorkshopOwnPieceCopyWith(WorkshopOwnPiece value, $Res Function(WorkshopOwnPiece) _then) = _$WorkshopOwnPieceCopyWithImpl;
@useResult
$Res call({
 int id, String? label, int? madeInBookingId, String? madeOn, List<ApiImage> images, bool isAvailableToPaint
});




}
/// @nodoc
class _$WorkshopOwnPieceCopyWithImpl<$Res>
    implements $WorkshopOwnPieceCopyWith<$Res> {
  _$WorkshopOwnPieceCopyWithImpl(this._self, this._then);

  final WorkshopOwnPiece _self;
  final $Res Function(WorkshopOwnPiece) _then;

/// Create a copy of WorkshopOwnPiece
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = freezed,Object? madeInBookingId = freezed,Object? madeOn = freezed,Object? images = null,Object? isAvailableToPaint = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,madeInBookingId: freezed == madeInBookingId ? _self.madeInBookingId : madeInBookingId // ignore: cast_nullable_to_non_nullable
as int?,madeOn: freezed == madeOn ? _self.madeOn : madeOn // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,isAvailableToPaint: null == isAvailableToPaint ? _self.isAvailableToPaint : isAvailableToPaint // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkshopOwnPiece].
extension WorkshopOwnPiecePatterns on WorkshopOwnPiece {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopOwnPiece value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopOwnPiece() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopOwnPiece value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopOwnPiece():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopOwnPiece value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopOwnPiece() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? label,  int? madeInBookingId,  String? madeOn,  List<ApiImage> images,  bool isAvailableToPaint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopOwnPiece() when $default != null:
return $default(_that.id,_that.label,_that.madeInBookingId,_that.madeOn,_that.images,_that.isAvailableToPaint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? label,  int? madeInBookingId,  String? madeOn,  List<ApiImage> images,  bool isAvailableToPaint)  $default,) {final _that = this;
switch (_that) {
case _WorkshopOwnPiece():
return $default(_that.id,_that.label,_that.madeInBookingId,_that.madeOn,_that.images,_that.isAvailableToPaint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? label,  int? madeInBookingId,  String? madeOn,  List<ApiImage> images,  bool isAvailableToPaint)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopOwnPiece() when $default != null:
return $default(_that.id,_that.label,_that.madeInBookingId,_that.madeOn,_that.images,_that.isAvailableToPaint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkshopOwnPiece extends WorkshopOwnPiece {
  const _WorkshopOwnPiece({required this.id, this.label, this.madeInBookingId, this.madeOn, final  List<ApiImage> images = const <ApiImage>[], this.isAvailableToPaint = true}): _images = images,super._();
  factory _WorkshopOwnPiece.fromJson(Map<String, dynamic> json) => _$WorkshopOwnPieceFromJson(json);

/// `workshop_booking_piece_id` — what a booking line names when it
/// brings this piece back. Quantity is ignored for it: a specific
/// object is always one.
@override final  int id;
/// What the customer called it when they uploaded the photos —
/// "Sara's mug". Nullable: the label is what groups the photos, and
/// an older row may have none.
@override final  String? label;
/// The booking it was made in, and the day that was. Both are for
/// telling two similar cups apart.
@override final  int? madeInBookingId;
@override final  String? madeOn;
/// The photos of it. Empty is possible — a piece whose last photo
/// was deleted is deleted too, but a trimmed payload can still say
/// nothing.
 final  List<ApiImage> _images;
/// The photos of it. Empty is possible — a piece whose last photo
/// was deleted is deleted too, but a trimmed payload can still say
/// nothing.
@override@JsonKey() List<ApiImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// Whether it can still be booked in.
///
/// False once it has been painted in another booking
/// (`painted_in_booking_id` is set). The server refuses a claimed
/// piece with `api.workshop_piece_unavailable`, so a screen that
/// offers one is a screen that 422s.
@override@JsonKey() final  bool isAvailableToPaint;

/// Create a copy of WorkshopOwnPiece
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopOwnPieceCopyWith<_WorkshopOwnPiece> get copyWith => __$WorkshopOwnPieceCopyWithImpl<_WorkshopOwnPiece>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopOwnPieceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopOwnPiece&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.madeInBookingId, madeInBookingId) || other.madeInBookingId == madeInBookingId)&&(identical(other.madeOn, madeOn) || other.madeOn == madeOn)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.isAvailableToPaint, isAvailableToPaint) || other.isAvailableToPaint == isAvailableToPaint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,madeInBookingId,madeOn,const DeepCollectionEquality().hash(_images),isAvailableToPaint);

@override
String toString() {
  return 'WorkshopOwnPiece(id: $id, label: $label, madeInBookingId: $madeInBookingId, madeOn: $madeOn, images: $images, isAvailableToPaint: $isAvailableToPaint)';
}


}

/// @nodoc
abstract mixin class _$WorkshopOwnPieceCopyWith<$Res> implements $WorkshopOwnPieceCopyWith<$Res> {
  factory _$WorkshopOwnPieceCopyWith(_WorkshopOwnPiece value, $Res Function(_WorkshopOwnPiece) _then) = __$WorkshopOwnPieceCopyWithImpl;
@override @useResult
$Res call({
 int id, String? label, int? madeInBookingId, String? madeOn, List<ApiImage> images, bool isAvailableToPaint
});




}
/// @nodoc
class __$WorkshopOwnPieceCopyWithImpl<$Res>
    implements _$WorkshopOwnPieceCopyWith<$Res> {
  __$WorkshopOwnPieceCopyWithImpl(this._self, this._then);

  final _WorkshopOwnPiece _self;
  final $Res Function(_WorkshopOwnPiece) _then;

/// Create a copy of WorkshopOwnPiece
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = freezed,Object? madeInBookingId = freezed,Object? madeOn = freezed,Object? images = null,Object? isAvailableToPaint = null,}) {
  return _then(_WorkshopOwnPiece(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,madeInBookingId: freezed == madeInBookingId ? _self.madeInBookingId : madeInBookingId // ignore: cast_nullable_to_non_nullable
as int?,madeOn: freezed == madeOn ? _self.madeOn : madeOn // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,isAvailableToPaint: null == isAvailableToPaint ? _self.isAvailableToPaint : isAvailableToPaint // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
