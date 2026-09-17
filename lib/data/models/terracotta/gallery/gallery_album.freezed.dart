// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_album.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GalleryAlbum {

/// Album id — the path segment for `GET /api/gallery/{id}`.
 int get id;/// Already-localized album name for the requested locale. Display
/// as-is; do not look it up in the ARB.
 String get title;/// Grid thumbnail. In the capture it is the album's first image.
 ApiImage get cover;/// How many still images the album holds.
 int get imagesCount;/// How many videos the album holds. `0` throughout the capture.
 int get videosCount;
/// Create a copy of GalleryAlbum
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryAlbumCopyWith<GalleryAlbum> get copyWith => _$GalleryAlbumCopyWithImpl<GalleryAlbum>(this as GalleryAlbum, _$identity);

  /// Serializes this GalleryAlbum to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryAlbum&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.imagesCount, imagesCount) || other.imagesCount == imagesCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,cover,imagesCount,videosCount);

@override
String toString() {
  return 'GalleryAlbum(id: $id, title: $title, cover: $cover, imagesCount: $imagesCount, videosCount: $videosCount)';
}


}

/// @nodoc
abstract mixin class $GalleryAlbumCopyWith<$Res>  {
  factory $GalleryAlbumCopyWith(GalleryAlbum value, $Res Function(GalleryAlbum) _then) = _$GalleryAlbumCopyWithImpl;
@useResult
$Res call({
 int id, String title, ApiImage cover, int imagesCount, int videosCount
});


$ApiImageCopyWith<$Res> get cover;

}
/// @nodoc
class _$GalleryAlbumCopyWithImpl<$Res>
    implements $GalleryAlbumCopyWith<$Res> {
  _$GalleryAlbumCopyWithImpl(this._self, this._then);

  final GalleryAlbum _self;
  final $Res Function(GalleryAlbum) _then;

/// Create a copy of GalleryAlbum
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? cover = null,Object? imagesCount = null,Object? videosCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ApiImage,imagesCount: null == imagesCount ? _self.imagesCount : imagesCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of GalleryAlbum
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res> get cover {
  
  return $ApiImageCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// Adds pattern-matching-related methods to [GalleryAlbum].
extension GalleryAlbumPatterns on GalleryAlbum {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GalleryAlbum value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GalleryAlbum() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GalleryAlbum value)  $default,){
final _that = this;
switch (_that) {
case _GalleryAlbum():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GalleryAlbum value)?  $default,){
final _that = this;
switch (_that) {
case _GalleryAlbum() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  ApiImage cover,  int imagesCount,  int videosCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GalleryAlbum() when $default != null:
return $default(_that.id,_that.title,_that.cover,_that.imagesCount,_that.videosCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  ApiImage cover,  int imagesCount,  int videosCount)  $default,) {final _that = this;
switch (_that) {
case _GalleryAlbum():
return $default(_that.id,_that.title,_that.cover,_that.imagesCount,_that.videosCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  ApiImage cover,  int imagesCount,  int videosCount)?  $default,) {final _that = this;
switch (_that) {
case _GalleryAlbum() when $default != null:
return $default(_that.id,_that.title,_that.cover,_that.imagesCount,_that.videosCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GalleryAlbum extends GalleryAlbum {
  const _GalleryAlbum({required this.id, required this.title, required this.cover, required this.imagesCount, required this.videosCount}): super._();
  factory _GalleryAlbum.fromJson(Map<String, dynamic> json) => _$GalleryAlbumFromJson(json);

/// Album id — the path segment for `GET /api/gallery/{id}`.
@override final  int id;
/// Already-localized album name for the requested locale. Display
/// as-is; do not look it up in the ARB.
@override final  String title;
/// Grid thumbnail. In the capture it is the album's first image.
@override final  ApiImage cover;
/// How many still images the album holds.
@override final  int imagesCount;
/// How many videos the album holds. `0` throughout the capture.
@override final  int videosCount;

/// Create a copy of GalleryAlbum
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GalleryAlbumCopyWith<_GalleryAlbum> get copyWith => __$GalleryAlbumCopyWithImpl<_GalleryAlbum>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GalleryAlbumToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GalleryAlbum&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.imagesCount, imagesCount) || other.imagesCount == imagesCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,cover,imagesCount,videosCount);

@override
String toString() {
  return 'GalleryAlbum(id: $id, title: $title, cover: $cover, imagesCount: $imagesCount, videosCount: $videosCount)';
}


}

/// @nodoc
abstract mixin class _$GalleryAlbumCopyWith<$Res> implements $GalleryAlbumCopyWith<$Res> {
  factory _$GalleryAlbumCopyWith(_GalleryAlbum value, $Res Function(_GalleryAlbum) _then) = __$GalleryAlbumCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, ApiImage cover, int imagesCount, int videosCount
});


@override $ApiImageCopyWith<$Res> get cover;

}
/// @nodoc
class __$GalleryAlbumCopyWithImpl<$Res>
    implements _$GalleryAlbumCopyWith<$Res> {
  __$GalleryAlbumCopyWithImpl(this._self, this._then);

  final _GalleryAlbum _self;
  final $Res Function(_GalleryAlbum) _then;

/// Create a copy of GalleryAlbum
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? cover = null,Object? imagesCount = null,Object? videosCount = null,}) {
  return _then(_GalleryAlbum(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ApiImage,imagesCount: null == imagesCount ? _self.imagesCount : imagesCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of GalleryAlbum
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApiImageCopyWith<$Res> get cover {
  
  return $ApiImageCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}

// dart format on
