// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductDetail {

// ---- the `Product` half, sent verbatim ----
/// Product id.
 int get id;/// Already-localized display name.
 String get title;/// List price as a decimal string (`"45.00"`).
 String get price;/// Offer price as a decimal string, or null when not on offer.
 String? get salePrice;/// Primary/cover image. NULL on CMS rows with no image set — paint
/// via `image?.display`, never `image.url`.
 ApiImage? get image;/// CMS-curated home-rail flag.
 bool get isFeatured;/// Per-user favourite state at fetch time.
 bool get isFavorited;// ---- detail-only additions ----
/// Long-form localized body copy. Plain text in the capture, not
/// HTML or Markdown.
/// Whether the studio has any of this to sell. False is a piece the
/// card must not offer an add button for.
 bool get inStock;/// How many are left, or NULL when the CMS row tracks no stock at
/// all — 13 of the 15 live products are untracked. Null therefore
/// means "no limit worth showing", NOT "none left"; that is
/// [inStock].
 int? get stock;/// The most one order may take: [stock] when it is tracked, and a
/// flat 100 when it is not. Asking for more is a 422 either way —
/// `errors.cart` names the piece and the number when stock is the
/// reason, `errors.quantity` when the 100 cap is.
 int get maxQuantity; String? get description;/// The gallery. Includes the cover [image] as its first entry, so
/// rendering both a hero and this list shows the cover twice —
/// drive the pager from [images] alone.
 List<ApiImage> get images;/// Selectable colourways as `#rrggbb` strings. The string is the
/// variant identifier the cart takes; empty means no choice.
 List<String> get colors;/// Height as a decimal string (`"8.00"`). A measurement, not a
/// choice and not money.
 String? get height;/// Width as a decimal string (`"6.00"`).
 String? get width;/// Length as a decimal string (`"6.00"`).
 String? get length;/// Parent category NAME (`"Cups"`) — no id travels with it.
 String? get category;/// Sub-category NAME (`"Abbasi Cups"`) — no id travels with it.
 String? get subCategory;/// The "you may also like" rail — plain list-shaped cards, so it
/// feeds the same widget the catalogue grid uses.
 List<Product> get relatedProducts;
/// Create a copy of ProductDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDetailCopyWith<ProductDetail> get copyWith => _$ProductDetailCopyWithImpl<ProductDetail>(this as ProductDetail, _$identity);

  /// Serializes this ProductDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.salePrice, salePrice) || other.salePrice == salePrice)&&(identical(other.image, image) || other.image == image)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isFavorited, isFavorited) || other.isFavorited == isFavorited)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.images, images)&&const DeepCollectionEquality().equals(other.colors, colors)&&(identical(other.height, height) || other.height == height)&&(identical(other.width, width) || other.width == width)&&(identical(other.length, length) || other.length == length)&&(identical(other.category, category) || other.category == category)&&(identical(other.subCategory, subCategory) || other.subCategory == subCategory)&&const DeepCollectionEquality().equals(other.relatedProducts, relatedProducts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,price,salePrice,image,isFeatured,isFavorited,inStock,stock,maxQuantity,description,const DeepCollectionEquality().hash(images),const DeepCollectionEquality().hash(colors),height,width,length,category,subCategory,const DeepCollectionEquality().hash(relatedProducts)]);

@override
String toString() {
  return 'ProductDetail(id: $id, title: $title, price: $price, salePrice: $salePrice, image: $image, isFeatured: $isFeatured, isFavorited: $isFavorited, inStock: $inStock, stock: $stock, maxQuantity: $maxQuantity, description: $description, images: $images, colors: $colors, height: $height, width: $width, length: $length, category: $category, subCategory: $subCategory, relatedProducts: $relatedProducts)';
}


}

