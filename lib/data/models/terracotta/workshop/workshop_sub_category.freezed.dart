// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop_sub_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkshopSubCategory {

 int get id;/// Already-localized group name (`"Scented Jars"`).
 String get title;/// The pickable items. Defaults to empty so a missing or null key
/// cannot throw.
 List<WorkshopProduct> get products;
/// Create a copy of WorkshopSubCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopSubCategoryCopyWith<WorkshopSubCategory> get copyWith => _$WorkshopSubCategoryCopyWithImpl<WorkshopSubCategory>(this as WorkshopSubCategory, _$identity);

  /// Serializes this WorkshopSubCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopSubCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.products, products));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(products));

@override
String toString() {
  return 'WorkshopSubCategory(id: $id, title: $title, products: $products)';
}


}

/// @nodoc
abstract mixin class $WorkshopSubCategoryCopyWith<$Res>  {
  factory $WorkshopSubCategoryCopyWith(WorkshopSubCategory value, $Res Function(WorkshopSubCategory) _then) = _$WorkshopSubCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String title, List<WorkshopProduct> products
});




}
/// @nodoc
class _$WorkshopSubCategoryCopyWithImpl<$Res>
    implements $WorkshopSubCategoryCopyWith<$Res> {
  _$WorkshopSubCategoryCopyWithImpl(this._self, this._then);

  final WorkshopSubCategory _self;
  final $Res Function(WorkshopSubCategory) _then;

/// Create a copy of WorkshopSubCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? products = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,products: null == products ? _self.products : products // ignore: cast_nullable_to_non_nullable
as List<WorkshopProduct>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkshopSubCategory].
extension WorkshopSubCategoryPatterns on WorkshopSubCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopSubCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopSubCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopSubCategory value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopSubCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopSubCategory value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopSubCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  List<WorkshopProduct> products)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopSubCategory() when $default != null:
return $default(_that.id,_that.title,_that.products);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  List<WorkshopProduct> products)  $default,) {final _that = this;
switch (_that) {
case _WorkshopSubCategory():
return $default(_that.id,_that.title,_that.products);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  List<WorkshopProduct> products)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopSubCategory() when $default != null:
return $default(_that.id,_that.title,_that.products);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkshopSubCategory implements WorkshopSubCategory {
  const _WorkshopSubCategory({required this.id, required this.title, final  List<WorkshopProduct> products = const <WorkshopProduct>[]}): _products = products;
  factory _WorkshopSubCategory.fromJson(Map<String, dynamic> json) => _$WorkshopSubCategoryFromJson(json);

@override final  int id;
/// Already-localized group name (`"Scented Jars"`).
@override final  String title;
/// The pickable items. Defaults to empty so a missing or null key
/// cannot throw.
 final  List<WorkshopProduct> _products;
/// The pickable items. Defaults to empty so a missing or null key
/// cannot throw.
@override@JsonKey() List<WorkshopProduct> get products {
  if (_products is EqualUnmodifiableListView) return _products;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_products);
}


/// Create a copy of WorkshopSubCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopSubCategoryCopyWith<_WorkshopSubCategory> get copyWith => __$WorkshopSubCategoryCopyWithImpl<_WorkshopSubCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopSubCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopSubCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._products, _products));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_products));

@override
String toString() {
  return 'WorkshopSubCategory(id: $id, title: $title, products: $products)';
}


}

/// @nodoc
abstract mixin class _$WorkshopSubCategoryCopyWith<$Res> implements $WorkshopSubCategoryCopyWith<$Res> {
  factory _$WorkshopSubCategoryCopyWith(_WorkshopSubCategory value, $Res Function(_WorkshopSubCategory) _then) = __$WorkshopSubCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, List<WorkshopProduct> products
});




}
/// @nodoc
class __$WorkshopSubCategoryCopyWithImpl<$Res>
    implements _$WorkshopSubCategoryCopyWith<$Res> {
  __$WorkshopSubCategoryCopyWithImpl(this._self, this._then);

  final _WorkshopSubCategory _self;
  final $Res Function(_WorkshopSubCategory) _then;

/// Create a copy of WorkshopSubCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? products = null,}) {
  return _then(_WorkshopSubCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,products: null == products ? _self._products : products // ignore: cast_nullable_to_non_nullable
as List<WorkshopProduct>,
  ));
}


}

// dart format on
