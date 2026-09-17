// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopCategory {

/// Category id — the filter value for the product listing.
 int get id;/// Already-localized display name (`"Incense Burners"`).
 String get title;/// Category chip artwork. Sent ONLY by the shop-home payload; the
/// categories endpoint omits the key entirely.
 ApiImage? get image;/// Children. Sent ONLY by `GET /api/shop/categories`; empty here
/// means "this response did not carry them", not "none exist".
 List<ShopSubCategory> get subCategories;
/// Create a copy of ShopCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopCategoryCopyWith<ShopCategory> get copyWith => _$ShopCategoryCopyWithImpl<ShopCategory>(this as ShopCategory, _$identity);

  /// Serializes this ShopCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image)&&const DeepCollectionEquality().equals(other.subCategories, subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image,const DeepCollectionEquality().hash(subCategories));

@override
String toString() {
  return 'ShopCategory(id: $id, title: $title, image: $image, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class $ShopCategoryCopyWith<$Res>  {
  factory $ShopCategoryCopyWith(ShopCategory value, $Res Function(ShopCategory) _then) = _$ShopCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String title, ApiImage? image, List<ShopSubCategory> subCategories
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$ShopCategoryCopyWithImpl<$Res>
    implements $ShopCategoryCopyWith<$Res> {
  _$ShopCategoryCopyWithImpl(this._self, this._then);

  final ShopCategory _self;
  final $Res Function(ShopCategory) _then;

/// Create a copy of ShopCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? image = freezed,Object? subCategories = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,subCategories: null == subCategories ? _self.subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<ShopSubCategory>,
  ));
}
/// Create a copy of ShopCategory
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


/// Adds pattern-matching-related methods to [ShopCategory].
extension ShopCategoryPatterns on ShopCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopCategory value)  $default,){
final _that = this;
switch (_that) {
case _ShopCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopCategory value)?  $default,){
final _that = this;
switch (_that) {
case _ShopCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  ApiImage? image,  List<ShopSubCategory> subCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopCategory() when $default != null:
return $default(_that.id,_that.title,_that.image,_that.subCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  ApiImage? image,  List<ShopSubCategory> subCategories)  $default,) {final _that = this;
switch (_that) {
case _ShopCategory():
return $default(_that.id,_that.title,_that.image,_that.subCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  ApiImage? image,  List<ShopSubCategory> subCategories)?  $default,) {final _that = this;
switch (_that) {
case _ShopCategory() when $default != null:
return $default(_that.id,_that.title,_that.image,_that.subCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShopCategory implements ShopCategory {
  const _ShopCategory({required this.id, required this.title, this.image, final  List<ShopSubCategory> subCategories = const <ShopSubCategory>[]}): _subCategories = subCategories;
  factory _ShopCategory.fromJson(Map<String, dynamic> json) => _$ShopCategoryFromJson(json);

/// Category id — the filter value for the product listing.
@override final  int id;
/// Already-localized display name (`"Incense Burners"`).
@override final  String title;
/// Category chip artwork. Sent ONLY by the shop-home payload; the
/// categories endpoint omits the key entirely.
@override final  ApiImage? image;
/// Children. Sent ONLY by `GET /api/shop/categories`; empty here
/// means "this response did not carry them", not "none exist".
 final  List<ShopSubCategory> _subCategories;
/// Children. Sent ONLY by `GET /api/shop/categories`; empty here
/// means "this response did not carry them", not "none exist".
@override@JsonKey() List<ShopSubCategory> get subCategories {
  if (_subCategories is EqualUnmodifiableListView) return _subCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subCategories);
}


/// Create a copy of ShopCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopCategoryCopyWith<_ShopCategory> get copyWith => __$ShopCategoryCopyWithImpl<_ShopCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.image, image) || other.image == image)&&const DeepCollectionEquality().equals(other._subCategories, _subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,image,const DeepCollectionEquality().hash(_subCategories));

@override
String toString() {
  return 'ShopCategory(id: $id, title: $title, image: $image, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class _$ShopCategoryCopyWith<$Res> implements $ShopCategoryCopyWith<$Res> {
  factory _$ShopCategoryCopyWith(_ShopCategory value, $Res Function(_ShopCategory) _then) = __$ShopCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, ApiImage? image, List<ShopSubCategory> subCategories
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$ShopCategoryCopyWithImpl<$Res>
    implements _$ShopCategoryCopyWith<$Res> {
  __$ShopCategoryCopyWithImpl(this._self, this._then);

  final _ShopCategory _self;
  final $Res Function(_ShopCategory) _then;

/// Create a copy of ShopCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? image = freezed,Object? subCategories = null,}) {
  return _then(_ShopCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,subCategories: null == subCategories ? _self._subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<ShopSubCategory>,
  ));
}

/// Create a copy of ShopCategory
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
