// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_home.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopHome {

/// Category chips. Carry `image`, never `sub_categories`.
 List<ShopCategory> get categories;/// The CMS-flagged rail (`is_featured: true`).
 List<Product> get featuredProducts;/// Every product currently carrying a `sale_price`. May share
/// members with [featuredProducts].
 List<Product> get offers;
/// Create a copy of ShopHome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopHomeCopyWith<ShopHome> get copyWith => _$ShopHomeCopyWithImpl<ShopHome>(this as ShopHome, _$identity);

  /// Serializes this ShopHome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopHome&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.featuredProducts, featuredProducts)&&const DeepCollectionEquality().equals(other.offers, offers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(featuredProducts),const DeepCollectionEquality().hash(offers));

@override
String toString() {
  return 'ShopHome(categories: $categories, featuredProducts: $featuredProducts, offers: $offers)';
}


}

/// @nodoc
abstract mixin class $ShopHomeCopyWith<$Res>  {
  factory $ShopHomeCopyWith(ShopHome value, $Res Function(ShopHome) _then) = _$ShopHomeCopyWithImpl;
@useResult
$Res call({
 List<ShopCategory> categories, List<Product> featuredProducts, List<Product> offers
});




}
/// @nodoc
class _$ShopHomeCopyWithImpl<$Res>
    implements $ShopHomeCopyWith<$Res> {
  _$ShopHomeCopyWithImpl(this._self, this._then);

  final ShopHome _self;
  final $Res Function(ShopHome) _then;

/// Create a copy of ShopHome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,Object? featuredProducts = null,Object? offers = null,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<ShopCategory>,featuredProducts: null == featuredProducts ? _self.featuredProducts : featuredProducts // ignore: cast_nullable_to_non_nullable
as List<Product>,offers: null == offers ? _self.offers : offers // ignore: cast_nullable_to_non_nullable
as List<Product>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopHome].
extension ShopHomePatterns on ShopHome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopHome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopHome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopHome value)  $default,){
final _that = this;
switch (_that) {
case _ShopHome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopHome value)?  $default,){
final _that = this;
switch (_that) {
case _ShopHome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ShopCategory> categories,  List<Product> featuredProducts,  List<Product> offers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopHome() when $default != null:
return $default(_that.categories,_that.featuredProducts,_that.offers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ShopCategory> categories,  List<Product> featuredProducts,  List<Product> offers)  $default,) {final _that = this;
switch (_that) {
case _ShopHome():
return $default(_that.categories,_that.featuredProducts,_that.offers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ShopCategory> categories,  List<Product> featuredProducts,  List<Product> offers)?  $default,) {final _that = this;
switch (_that) {
case _ShopHome() when $default != null:
return $default(_that.categories,_that.featuredProducts,_that.offers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShopHome implements ShopHome {
  const _ShopHome({final  List<ShopCategory> categories = const <ShopCategory>[], final  List<Product> featuredProducts = const <Product>[], final  List<Product> offers = const <Product>[]}): _categories = categories,_featuredProducts = featuredProducts,_offers = offers;
  factory _ShopHome.fromJson(Map<String, dynamic> json) => _$ShopHomeFromJson(json);

/// Category chips. Carry `image`, never `sub_categories`.
 final  List<ShopCategory> _categories;
/// Category chips. Carry `image`, never `sub_categories`.
@override@JsonKey() List<ShopCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

/// The CMS-flagged rail (`is_featured: true`).
 final  List<Product> _featuredProducts;
/// The CMS-flagged rail (`is_featured: true`).
@override@JsonKey() List<Product> get featuredProducts {
  if (_featuredProducts is EqualUnmodifiableListView) return _featuredProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_featuredProducts);
}

/// Every product currently carrying a `sale_price`. May share
/// members with [featuredProducts].
 final  List<Product> _offers;
/// Every product currently carrying a `sale_price`. May share
/// members with [featuredProducts].
@override@JsonKey() List<Product> get offers {
  if (_offers is EqualUnmodifiableListView) return _offers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_offers);
}


/// Create a copy of ShopHome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopHomeCopyWith<_ShopHome> get copyWith => __$ShopHomeCopyWithImpl<_ShopHome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopHomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopHome&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._featuredProducts, _featuredProducts)&&const DeepCollectionEquality().equals(other._offers, _offers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_featuredProducts),const DeepCollectionEquality().hash(_offers));

@override
String toString() {
  return 'ShopHome(categories: $categories, featuredProducts: $featuredProducts, offers: $offers)';
}


}

/// @nodoc
abstract mixin class _$ShopHomeCopyWith<$Res> implements $ShopHomeCopyWith<$Res> {
  factory _$ShopHomeCopyWith(_ShopHome value, $Res Function(_ShopHome) _then) = __$ShopHomeCopyWithImpl;
@override @useResult
$Res call({
 List<ShopCategory> categories, List<Product> featuredProducts, List<Product> offers
});




}
/// @nodoc
class __$ShopHomeCopyWithImpl<$Res>
    implements _$ShopHomeCopyWith<$Res> {
  __$ShopHomeCopyWithImpl(this._self, this._then);

  final _ShopHome _self;
  final $Res Function(_ShopHome) _then;

/// Create a copy of ShopHome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? featuredProducts = null,Object? offers = null,}) {
  return _then(_ShopHome(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<ShopCategory>,featuredProducts: null == featuredProducts ? _self._featuredProducts : featuredProducts // ignore: cast_nullable_to_non_nullable
as List<Product>,offers: null == offers ? _self._offers : offers // ignore: cast_nullable_to_non_nullable
as List<Product>,
  ));
}


}

// dart format on
