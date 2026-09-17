// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_image.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiImage {

 int get id; String get url; String get type; String get blurhash; String? get imageApi;
/// Create a copy of ApiImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiImageCopyWith<ApiImage> get copyWith => _$ApiImageCopyWithImpl<ApiImage>(this as ApiImage, _$identity);

  /// Serializes this ApiImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.blurhash, blurhash) || other.blurhash == blurhash)&&(identical(other.imageApi, imageApi) || other.imageApi == imageApi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,type,blurhash,imageApi);

@override
String toString() {
  return 'ApiImage(id: $id, url: $url, type: $type, blurhash: $blurhash, imageApi: $imageApi)';
}


}

/// @nodoc
abstract mixin class $ApiImageCopyWith<$Res>  {
  factory $ApiImageCopyWith(ApiImage value, $Res Function(ApiImage) _then) = _$ApiImageCopyWithImpl;
@useResult
$Res call({
 int id, String url, String type, String blurhash, String? imageApi
});




}
/// @nodoc
class _$ApiImageCopyWithImpl<$Res>
    implements $ApiImageCopyWith<$Res> {
  _$ApiImageCopyWithImpl(this._self, this._then);

  final ApiImage _self;
  final $Res Function(ApiImage) _then;

/// Create a copy of ApiImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? type = null,Object? blurhash = null,Object? imageApi = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,blurhash: null == blurhash ? _self.blurhash : blurhash // ignore: cast_nullable_to_non_nullable
as String,imageApi: freezed == imageApi ? _self.imageApi : imageApi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiImage].
extension ApiImagePatterns on ApiImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiImage value)  $default,){
final _that = this;
switch (_that) {
case _ApiImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiImage value)?  $default,){
final _that = this;
switch (_that) {
case _ApiImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String url,  String type,  String blurhash,  String? imageApi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiImage() when $default != null:
return $default(_that.id,_that.url,_that.type,_that.blurhash,_that.imageApi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String url,  String type,  String blurhash,  String? imageApi)  $default,) {final _that = this;
switch (_that) {
case _ApiImage():
return $default(_that.id,_that.url,_that.type,_that.blurhash,_that.imageApi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String url,  String type,  String blurhash,  String? imageApi)?  $default,) {final _that = this;
switch (_that) {
case _ApiImage() when $default != null:
return $default(_that.id,_that.url,_that.type,_that.blurhash,_that.imageApi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApiImage extends ApiImage {
  const _ApiImage({required this.id, required this.url, required this.type, required this.blurhash, this.imageApi}): super._();
  factory _ApiImage.fromJson(Map<String, dynamic> json) => _$ApiImageFromJson(json);

@override final  int id;
@override final  String url;
@override final  String type;
@override final  String blurhash;
@override final  String? imageApi;

/// Create a copy of ApiImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiImageCopyWith<_ApiImage> get copyWith => __$ApiImageCopyWithImpl<_ApiImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApiImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.type, type) || other.type == type)&&(identical(other.blurhash, blurhash) || other.blurhash == blurhash)&&(identical(other.imageApi, imageApi) || other.imageApi == imageApi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,type,blurhash,imageApi);

@override
String toString() {
  return 'ApiImage(id: $id, url: $url, type: $type, blurhash: $blurhash, imageApi: $imageApi)';
}


}

/// @nodoc
abstract mixin class _$ApiImageCopyWith<$Res> implements $ApiImageCopyWith<$Res> {
  factory _$ApiImageCopyWith(_ApiImage value, $Res Function(_ApiImage) _then) = __$ApiImageCopyWithImpl;
@override @useResult
$Res call({
 int id, String url, String type, String blurhash, String? imageApi
});




}
/// @nodoc
class __$ApiImageCopyWithImpl<$Res>
    implements _$ApiImageCopyWith<$Res> {
  __$ApiImageCopyWithImpl(this._self, this._then);

  final _ApiImage _self;
  final $Res Function(_ApiImage) _then;

/// Create a copy of ApiImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? type = null,Object? blurhash = null,Object? imageApi = freezed,}) {
  return _then(_ApiImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,blurhash: null == blurhash ? _self.blurhash : blurhash // ignore: cast_nullable_to_non_nullable
as String,imageApi: freezed == imageApi ? _self.imageApi : imageApi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
