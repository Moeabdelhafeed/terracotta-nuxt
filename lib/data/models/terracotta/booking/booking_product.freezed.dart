// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingProduct {

/// The product inside the workshop's `categories[]` tree — NOT a
/// line id and NOT unique per booking.
///
/// NULL on a line that is one of the customer's OWN pieces brought
/// back to be painted; [workshopBookingPieceId] names it instead.
/// The two are mutually exclusive, which is the server's own rule
/// for the `products[]` a booking is created with.
 int? get workshopProductId;/// The customer's own piece, when the line is one. Null on a
/// catalogue line.
 int? get workshopBookingPieceId;/// Already-localized product name (`"Lavender Jar"`). Display
/// as-is; do not look it up in the ARB. NULL when the CMS has no
/// name for it in the requested locale — see the class doc.
 String? get title;/// Secondary line under [title]. Null in every capture.
 String? get subtitle;/// Thumbnail. Paint it via `image.display`, never `image.url`.
/// Null in every capture — see the class doc.
 ApiImage? get image;/// How many of this product the booking includes.
 int get quantity;/// Price of ONE unit, as a decimal string (`"10.00"`). Never a
/// double.
 String get unitPrice;
/// Create a copy of BookingProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingProductCopyWith<BookingProduct> get copyWith => _$BookingProductCopyWithImpl<BookingProduct>(this as BookingProduct, _$identity);

  /// Serializes this BookingProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingProduct&&(identical(other.workshopProductId, workshopProductId) || other.workshopProductId == workshopProductId)&&(identical(other.workshopBookingPieceId, workshopBookingPieceId) || other.workshopBookingPieceId == workshopBookingPieceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.image, image) || other.image == image)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workshopProductId,workshopBookingPieceId,title,subtitle,image,quantity,unitPrice);

