// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkshopProduct {

/// The catalog id. Echoed as `workshop_product_id` on bookings.
 int get id;/// Already-localized product name (`"Lavender Jar"`).
///
/// NULLABLE — verified live on 2026-09-07, where the first real
/// catalogue row on dev came back `"title": null`. Declared
/// required it threw inside `fromJson` and took the WHOLE workshop
/// detail with it: the catalogue screen showed its failure state
/// for a workshop whose products were all there. The CMS lets an
/// admin save a product with no name in the requested locale, so
/// this is a state the app has to draw, not one to assert away.
 String? get title;/// Per-unit price as a decimal string. Additive to the seat price.
 String get price;/// Secondary line. Null on every captured product.
 String? get subtitle;/// Product photos. Empty on every captured product; defaults to an
/// empty list so a missing or null key cannot throw.
 List<ApiImage> get images;
/// Create a copy of WorkshopProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopProductCopyWith<WorkshopProduct> get copyWith => _$WorkshopProductCopyWithImpl<WorkshopProduct>(this as WorkshopProduct, _$identity);

  /// Serializes this WorkshopProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,subtitle,const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'WorkshopProduct(id: $id, title: $title, price: $price, subtitle: $subtitle, images: $images)';
}


}

/// @nodoc
abstract mixin class $WorkshopProductCopyWith<$Res>  {
  factory $WorkshopProductCopyWith(WorkshopProduct value, $Res Function(WorkshopProduct) _then) = _$WorkshopProductCopyWithImpl;
@useResult
$Res call({
 int id, String? title, String price, String? subtitle, List<ApiImage> images
});




}
/// @nodoc
class _$WorkshopProductCopyWithImpl<$Res>
    implements $WorkshopProductCopyWith<$Res> {
  _$WorkshopProductCopyWithImpl(this._self, this._then);

  final WorkshopProduct _self;
  final $Res Function(WorkshopProduct) _then;

/// Create a copy of WorkshopProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? price = null,Object? subtitle = freezed,Object? images = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkshopProduct].
extension WorkshopProductPatterns on WorkshopProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopProduct value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopProduct value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? title,  String price,  String? subtitle,  List<ApiImage> images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.subtitle,_that.images);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? title,  String price,  String? subtitle,  List<ApiImage> images)  $default,) {final _that = this;
switch (_that) {
case _WorkshopProduct():
return $default(_that.id,_that.title,_that.price,_that.subtitle,_that.images);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? title,  String price,  String? subtitle,  List<ApiImage> images)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopProduct() when $default != null:
return $default(_that.id,_that.title,_that.price,_that.subtitle,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkshopProduct extends WorkshopProduct {
  const _WorkshopProduct({required this.id, this.title, required this.price, this.subtitle, final  List<ApiImage> images = const <ApiImage>[]}): _images = images,super._();
  factory _WorkshopProduct.fromJson(Map<String, dynamic> json) => _$WorkshopProductFromJson(json);

/// The catalog id. Echoed as `workshop_product_id` on bookings.
@override final  int id;
/// Already-localized product name (`"Lavender Jar"`).
///
/// NULLABLE — verified live on 2026-09-07, where the first real
/// catalogue row on dev came back `"title": null`. Declared
/// required it threw inside `fromJson` and took the WHOLE workshop
/// detail with it: the catalogue screen showed its failure state
/// for a workshop whose products were all there. The CMS lets an
/// admin save a product with no name in the requested locale, so
/// this is a state the app has to draw, not one to assert away.
@override final  String? title;
/// Per-unit price as a decimal string. Additive to the seat price.
@override final  String price;
/// Secondary line. Null on every captured product.
@override final  String? subtitle;
/// Product photos. Empty on every captured product; defaults to an
/// empty list so a missing or null key cannot throw.
 final  List<ApiImage> _images;
/// Product photos. Empty on every captured product; defaults to an
/// empty list so a missing or null key cannot throw.
@override@JsonKey() List<ApiImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}


/// Create a copy of WorkshopProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopProductCopyWith<_WorkshopProduct> get copyWith => __$WorkshopProductCopyWithImpl<_WorkshopProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.price, price) || other.price == price)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&const DeepCollectionEquality().equals(other._images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,price,subtitle,const DeepCollectionEquality().hash(_images));

@override
String toString() {
  return 'WorkshopProduct(id: $id, title: $title, price: $price, subtitle: $subtitle, images: $images)';
}


}

/// @nodoc
abstract mixin class _$WorkshopProductCopyWith<$Res> implements $WorkshopProductCopyWith<$Res> {
  factory _$WorkshopProductCopyWith(_WorkshopProduct value, $Res Function(_WorkshopProduct) _then) = __$WorkshopProductCopyWithImpl;
@override @useResult
$Res call({
 int id, String? title, String price, String? subtitle, List<ApiImage> images
});




}
/// @nodoc
class __$WorkshopProductCopyWithImpl<$Res>
    implements _$WorkshopProductCopyWith<$Res> {
  __$WorkshopProductCopyWithImpl(this._self, this._then);

  final _WorkshopProduct _self;
  final $Res Function(_WorkshopProduct) _then;

/// Create a copy of WorkshopProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? price = null,Object? subtitle = freezed,Object? images = null,}) {
  return _then(_WorkshopProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ApiImage>,
  ));
}


}

// dart format on
