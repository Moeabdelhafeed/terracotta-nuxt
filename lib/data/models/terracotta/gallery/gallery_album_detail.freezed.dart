// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_album_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GalleryAlbumDetail {

/// Album id — matches `GalleryAlbum.id`.
 int get id;/// Already-localized album name for the requested locale.
 String get title;/// How many still images the album holds. Should equal the number
/// of image items in [items] when the whole album is returned.
 int get imagesCount;/// How many videos the album holds. `0` throughout the capture.
 int get videosCount;/// The album's media, in server order. Empty list, never null.
 List<GalleryMediaItem> get items;
/// Create a copy of GalleryAlbumDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryAlbumDetailCopyWith<GalleryAlbumDetail> get copyWith => _$GalleryAlbumDetailCopyWithImpl<GalleryAlbumDetail>(this as GalleryAlbumDetail, _$identity);

  /// Serializes this GalleryAlbumDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryAlbumDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imagesCount, imagesCount) || other.imagesCount == imagesCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imagesCount,videosCount,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'GalleryAlbumDetail(id: $id, title: $title, imagesCount: $imagesCount, videosCount: $videosCount, items: $items)';
}


}

/// @nodoc
abstract mixin class $GalleryAlbumDetailCopyWith<$Res>  {
  factory $GalleryAlbumDetailCopyWith(GalleryAlbumDetail value, $Res Function(GalleryAlbumDetail) _then) = _$GalleryAlbumDetailCopyWithImpl;
@useResult
$Res call({
 int id, String title, int imagesCount, int videosCount, List<GalleryMediaItem> items
});




}
/// @nodoc
class _$GalleryAlbumDetailCopyWithImpl<$Res>
    implements $GalleryAlbumDetailCopyWith<$Res> {
  _$GalleryAlbumDetailCopyWithImpl(this._self, this._then);

  final GalleryAlbumDetail _self;
  final $Res Function(GalleryAlbumDetail) _then;

/// Create a copy of GalleryAlbumDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? imagesCount = null,Object? videosCount = null,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imagesCount: null == imagesCount ? _self.imagesCount : imagesCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GalleryMediaItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [GalleryAlbumDetail].
extension GalleryAlbumDetailPatterns on GalleryAlbumDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GalleryAlbumDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GalleryAlbumDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GalleryAlbumDetail value)  $default,){
final _that = this;
switch (_that) {
case _GalleryAlbumDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GalleryAlbumDetail value)?  $default,){
final _that = this;
switch (_that) {
case _GalleryAlbumDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  int imagesCount,  int videosCount,  List<GalleryMediaItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GalleryAlbumDetail() when $default != null:
return $default(_that.id,_that.title,_that.imagesCount,_that.videosCount,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  int imagesCount,  int videosCount,  List<GalleryMediaItem> items)  $default,) {final _that = this;
switch (_that) {
case _GalleryAlbumDetail():
return $default(_that.id,_that.title,_that.imagesCount,_that.videosCount,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  int imagesCount,  int videosCount,  List<GalleryMediaItem> items)?  $default,) {final _that = this;
switch (_that) {
case _GalleryAlbumDetail() when $default != null:
return $default(_that.id,_that.title,_that.imagesCount,_that.videosCount,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GalleryAlbumDetail extends GalleryAlbumDetail {
  const _GalleryAlbumDetail({required this.id, required this.title, required this.imagesCount, required this.videosCount, required final  List<GalleryMediaItem> items}): _items = items,super._();
  factory _GalleryAlbumDetail.fromJson(Map<String, dynamic> json) => _$GalleryAlbumDetailFromJson(json);

/// Album id — matches `GalleryAlbum.id`.
@override final  int id;
/// Already-localized album name for the requested locale.
@override final  String title;
/// How many still images the album holds. Should equal the number
/// of image items in [items] when the whole album is returned.
@override final  int imagesCount;
/// How many videos the album holds. `0` throughout the capture.
@override final  int videosCount;
/// The album's media, in server order. Empty list, never null.
 final  List<GalleryMediaItem> _items;
/// The album's media, in server order. Empty list, never null.
@override List<GalleryMediaItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of GalleryAlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GalleryAlbumDetailCopyWith<_GalleryAlbumDetail> get copyWith => __$GalleryAlbumDetailCopyWithImpl<_GalleryAlbumDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GalleryAlbumDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GalleryAlbumDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imagesCount, imagesCount) || other.imagesCount == imagesCount)&&(identical(other.videosCount, videosCount) || other.videosCount == videosCount)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,imagesCount,videosCount,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'GalleryAlbumDetail(id: $id, title: $title, imagesCount: $imagesCount, videosCount: $videosCount, items: $items)';
}


}

/// @nodoc
abstract mixin class _$GalleryAlbumDetailCopyWith<$Res> implements $GalleryAlbumDetailCopyWith<$Res> {
  factory _$GalleryAlbumDetailCopyWith(_GalleryAlbumDetail value, $Res Function(_GalleryAlbumDetail) _then) = __$GalleryAlbumDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, int imagesCount, int videosCount, List<GalleryMediaItem> items
});




}
/// @nodoc
class __$GalleryAlbumDetailCopyWithImpl<$Res>
    implements _$GalleryAlbumDetailCopyWith<$Res> {
  __$GalleryAlbumDetailCopyWithImpl(this._self, this._then);

  final _GalleryAlbumDetail _self;
  final $Res Function(_GalleryAlbumDetail) _then;

/// Create a copy of GalleryAlbumDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? imagesCount = null,Object? videosCount = null,Object? items = null,}) {
  return _then(_GalleryAlbumDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imagesCount: null == imagesCount ? _self.imagesCount : imagesCount // ignore: cast_nullable_to_non_nullable
as int,videosCount: null == videosCount ? _self.videosCount : videosCount // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GalleryMediaItem>,
  ));
}


}

// dart format on
