// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'line_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LineProduct {

/// Catalogue product id — this is what `/api/shop/products/{id}`
/// and `/api/shop/favorites/{product}` take. It is NOT the cart or
/// order line id.
 int get id;/// Already localized for the `Accept-Language` of the request.
 String get title;/// List price as a decimal string (`"45.00"`). Never a double.
 String get price;/// Discounted price as a decimal string, or null when not on sale.
 String? get salePrice;/// Thumbnail. Nullable — see the class doc.
 ApiImage? get image;/// Merchandising flag from the CMS.
 bool get isFeatured;/// Whether the CALLER has favourited it. Reflects the caller's
/// account, so it flips after `POST/DELETE /api/shop/favorites`.
 bool get isFavorited;/// Whether the studio has any of this to sell — **null on an ORDER
/// line**, where it would be meaningless: an order is a record of
/// what was bought, not an offer to buy it again. The server sends
/// it on every CART line. Null is "unknown", never "sold out".
 bool? get inStock;/// How many are left, or NULL when the CMS row tracks no stock at
/// all — 13 of the 15 live products are untracked. Null therefore
/// means "no limit worth showing", NOT "none left"; that is
/// [inStock].
 int? get stock;/// The most one order may take: [stock] when it is tracked, and a
/// flat 100 when it is not. Asking for more is a 422 either way —
/// `errors.cart` names the piece and the number when stock is the
/// reason, `errors.quantity` when the 100 cap is. Null on an order
/// line, for the same reason as [inStock].
 int? get maxQuantity;
/// Create a copy of LineProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineProductCopyWith<LineProduct> get copyWith => _$LineProductCopyWithImpl<LineProduct>(this as LineProduct, _$identity);

  /// Serializes this LineProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.salePrice, salePrice) || other.salePrice == salePrice)&&(identical(other.image, image) || other.image == image)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isFavorited, isFavorited) || other.isFavorited == isFavorited)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,salePrice,image,isFeatured,isFavorited,inStock,stock,maxQuantity);

@override
String toString() {
  return 'LineProduct(id: $id, title: $title, price: $price, salePrice: $salePrice, image: $image, isFeatured: $isFeatured, isFavorited: $isFavorited, inStock: $inStock, stock: $stock, maxQuantity: $maxQuantity)';
}


}