@override
String toString() {
  return 'BookingProduct(workshopProductId: $workshopProductId, workshopBookingPieceId: $workshopBookingPieceId, title: $title, subtitle: $subtitle, image: $image, quantity: $quantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class $BookingProductCopyWith<$Res>  {
  factory $BookingProductCopyWith(BookingProduct value, $Res Function(BookingProduct) _then) = _$BookingProductCopyWithImpl;
@useResult
$Res call({
 int? workshopProductId, int? workshopBookingPieceId, String? title, String? subtitle, ApiImage? image, int quantity, String unitPrice
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$BookingProductCopyWithImpl<$Res>
    implements $BookingProductCopyWith<$Res> {
  _$BookingProductCopyWithImpl(this._self, this._then);

  final BookingProduct _self;
  final $Res Function(BookingProduct) _then;

/// Create a copy of BookingProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workshopProductId = freezed,Object? workshopBookingPieceId = freezed,Object? title = freezed,Object? subtitle = freezed,Object? image = freezed,Object? quantity = null,Object? unitPrice = null,}) {
  return _then(_self.copyWith(
workshopProductId: freezed == workshopProductId ? _self.workshopProductId : workshopProductId // ignore: cast_nullable_to_non_nullable
as int?,workshopBookingPieceId: freezed == workshopBookingPieceId ? _self.workshopBookingPieceId : workshopBookingPieceId // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of BookingProduct
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingProduct].
extension BookingProductPatterns on BookingProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingProduct value)  $default,){
final _that = this;
switch (_that) {
case _BookingProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingProduct value)?  $default,){
final _that = this;
switch (_that) {
case _BookingProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? workshopProductId,  int? workshopBookingPieceId,  String? title,  String? subtitle,  ApiImage? image,  int quantity,  String unitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingProduct() when $default != null:
return $default(_that.workshopProductId,_that.workshopBookingPieceId,_that.title,_that.subtitle,_that.image,_that.quantity,_that.unitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? workshopProductId,  int? workshopBookingPieceId,  String? title,  String? subtitle,  ApiImage? image,  int quantity,  String unitPrice)  $default,) {final _that = this;
switch (_that) {
case _BookingProduct():
return $default(_that.workshopProductId,_that.workshopBookingPieceId,_that.title,_that.subtitle,_that.image,_that.quantity,_that.unitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? workshopProductId,  int? workshopBookingPieceId,  String? title,  String? subtitle,  ApiImage? image,  int quantity,  String unitPrice)?  $default,) {final _that = this;
switch (_that) {
case _BookingProduct() when $default != null:
return $default(_that.workshopProductId,_that.workshopBookingPieceId,_that.title,_that.subtitle,_that.image,_that.quantity,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingProduct implements BookingProduct {
  const _BookingProduct({this.workshopProductId, this.workshopBookingPieceId, this.title, this.subtitle, this.image, required this.quantity, required this.unitPrice});
  factory _BookingProduct.fromJson(Map<String, dynamic> json) => _$BookingProductFromJson(json);

/// The product inside the workshop's `categories[]` tree — NOT a
/// line id and NOT unique per booking.
///
/// NULL on a line that is one of the customer's OWN pieces brought
/// back to be painted; [workshopBookingPieceId] names it instead.
/// The two are mutually exclusive, which is the server's own rule
/// for the `products[]` a booking is created with.
@override final  int? workshopProductId;
/// The customer's own piece, when the line is one. Null on a
/// catalogue line.
@override final  int? workshopBookingPieceId;
/// Already-localized product name (`"Lavender Jar"`). Display
/// as-is; do not look it up in the ARB. NULL when the CMS has no
/// name for it in the requested locale — see the class doc.
@override final  String? title;
/// Secondary line under [title]. Null in every capture.
@override final  String? subtitle;
/// Thumbnail. Paint it via `image.display`, never `image.url`.
/// Null in every capture — see the class doc.
@override final  ApiImage? image;
/// How many of this product the booking includes.
@override final  int quantity;
/// Price of ONE unit, as a decimal string (`"10.00"`). Never a
/// double.
@override final  String unitPrice;

/// Create a copy of BookingProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingProductCopyWith<_BookingProduct> get copyWith => __$BookingProductCopyWithImpl<_BookingProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingProduct&&(identical(other.workshopProductId, workshopProductId) || other.workshopProductId == workshopProductId)&&(identical(other.workshopBookingPieceId, workshopBookingPieceId) || other.workshopBookingPieceId == workshopBookingPieceId)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.image, image) || other.image == image)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workshopProductId,workshopBookingPieceId,title,subtitle,image,quantity,unitPrice);

@override
String toString() {
  return 'BookingProduct(workshopProductId: $workshopProductId, workshopBookingPieceId: $workshopBookingPieceId, title: $title, subtitle: $subtitle, image: $image, quantity: $quantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$BookingProductCopyWith<$Res> implements $BookingProductCopyWith<$Res> {
  factory _$BookingProductCopyWith(_BookingProduct value, $Res Function(_BookingProduct) _then) = __$BookingProductCopyWithImpl;
@override @useResult
$Res call({
 int? workshopProductId, int? workshopBookingPieceId, String? title, String? subtitle, ApiImage? image, int quantity, String unitPrice
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$BookingProductCopyWithImpl<$Res>
    implements _$BookingProductCopyWith<$Res> {
  __$BookingProductCopyWithImpl(this._self, this._then);

  final _BookingProduct _self;
  final $Res Function(_BookingProduct) _then;

/// Create a copy of BookingProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workshopProductId = freezed,Object? workshopBookingPieceId = freezed,Object? title = freezed,Object? subtitle = freezed,Object? image = freezed,Object? quantity = null,Object? unitPrice = null,}) {
  return _then(_BookingProduct(
workshopProductId: freezed == workshopProductId ? _self.workshopProductId : workshopProductId // ignore: cast_nullable_to_non_nullable
as int?,workshopBookingPieceId: freezed == workshopBookingPieceId ? _self.workshopBookingPieceId : workshopBookingPieceId // ignore: cast_nullable_to_non_nullable
as int?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of BookingProduct
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res>? get image {
    if (_self.image == null) {
    return null;
  }

  return $ApiImageCopyWith<$Res>(_self.image!, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}

// dart format on
