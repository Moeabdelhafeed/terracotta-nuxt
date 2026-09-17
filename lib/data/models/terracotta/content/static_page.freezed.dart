// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'static_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StaticPage {

/// CMS row key. Home banners reference pages by this via
/// `link_target_id`.
 int get id;/// URL key — `"terms"`, `"privacy"`. The routing identity.
 String get slug;/// Display title, already localized by the CMS.
 String get name;/// **HTML body.** Never render with `Text`.
 String get content;/// Header illustration. **Null for every captured page.**
 ApiImage? get image;
/// Create a copy of StaticPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StaticPageCopyWith<StaticPage> get copyWith => _$StaticPageCopyWithImpl<StaticPage>(this as StaticPage, _$identity);

  /// Serializes this StaticPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StaticPage&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,content,image);

@override
String toString() {
  return 'StaticPage(id: $id, slug: $slug, name: $name, content: $content, image: $image)';
}


}

/// @nodoc
abstract mixin class $StaticPageCopyWith<$Res>  {
  factory $StaticPageCopyWith(StaticPage value, $Res Function(StaticPage) _then) = _$StaticPageCopyWithImpl;
@useResult
$Res call({
 int id, String slug, String name, String content, ApiImage? image
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$StaticPageCopyWithImpl<$Res>
    implements $StaticPageCopyWith<$Res> {
  _$StaticPageCopyWithImpl(this._self, this._then);

  final StaticPage _self;
  final $Res Function(StaticPage) _then;

/// Create a copy of StaticPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? content = null,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}
/// Create a copy of StaticPage
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


/// Adds pattern-matching-related methods to [StaticPage].
extension StaticPagePatterns on StaticPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StaticPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StaticPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StaticPage value)  $default,){
final _that = this;
switch (_that) {
case _StaticPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StaticPage value)?  $default,){
final _that = this;
switch (_that) {
case _StaticPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String slug,  String name,  String content,  ApiImage? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StaticPage() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.content,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String slug,  String name,  String content,  ApiImage? image)  $default,) {final _that = this;
switch (_that) {
case _StaticPage():
return $default(_that.id,_that.slug,_that.name,_that.content,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String slug,  String name,  String content,  ApiImage? image)?  $default,) {final _that = this;
switch (_that) {
case _StaticPage() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.content,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StaticPage implements StaticPage {
  const _StaticPage({required this.id, required this.slug, required this.name, required this.content, this.image});
  factory _StaticPage.fromJson(Map<String, dynamic> json) => _$StaticPageFromJson(json);

/// CMS row key. Home banners reference pages by this via
/// `link_target_id`.
@override final  int id;
/// URL key — `"terms"`, `"privacy"`. The routing identity.
@override final  String slug;
/// Display title, already localized by the CMS.
@override final  String name;
/// **HTML body.** Never render with `Text`.
@override final  String content;
/// Header illustration. **Null for every captured page.**
@override final  ApiImage? image;

/// Create a copy of StaticPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StaticPageCopyWith<_StaticPage> get copyWith => __$StaticPageCopyWithImpl<_StaticPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StaticPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StaticPage&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,content,image);

@override
String toString() {
  return 'StaticPage(id: $id, slug: $slug, name: $name, content: $content, image: $image)';
}


}

/// @nodoc
abstract mixin class _$StaticPageCopyWith<$Res> implements $StaticPageCopyWith<$Res> {
  factory _$StaticPageCopyWith(_StaticPage value, $Res Function(_StaticPage) _then) = __$StaticPageCopyWithImpl;
@override @useResult
$Res call({
 int id, String slug, String name, String content, ApiImage? image
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$StaticPageCopyWithImpl<$Res>
    implements _$StaticPageCopyWith<$Res> {
  __$StaticPageCopyWithImpl(this._self, this._then);

  final _StaticPage _self;
  final $Res Function(_StaticPage) _then;

/// Create a copy of StaticPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? content = null,Object? image = freezed,}) {
  return _then(_StaticPage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}

/// Create a copy of StaticPage
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