/// @nodoc
abstract mixin class $LineProductCopyWith<$Res>  {
  factory $LineProductCopyWith(LineProduct value, $Res Function(LineProduct) _then) = _$LineProductCopyWithImpl;
@useResult
$Res call({
 int id, String title, String price, String? salePrice, ApiImage? image, bool isFeatured, bool isFavorited, bool? inStock, int? stock, int? maxQuantity
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$LineProductCopyWithImpl<$Res>
    implements $LineProductCopyWith<$Res> {
  _$LineProductCopyWithImpl(this._self, this._then);

  final LineProduct _self;
  final $Res Function(LineProduct) _then;

/// Create a copy of LineProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? price = null,Object? salePrice = freezed,Object? image = freezed,Object? isFeatured = null,Object? isFavorited = null,Object? inStock = freezed,Object? stock = freezed,Object? maxQuantity = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,salePrice: freezed == salePrice ? _self.salePrice : salePrice // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isFavorited: null == isFavorited ? _self.isFavorited : isFavorited // ignore: cast_nullable_to_non_nullable
as bool,inStock: freezed == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int?,maxQuantity: freezed == maxQuantity ? _self.maxQuantity : maxQuantity // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of LineProduct
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


/// Adds pattern-matching-related methods to [LineProduct].
extension LineProductPatterns on LineProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LineProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LineProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LineProduct value)  $default,){
final _that = this;
switch (_that) {
case _LineProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LineProduct value)?  $default,){
final _that = this;
switch (_that) {
case _LineProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool? inStock,  int? stock,  int? maxQuantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LineProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.salePrice,_that.image,_that.isFeatured,_that.isFavorited,_that.inStock,_that.stock,_that.maxQuantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool? inStock,  int? stock,  int? maxQuantity)  $default,) {final _that = this;
switch (_that) {
case _LineProduct():
return $default(_that.id,_that.title,_that.price,_that.salePrice,_that.image,_that.isFeatured,_that.isFavorited,_that.inStock,_that.stock,_that.maxQuantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool? inStock,  int? stock,  int? maxQuantity)?  $default,) {final _that = this;
switch (_that) {
case _LineProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.salePrice,_that.image,_that.isFeatured,_that.isFavorited,_that.inStock,_that.stock,_that.maxQuantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LineProduct extends LineProduct {
  const _LineProduct({required this.id, required this.title, required this.price, this.salePrice, this.image, required this.isFeatured, required this.isFavorited, this.inStock, this.stock, this.maxQuantity}): super._();
  factory _LineProduct.fromJson(Map<String, dynamic> json) => _$LineProductFromJson(json);

/// Catalogue product id — this is what `/api/shop/products/{id}`
/// and `/api/shop/favorites/{product}` take. It is NOT the cart or
/// order line id.
@override final  int id;
/// Already localized for the `Accept-Language` of the request.
@override final  String title;
/// List price as a decimal string (`"45.00"`). Never a double.
@override final  String price;
/// Discounted price as a decimal string, or null when not on sale.
@override final  String? salePrice;
/// Thumbnail. Nullable — see the class doc.
@override final  ApiImage? image;
/// Merchandising flag from the CMS.
@override final  bool isFeatured;
/// Whether the CALLER has favourited it. Reflects the caller's
/// account, so it flips after `POST/DELETE /api/shop/favorites`.
@override final  bool isFavorited;
/// Whether the studio has any of this to sell — **null on an ORDER
/// line**, where it would be meaningless: an order is a record of
/// what was bought, not an offer to buy it again. The server sends
/// it on every CART line. Null is "unknown", never "sold out".
@override final  bool? inStock;
/// How many are left, or NULL when the CMS row tracks no stock at
/// all — 13 of the 15 live products are untracked. Null therefore
/// means "no limit worth showing", NOT "none left"; that is
/// [inStock].
@override final  int? stock;
/// The most one order may take: [stock] when it is tracked, and a
/// flat 100 when it is not. Asking for more is a 422 either way —
/// `errors.cart` names the piece and the number when stock is the
/// reason, `errors.quantity` when the 100 cap is. Null on an order
/// line, for the same reason as [inStock].
@override final  int? maxQuantity;

/// Create a copy of LineProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LineProductCopyWith<_LineProduct> get copyWith => __$LineProductCopyWithImpl<_LineProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LineProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LineProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.salePrice, salePrice) || other.salePrice == salePrice)&&(identical(other.image, image) || other.image == image)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isFavorited, isFavorited) || other.isFavorited == isFavorited)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,salePrice,image,isFeatured,isFavorited,inStock,stock,maxQuantity);

@override
String toString() {
  return 'LineProduct(id: $id, title: $title, price: $price, salePrice: $salePrice, image: $image, isFeatured: $isFeatured, isFavorited: $isFavorited, inStock: $inStock, stock: $stock, maxQuantity: $maxQuantity)';
}


}

/// @nodoc
abstract mixin class _$LineProductCopyWith<$Res> implements $LineProductCopyWith<$Res> {
  factory _$LineProductCopyWith(_LineProduct value, $Res Function(_LineProduct) _then) = __$LineProductCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String price, String? salePrice, ApiImage? image, bool isFeatured, bool isFavorited, bool? inStock, int? stock, int? maxQuantity
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$LineProductCopyWithImpl<$Res>
    implements _$LineProductCopyWith<$Res> {
  __$LineProductCopyWithImpl(this._self, this._then);

  final _LineProduct _self;
  final $Res Function(_LineProduct) _then;

/// Create a copy of LineProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? price = null,Object? salePrice = freezed,Object? image = freezed,Object? isFeatured = null,Object? isFavorited = null,Object? inStock = freezed,Object? stock = freezed,Object? maxQuantity = freezed,}) {
  return _then(_LineProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,salePrice: freezed == salePrice ? _self.salePrice : salePrice // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isFavorited: null == isFavorited ? _self.isFavorited : isFavorited // ignore: cast_nullable_to_non_nullable
as bool,inStock: freezed == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool?,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int?,maxQuantity: freezed == maxQuantity ? _self.maxQuantity : maxQuantity // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of LineProduct
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
