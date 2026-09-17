// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_sub_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShopSubCategory {

/// Sub-category id — the filter value for the product listing.
 int get id;/// Already-localized display name (`"Abbasi Cups"`).
 String get title;
/// Create a copy of ShopSubCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopSubCategoryCopyWith<ShopSubCategory> get copyWith => _$ShopSubCategoryCopyWithImpl<ShopSubCategory>(this as ShopSubCategory, _$identity);

  /// Serializes this ShopSubCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopSubCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'ShopSubCategory(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class $ShopSubCategoryCopyWith<$Res>  {
  factory $ShopSubCategoryCopyWith(ShopSubCategory value, $Res Function(ShopSubCategory) _then) = _$ShopSubCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String title
});




}
/// @nodoc
class _$ShopSubCategoryCopyWithImpl<$Res>
    implements $ShopSubCategoryCopyWith<$Res> {
  _$ShopSubCategoryCopyWithImpl(this._self, this._then);

  final ShopSubCategory _self;
  final $Res Function(ShopSubCategory) _then;

/// Create a copy of ShopSubCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopSubCategory].
extension ShopSubCategoryPatterns on ShopSubCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopSubCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopSubCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopSubCategory value)  $default,){
final _that = this;
switch (_that) {
case _ShopSubCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopSubCategory value)?  $default,){
final _that = this;
switch (_that) {
case _ShopSubCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopSubCategory() when $default != null:
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title)  $default,) {final _that = this;
switch (_that) {
case _ShopSubCategory():
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title)?  $default,) {final _that = this;
switch (_that) {
case _ShopSubCategory() when $default != null:
return $default(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShopSubCategory implements ShopSubCategory {
  const _ShopSubCategory({required this.id, required this.title});
  factory _ShopSubCategory.fromJson(Map<String, dynamic> json) => _$ShopSubCategoryFromJson(json);

/// Sub-category id — the filter value for the product listing.
@override final  int id;
/// Already-localized display name (`"Abbasi Cups"`).
@override final  String title;

/// Create a copy of ShopSubCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopSubCategoryCopyWith<_ShopSubCategory> get copyWith => __$ShopSubCategoryCopyWithImpl<_ShopSubCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShopSubCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopSubCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'ShopSubCategory(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$ShopSubCategoryCopyWith<$Res> implements $ShopSubCategoryCopyWith<$Res> {
  factory _$ShopSubCategoryCopyWith(_ShopSubCategory value, $Res Function(_ShopSubCategory) _then) = __$ShopSubCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String title
});




}
/// @nodoc
class __$ShopSubCategoryCopyWithImpl<$Res>
    implements _$ShopSubCategoryCopyWith<$Res> {
  __$ShopSubCategoryCopyWithImpl(this._self, this._then);

  final _ShopSubCategory _self;
  final $Res Function(_ShopSubCategory) _then;

/// Create a copy of ShopSubCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_ShopSubCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
