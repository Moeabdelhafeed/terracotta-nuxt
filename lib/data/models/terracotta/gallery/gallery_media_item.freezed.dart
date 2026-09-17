// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_media_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GalleryMediaItem {

/// The item's own id — NOT the id of the nested image. Both are
/// present and they differ (item 1 wraps image 33).
 int get id;/// The media kind. Unrecognised wire values degrade to
/// [GalleryMediaType.unknown]; skip those tiles.
@JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire) GalleryMediaType get type;/// The still image for an `image` item. Null for any kind that is
/// not an image — see the class doc.
 ApiImage? get image;
/// Create a copy of GalleryMediaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GalleryMediaItemCopyWith<GalleryMediaItem> get copyWith => _$GalleryMediaItemCopyWithImpl<GalleryMediaItem>(this as GalleryMediaItem, _$identity);

  /// Serializes this GalleryMediaItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryMediaItem&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,image);

@override
String toString() {
  return 'GalleryMediaItem(id: $id, type: $type, image: $image)';
}


}

/// @nodoc
abstract mixin class $GalleryMediaItemCopyWith<$Res>  {
  factory $GalleryMediaItemCopyWith(GalleryMediaItem value, $Res Function(GalleryMediaItem) _then) = _$GalleryMediaItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire) GalleryMediaType type, ApiImage? image
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$GalleryMediaItemCopyWithImpl<$Res>
    implements $GalleryMediaItemCopyWith<$Res> {
  _$GalleryMediaItemCopyWithImpl(this._self, this._then);

  final GalleryMediaItem _self;
  final $Res Function(GalleryMediaItem) _then;

/// Create a copy of GalleryMediaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GalleryMediaType,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}
/// Create a copy of GalleryMediaItem
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


/// Adds pattern-matching-related methods to [GalleryMediaItem].
extension GalleryMediaItemPatterns on GalleryMediaItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GalleryMediaItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GalleryMediaItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GalleryMediaItem value)  $default,){
final _that = this;
switch (_that) {
case _GalleryMediaItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GalleryMediaItem value)?  $default,){
final _that = this;
switch (_that) {
case _GalleryMediaItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire)  GalleryMediaType type,  ApiImage? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GalleryMediaItem() when $default != null:
return $default(_that.id,_that.type,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire)  GalleryMediaType type,  ApiImage? image)  $default,) {final _that = this;
switch (_that) {
case _GalleryMediaItem():
return $default(_that.id,_that.type,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire)  GalleryMediaType type,  ApiImage? image)?  $default,) {final _that = this;
switch (_that) {
case _GalleryMediaItem() when $default != null:
return $default(_that.id,_that.type,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GalleryMediaItem extends GalleryMediaItem {
  const _GalleryMediaItem({required this.id, @JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire) required this.type, this.image}): super._();
  factory _GalleryMediaItem.fromJson(Map<String, dynamic> json) => _$GalleryMediaItemFromJson(json);

/// The item's own id — NOT the id of the nested image. Both are
/// present and they differ (item 1 wraps image 33).
@override final  int id;
/// The media kind. Unrecognised wire values degrade to
/// [GalleryMediaType.unknown]; skip those tiles.
@override@JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire) final  GalleryMediaType type;
/// The still image for an `image` item. Null for any kind that is
/// not an image — see the class doc.
@override final  ApiImage? image;

/// Create a copy of GalleryMediaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GalleryMediaItemCopyWith<_GalleryMediaItem> get copyWith => __$GalleryMediaItemCopyWithImpl<_GalleryMediaItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GalleryMediaItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GalleryMediaItem&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,image);

@override
String toString() {
  return 'GalleryMediaItem(id: $id, type: $type, image: $image)';
}


}

/// @nodoc
abstract mixin class _$GalleryMediaItemCopyWith<$Res> implements $GalleryMediaItemCopyWith<$Res> {
  factory _$GalleryMediaItemCopyWith(_GalleryMediaItem value, $Res Function(_GalleryMediaItem) _then) = __$GalleryMediaItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(fromJson: GalleryMediaType.fromWire, toJson: galleryMediaTypeToWire) GalleryMediaType type, ApiImage? image
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$GalleryMediaItemCopyWithImpl<$Res>
    implements _$GalleryMediaItemCopyWith<$Res> {
  __$GalleryMediaItemCopyWithImpl(this._self, this._then);

  final _GalleryMediaItem _self;
  final $Res Function(_GalleryMediaItem) _then;

/// Create a copy of GalleryMediaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? image = freezed,}) {
  return _then(_GalleryMediaItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GalleryMediaType,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}

/// Create a copy of GalleryMediaItem
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