/// @nodoc
abstract mixin class $ProductDetailCopyWith<$Res>  {
  factory $ProductDetailCopyWith(ProductDetail value, $Res Function(ProductDetail) _then) = _$ProductDetailCopyWithImpl;
@useResult
$Res call({
 int id, String title, String price, String? salePrice, ApiImage? image, bool isFeatured, bool isFavorited, bool inStock, int? stock, int maxQuantity, String? description, List<ApiImage> images, List<String> colors, String? height, String? width, String? length, String? category, String? subCategory, List<Product> relatedProducts
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$ProductDetailCopyWithImpl<$Res>
    implements $ProductDetailCopyWith<$Res> {
  _$ProductDetailCopyWithImpl(this._self, this._then);

  final ProductDetail _self;
  final $Res Function(ProductDetail) _then;

/// Create a copy of ProductDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? price = null,Object? salePrice = freezed,Object? image = freezed,Object? isFeatured = null,Object? isFavorited = null,Object? inStock = null,Object? stock = freezed,Object? maxQuantity = null,Object? description = freezed,Object? images = null,Object? colors = null,Object? height = freezed,Object? width = freezed,Object? length = freezed,Object? category = freezed,Object? subCategory = freezed,Object? relatedProducts = null,}) {
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
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as List<String>,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as String?,length: freezed == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subCategory: freezed == subCategory ? _self.subCategory : subCategory // ignore: cast_nullable_to_non_nullable
as String?,relatedProducts: null == relatedProducts ? _self.relatedProducts : relatedProducts // ignore: cast_nullable_to_non_nullable
as List<Product>,
  ));
}
/// Create a copy of ProductDetail
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


/// Adds pattern-matching-related methods to [ProductDetail].
extension ProductDetailPatterns on ProductDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductDetail value)  $default,){
final _that = this;
switch (_that) {
case _ProductDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ProductDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool inStock,  int? stock,  int maxQuantity,  String? description,  List<ApiImage> images,  List<String> colors,  String? height,  String? width,  String? length,  String? category,  String? subCategory,  List<Product> relatedProducts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductDetail() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.salePrice,_that.image,_that.isFeatured,_that.isFavorited,_that.inStock,_that.stock,_that.maxQuantity,_that.description,_that.images,_that.colors,_that.height,_that.width,_that.length,_that.category,_that.subCategory,_that.relatedProducts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool inStock,  int? stock,  int maxQuantity,  String? description,  List<ApiImage> images,  List<String> colors,  String? height,  String? width,  String? length,  String? category,  String? subCategory,  List<Product> relatedProducts)  $default,) {final _that = this;
switch (_that) {
case _ProductDetail():
return $default(_that.id,_that.title,_that.price,_that.salePrice,_that.image,_that.isFeatured,_that.isFavorited,_that.inStock,_that.stock,_that.maxQuantity,_that.description,_that.images,_that.colors,_that.height,_that.width,_that.length,_that.category,_that.subCategory,_that.relatedProducts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String price,  String? salePrice,  ApiImage? image,  bool isFeatured,  bool isFavorited,  bool inStock,  int? stock,  int maxQuantity,  String? description,  List<ApiImage> images,  List<String> colors,  String? height,  String? width,  String? length,  String? category,  String? subCategory,  List<Product> relatedProducts)?  $default,) {final _that = this;
switch (_that) {
case _ProductDetail() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.salePrice,_that.image,_that.isFeatured,_that.isFavorited,_that.inStock,_that.stock,_that.maxQuantity,_that.description,_that.images,_that.colors,_that.height,_that.width,_that.length,_that.category,_that.subCategory,_that.relatedProducts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductDetail extends ProductDetail {
  const _ProductDetail({required this.id, required this.title, required this.price, this.salePrice, this.image, required this.isFeatured, required this.isFavorited, required this.inStock, this.stock, required this.maxQuantity, this.description, final  List<ApiImage> images = const <ApiImage>[], final  List<String> colors = const <String>[], this.height, this.width, this.length, this.category, this.subCategory, final  List<Product> relatedProducts = const <Product>[]}): _images = images,_colors = colors,_relatedProducts = relatedProducts,super._();
  factory _ProductDetail.fromJson(Map<String, dynamic> json) => _$ProductDetailFromJson(json);

// ---- the `Product` half, sent verbatim ----
/// Product id.
@override final  int id;
/// Already-localized display name.
@override final  String title;
/// List price as a decimal string (`"45.00"`).
@override final  String price;
/// Offer price as a decimal string, or null when not on offer.
@override final  String? salePrice;
/// Primary/cover image. NULL on CMS rows with no image set — paint
/// via `image?.display`, never `image.url`.
@override final  ApiImage? image;
/// CMS-curated home-rail flag.
@override final  bool isFeatured;
/// Per-user favourite state at fetch time.
@override final  bool isFavorited;
// ---- detail-only additions ----
/// Long-form localized body copy. Plain text in the capture, not
/// HTML or Markdown.
/// Whether the studio has any of this to sell. False is a piece the
/// card must not offer an add button for.
@override final  bool inStock;
/// How many are left, or NULL when the CMS row tracks no stock at
/// all — 13 of the 15 live products are untracked. Null therefore
/// means "no limit worth showing", NOT "none left"; that is
/// [inStock].
@override final  int? stock;
/// The most one order may take: [stock] when it is tracked, and a
/// flat 100 when it is not. Asking for more is a 422 either way —
/// `errors.cart` names the piece and the number when stock is the
/// reason, `errors.quantity` when the 100 cap is.
@override final  int maxQuantity;
@override final  String? description;
/// The gallery. Includes the cover [image] as its first entry, so
/// rendering both a hero and this list shows the cover twice —
/// drive the pager from [images] alone.
 final  List<ApiImage> _images;
/// The gallery. Includes the cover [image] as its first entry, so
/// rendering both a hero and this list shows the cover twice —
/// drive the pager from [images] alone.
@override@JsonKey() List<ApiImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// Selectable colourways as `#rrggbb` strings. The string is the
/// variant identifier the cart takes; empty means no choice.
 final  List<String> _colors;
/// Selectable colourways as `#rrggbb` strings. The string is the
/// variant identifier the cart takes; empty means no choice.
@override@JsonKey() List<String> get colors {
  if (_colors is EqualUnmodifiableListView) return _colors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colors);
}

/// Height as a decimal string (`"8.00"`). A measurement, not a
/// choice and not money.
@override final  String? height;
/// Width as a decimal string (`"6.00"`).
@override final  String? width;
/// Length as a decimal string (`"6.00"`).
@override final  String? length;
/// Parent category NAME (`"Cups"`) — no id travels with it.
@override final  String? category;
/// Sub-category NAME (`"Abbasi Cups"`) — no id travels with it.
@override final  String? subCategory;
/// The "you may also like" rail — plain list-shaped cards, so it
/// feeds the same widget the catalogue grid uses.
 final  List<Product> _relatedProducts;
/// The "you may also like" rail — plain list-shaped cards, so it
/// feeds the same widget the catalogue grid uses.
@override@JsonKey() List<Product> get relatedProducts {
  if (_relatedProducts is EqualUnmodifiableListView) return _relatedProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedProducts);
}


/// Create a copy of ProductDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductDetailCopyWith<_ProductDetail> get copyWith => __$ProductDetailCopyWithImpl<_ProductDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.salePrice, salePrice) || other.salePrice == salePrice)&&(identical(other.image, image) || other.image == image)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isFavorited, isFavorited) || other.isFavorited == isFavorited)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.maxQuantity, maxQuantity) || other.maxQuantity == maxQuantity)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._images, _images)&&const DeepCollectionEquality().equals(other._colors, _colors)&&(identical(other.height, height) || other.height == height)&&(identical(other.width, width) || other.width == width)&&(identical(other.length, length) || other.length == length)&&(identical(other.category, category) || other.category == category)&&(identical(other.subCategory, subCategory) || other.subCategory == subCategory)&&const DeepCollectionEquality().equals(other._relatedProducts, _relatedProducts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,price,salePrice,image,isFeatured,isFavorited,inStock,stock,maxQuantity,description,const DeepCollectionEquality().hash(_images),const DeepCollectionEquality().hash(_colors),height,width,length,category,subCategory,const DeepCollectionEquality().hash(_relatedProducts)]);

@override
String toString() {
  return 'ProductDetail(id: $id, title: $title, price: $price, salePrice: $salePrice, image: $image, isFeatured: $isFeatured, isFavorited: $isFavorited, inStock: $inStock, stock: $stock, maxQuantity: $maxQuantity, description: $description, images: $images, colors: $colors, height: $height, width: $width, length: $length, category: $category, subCategory: $subCategory, relatedProducts: $relatedProducts)';
}


}

/// @nodoc
abstract mixin class _$ProductDetailCopyWith<$Res> implements $ProductDetailCopyWith<$Res> {
  factory _$ProductDetailCopyWith(_ProductDetail value, $Res Function(_ProductDetail) _then) = __$ProductDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String price, String? salePrice, ApiImage? image, bool isFeatured, bool isFavorited, bool inStock, int? stock, int maxQuantity, String? description, List<ApiImage> images, List<String> colors, String? height, String? width, String? length, String? category, String? subCategory, List<Product> relatedProducts
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$ProductDetailCopyWithImpl<$Res>
    implements _$ProductDetailCopyWith<$Res> {
  __$ProductDetailCopyWithImpl(this._self, this._then);

  final _ProductDetail _self;
  final $Res Function(_ProductDetail) _then;

/// Create a copy of ProductDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? price = null,Object? salePrice = freezed,Object? image = freezed,Object? isFeatured = null,Object? isFavorited = null,Object? inStock = null,Object? stock = freezed,Object? maxQuantity = null,Object? description = freezed,Object? images = null,Object? colors = null,Object? height = freezed,Object? width = freezed,Object? length = freezed,Object? category = freezed,Object? subCategory = freezed,Object? relatedProducts = null,}) {
  return _then(_ProductDetail(
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
as int,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,colors: null == colors ? _self._colors : colors // ignore: cast_nullable_to_non_nullable
as List<String>,height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,width: freezed == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as String?,length: freezed == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,subCategory: freezed == subCategory ? _self.subCategory : subCategory // ignore: cast_nullable_to_non_nullable
as String?,relatedProducts: null == relatedProducts ? _self._relatedProducts : relatedProducts // ignore: cast_nullable_to_non_nullable
as List<Product>,
  ));
}

/// Create a copy of ProductDetail
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
