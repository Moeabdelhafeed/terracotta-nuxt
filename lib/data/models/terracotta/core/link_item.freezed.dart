// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'link_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LinkItem {

 int get id; String get text; String get url; ApiImage get image;
/// Create a copy of LinkItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkItemCopyWith<LinkItem> get copyWith => _$LinkItemCopyWithImpl<LinkItem>(this as LinkItem, _$identity);

  /// Serializes this LinkItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkItem&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.url, url) || other.url == url)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,url,image);

@override
String toString() {
  return 'LinkItem(id: $id, text: $text, url: $url, image: $image)';
}


}

/// @nodoc
abstract mixin class $LinkItemCopyWith<$Res>  {
  factory $LinkItemCopyWith(LinkItem value, $Res Function(LinkItem) _then) = _$LinkItemCopyWithImpl;
@useResult
$Res call({
 int id, String text, String url, ApiImage image
});


$ApiImageCopyWith<$Res> get image;

}
/// @nodoc
class _$LinkItemCopyWithImpl<$Res>
    implements $LinkItemCopyWith<$Res> {
  _$LinkItemCopyWithImpl(this._self, this._then);

  final LinkItem _self;
  final $Res Function(LinkItem) _then;

/// Create a copy of LinkItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? text = null,Object? url = null,Object? image = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage,
  ));
}
/// Create a copy of LinkItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res> get image {
  
  return $ApiImageCopyWith<$Res>(_self.image, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}


/// Adds pattern-matching-related methods to [LinkItem].
extension LinkItemPatterns on LinkItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkItem value)  $default,){
final _that = this;
switch (_that) {
case _LinkItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkItem value)?  $default,){
final _that = this;
switch (_that) {
case _LinkItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String text,  String url,  ApiImage image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkItem() when $default != null:
return $default(_that.id,_that.text,_that.url,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String text,  String url,  ApiImage image)  $default,) {final _that = this;
switch (_that) {
case _LinkItem():
return $default(_that.id,_that.text,_that.url,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String text,  String url,  ApiImage image)?  $default,) {final _that = this;
switch (_that) {
case _LinkItem() when $default != null:
return $default(_that.id,_that.text,_that.url,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkItem implements LinkItem {
  const _LinkItem({required this.id, required this.text, required this.url, required this.image});
  factory _LinkItem.fromJson(Map<String, dynamic> json) => _$LinkItemFromJson(json);

@override final  int id;
@override final  String text;
@override final  String url;
@override final  ApiImage image;

/// Create a copy of LinkItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkItemCopyWith<_LinkItem> get copyWith => __$LinkItemCopyWithImpl<_LinkItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkItem&&(identical(other.id, id) || other.id == id)&&(identical(other.text, text) || other.text == text)&&(identical(other.url, url) || other.url == url)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,text,url,image);

@override
String toString() {
  return 'LinkItem(id: $id, text: $text, url: $url, image: $image)';
}


}

/// @nodoc
abstract mixin class _$LinkItemCopyWith<$Res> implements $LinkItemCopyWith<$Res> {
  factory _$LinkItemCopyWith(_LinkItem value, $Res Function(_LinkItem) _then) = __$LinkItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String text, String url, ApiImage image
});


@override $ApiImageCopyWith<$Res> get image;

}
/// @nodoc
class __$LinkItemCopyWithImpl<$Res>
    implements _$LinkItemCopyWith<$Res> {
  __$LinkItemCopyWithImpl(this._self, this._then);

  final _LinkItem _self;
  final $Res Function(_LinkItem) _then;

/// Create a copy of LinkItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? text = null,Object? url = null,Object? image = null,}) {
  return _then(_LinkItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage,
  ));
}

/// Create a copy of LinkItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res> get image {
  
  return $ApiImageCopyWith<$Res>(_self.image, (value) {
    return _then(_self.copyWith(image: value));
  });
}
}

// dart format on
