// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_product_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeProductCard {

/// Product id — what `GET /api/shop/products/{id}` and a
/// `shop_product` banner's `link_target_id` use.
 int get id;/// Product name, already localized by the CMS.
 String get title;/// Original price. Decimal string.
 String get price;/// Discounted price, or null when not on sale. Decimal string.
 String? get salePrice;/// Product thumbnail.
 ApiImage? get image;/// The CMS "featured" flag on the product row — **not** a statement
/// about which list this came in.
 bool get isFeatured;/// Whether the authenticated user has favourited it. Always false
/// on an unauthenticated request.
 bool get isFavorited;/// Whether the studio has any of this to sell.
 bool get inStock;/// How many are left, or NULL when the CMS row tracks no stock —
/// 13 of the 15 live products are untracked. Null means "no limit
/// worth showing", NOT "none left"; that is [inStock].
 int? get stock;/// The most one order may take: [stock] when tracked, a flat 100
/// when not.
 int get maxQuantity;
/// Create a copy of HomeProductCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeProductCardCopyWith<HomeProductCard> get copyWith => _$HomeProductCardCopyWithImpl<HomeProductCard>(this as HomeProductCard, _$identity);

  /// Serializes this HomeProductCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeProductCard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.salePrice, salePrice) || other.salePrice == salePrice)&&(identical(other.image, image) || other.image == image)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isFavorited, isFavorited) || other.isFavorited == isFavorited)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,salePrice,image,isFeatured,isFavorited,inStock,stock,maxQuantity);

@override
String toString() {
  return 'HomeProductCard(id: $id, title: $title, price: $price, salePrice: $salePrice, image: $image, isFeatured: $isFeatured, isFavorited: $isFavorited, inStock: $inStock, stock: $stock, maxQuantity: $maxQuantity)';
}


}

/// @nodoc
abstract mixin class $HomeProductCardCopyWith<$Res>  {
  factory $HomeProductCardCopyWith(HomeProductCard value, $Res Function(HomeProductCard) _then) = _$HomeProductCardCopyWithImpl;
@useResult
$Res call({
 int id, String title, String price, String? salePrice, ApiImage? image, bool isFeatured, bool isFavorited, bool inStock, int? stock, int maxQuantity
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$HomeProductCardCopyWithImpl<$Res>
    implements $HomeProductCardCopyWith<$Res> {
  _$HomeProductCardCopyWithImpl(this._self, this._then);

  final HomeProductCard _self;
  final $Res Function(HomeProductCard) _then;

/// Create a copy of HomeProductCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? price = null,Object? salePrice = freezed,Object? image = freezed,Object? isFeatured = null,Object? isFavorited = null,Object? inStock = null,Object? stock = freezed,Object? maxQuantity = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,salePrice: freezed == salePrice ? _self.salePrice : salePrice // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isFavorited: null == isFavorited ? _self.isFavorited : isFavorited // ignore: cast_nullable_to_non_nullable
as bool,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int?,maxQuantity: null == maxQuantity ? _self.maxQuantity : maxQuantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of HomeProductCard
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


/// Adds pattern-matching-related methods to [HomeProductCard].
extension HomeProductCardPatterns on HomeProductCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeProductCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeProductCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeProductCard value)  $default,){
final _that = this;
switch (_that) {
case _HomeProductCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeProductCard value)?  $default,){
final _that = this;
switch (_that) {
case _HomeProductCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool inStock,  int? stock,  int maxQuantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeProductCard() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool inStock,  int? stock,  int maxQuantity)  $default,) {final _that = this;
switch (_that) {
case _HomeProductCard():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool inStock,  int? stock,  int maxQuantity)?  $default,) {final _that = this;
switch (_that) {
case _HomeProductCard() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.salePrice,_that.image,_that.isFeatured,_that.isFavorited,_that.inStock,_that.stock,_that.maxQuantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeProductCard extends HomeProductCard {
  const _HomeProductCard({required this.id, required this.title, required this.price, this.salePrice, this.image, required this.isFeatured, required this.isFavorited, required this.inStock, this.stock, required this.maxQuantity}): super._();
  factory _HomeProductCard.fromJson(Map<String, dynamic> json) => _$HomeProductCardFromJson(json);

/// Product id — what `GET /api/shop/products/{id}` and a
/// `shop_product` banner's `link_target_id` use.
@override final  int id;
/// Product name, already localized by the CMS.
@override final  String title;
/// Original price. Decimal string.
@override final  String price;
/// Discounted price, or null when not on sale. Decimal string.
@override final  String? salePrice;
/// Product thumbnail.
@override final  ApiImage? image;
/// The CMS "featured" flag on the product row — **not** a statement
/// about which list this came in.
@override final  bool isFeatured;
/// Whether the authenticated user has favourited it. Always false
/// on an unauthenticated request.
@override final  bool isFavorited;
/// Whether the studio has any of this to sell.
@override final  bool inStock;
/// How many are left, or NULL when the CMS row tracks no stock —
/// 13 of the 15 live products are untracked. Null means "no limit
/// worth showing", NOT "none left"; that is [inStock].
@override final  int? stock;
/// The most one order may take: [stock] when tracked, a flat 100
/// when not.
@override final  int maxQuantity;

/// Create a copy of HomeProductCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeProductCardCopyWith<_HomeProductCard> get copyWith => __$HomeProductCardCopyWithImpl<_HomeProductCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeProductCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeProductCard&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.salePrice, salePrice) || other.salePrice == salePrice)&&(identical(other.image, image) || other.image == image)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isFavorited, isFavorited) || other.isFavorited == isFavorited)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,salePrice,image,isFeatured,isFavorited,inStock,stock,maxQuantity);

@override
String toString() {
  return 'HomeProductCard(id: $id, title: $title, price: $price, salePrice: $salePrice, image: $image, isFeatured: $isFeatured, isFavorited: $isFavorited, inStock: $inStock, stock: $stock, maxQuantity: $maxQuantity)';
}


}

/// @nodoc
abstract mixin class _$HomeProductCardCopyWith<$Res> implements $HomeProductCardCopyWith<$Res> {
  factory _$HomeProductCardCopyWith(_HomeProductCard value, $Res Function(_HomeProductCard) _then) = __$HomeProductCardCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String price, String? salePrice, ApiImage? image, bool isFeatured, bool isFavorited, bool inStock, int? stock, int maxQuantity
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$HomeProductCardCopyWithImpl<$Res>
    implements _$HomeProductCardCopyWith<$Res> {
  __$HomeProductCardCopyWithImpl(this._self, this._then);

  final _HomeProductCard _self;
  final $Res Function(_HomeProductCard) _then;

/// Create a copy of HomeProductCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? price = null,Object? salePrice = freezed,Object? image = freezed,Object? isFeatured = null,Object? isFavorited = null,Object? inStock = null,Object? stock = freezed,Object? maxQuantity = null,}) {
  return _then(_HomeProductCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,salePrice: freezed == salePrice ? _self.salePrice : salePrice // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isFavorited: null == isFavorited ? _self.isFavorited : isFavorited // ignore: cast_nullable_to_non_nullable
as bool,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool,stock: freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int?,maxQuantity: null == maxQuantity ? _self.maxQuantity : maxQuantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of HomeProductCard
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
