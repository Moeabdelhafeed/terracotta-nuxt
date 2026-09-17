// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workshop_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkshopCategory {

 int get id;/// Already-localized category name (`"Jars"`).
 String get title;/// Sub-groups holding the actual products. Defaults to empty so a
/// missing or null key cannot throw.
 List<WorkshopSubCategory> get subCategories;
/// Create a copy of WorkshopCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkshopCategoryCopyWith<WorkshopCategory> get copyWith => _$WorkshopCategoryCopyWithImpl<WorkshopCategory>(this as WorkshopCategory, _$identity);

  /// Serializes this WorkshopCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkshopCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.subCategories, subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(subCategories));

@override
String toString() {
  return 'WorkshopCategory(id: $id, title: $title, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class $WorkshopCategoryCopyWith<$Res>  {
  factory $WorkshopCategoryCopyWith(WorkshopCategory value, $Res Function(WorkshopCategory) _then) = _$WorkshopCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String title, List<WorkshopSubCategory> subCategories
});




}
/// @nodoc
class _$WorkshopCategoryCopyWithImpl<$Res>
    implements $WorkshopCategoryCopyWith<$Res> {
  _$WorkshopCategoryCopyWithImpl(this._self, this._then);

  final WorkshopCategory _self;
  final $Res Function(WorkshopCategory) _then;

/// Create a copy of WorkshopCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? subCategories = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subCategories: null == subCategories ? _self.subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<WorkshopSubCategory>,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkshopCategory].
extension WorkshopCategoryPatterns on WorkshopCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkshopCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkshopCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkshopCategory value)  $default,){
final _that = this;
switch (_that) {
case _WorkshopCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkshopCategory value)?  $default,){
final _that = this;
switch (_that) {
case _WorkshopCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  List<WorkshopSubCategory> subCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkshopCategory() when $default != null:
return $default(_that.id,_that.title,_that.subCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  List<WorkshopSubCategory> subCategories)  $default,) {final _that = this;
switch (_that) {
case _WorkshopCategory():
return $default(_that.id,_that.title,_that.subCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  List<WorkshopSubCategory> subCategories)?  $default,) {final _that = this;
switch (_that) {
case _WorkshopCategory() when $default != null:
return $default(_that.id,_that.title,_that.subCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkshopCategory implements WorkshopCategory {
  const _WorkshopCategory({required this.id, required this.title, final  List<WorkshopSubCategory> subCategories = const <WorkshopSubCategory>[]}): _subCategories = subCategories;
  factory _WorkshopCategory.fromJson(Map<String, dynamic> json) => _$WorkshopCategoryFromJson(json);

@override final  int id;
/// Already-localized category name (`"Jars"`).
@override final  String title;
/// Sub-groups holding the actual products. Defaults to empty so a
/// missing or null key cannot throw.
 final  List<WorkshopSubCategory> _subCategories;
/// Sub-groups holding the actual products. Defaults to empty so a
/// missing or null key cannot throw.
@override@JsonKey() List<WorkshopSubCategory> get subCategories {
  if (_subCategories is EqualUnmodifiableListView) return _subCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subCategories);
}


/// Create a copy of WorkshopCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkshopCategoryCopyWith<_WorkshopCategory> get copyWith => __$WorkshopCategoryCopyWithImpl<_WorkshopCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkshopCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkshopCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._subCategories, _subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_subCategories));

@override
String toString() {
  return 'WorkshopCategory(id: $id, title: $title, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class _$WorkshopCategoryCopyWith<$Res> implements $WorkshopCategoryCopyWith<$Res> {
  factory _$WorkshopCategoryCopyWith(_WorkshopCategory value, $Res Function(_WorkshopCategory) _then) = __$WorkshopCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, List<WorkshopSubCategory> subCategories
});




}
/// @nodoc
class __$WorkshopCategoryCopyWithImpl<$Res>
    implements _$WorkshopCategoryCopyWith<$Res> {
  __$WorkshopCategoryCopyWithImpl(this._self, this._then);

  final _WorkshopCategory _self;
  final $Res Function(_WorkshopCategory) _then;

/// Create a copy of WorkshopCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? subCategories = null,}) {
  return _then(_WorkshopCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subCategories: null == subCategories ? _self._subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<WorkshopSubCategory>,
  ));
}


}

// dart format on
