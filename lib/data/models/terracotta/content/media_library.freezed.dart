// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_library.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MediaLibrary {

/// The manifest namespace, echoed from the request. `"app"` live.
 String get group;/// section name → slot name → asset. Both key levels are CMS-owned.
///
/// **An EMPTY one arrives as `[]`, not `{}`.** PHP has one array
/// type and Laravel's JSON encoder cannot tell an empty map from
/// an empty list, so a CMS with no media at all answers
/// `"media": []` — which failed the `Map` cast and took the whole
/// library down with it. That is precisely the state this feature
/// exists to bootstrap out of: nothing loaded, so nothing seeded,
/// so nothing ever loaded. [readSections] reads either shape.
@JsonKey(fromJson: readSections) Map<String, Map<String, MediaItem>> get media;
/// Create a copy of MediaLibrary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaLibraryCopyWith<MediaLibrary> get copyWith => _$MediaLibraryCopyWithImpl<MediaLibrary>(this as MediaLibrary, _$identity);

  /// Serializes this MediaLibrary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MediaLibrary&&(identical(other.group, group) || other.group == group)&&const DeepCollectionEquality().equals(other.media, media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,group,const DeepCollectionEquality().hash(media));

@override
String toString() {
  return 'MediaLibrary(group: $group, media: $media)';
}


}

/// @nodoc
abstract mixin class $MediaLibraryCopyWith<$Res>  {
  factory $MediaLibraryCopyWith(MediaLibrary value, $Res Function(MediaLibrary) _then) = _$MediaLibraryCopyWithImpl;
@useResult
$Res call({
 String group,@JsonKey(fromJson: readSections) Map<String, Map<String, MediaItem>> media
});




}
/// @nodoc
class _$MediaLibraryCopyWithImpl<$Res>
    implements $MediaLibraryCopyWith<$Res> {
  _$MediaLibraryCopyWithImpl(this._self, this._then);

  final MediaLibrary _self;
  final $Res Function(MediaLibrary) _then;

/// Create a copy of MediaLibrary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = null,Object? media = null,}) {
  return _then(_self.copyWith(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, MediaItem>>,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaLibrary].
extension MediaLibraryPatterns on MediaLibrary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MediaLibrary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MediaLibrary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MediaLibrary value)  $default,){
final _that = this;
switch (_that) {
case _MediaLibrary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MediaLibrary value)?  $default,){
final _that = this;
switch (_that) {
case _MediaLibrary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String group, @JsonKey(fromJson: readSections)  Map<String, Map<String, MediaItem>> media)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MediaLibrary() when $default != null:
return $default(_that.group,_that.media);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String group, @JsonKey(fromJson: readSections)  Map<String, Map<String, MediaItem>> media)  $default,) {final _that = this;
switch (_that) {
case _MediaLibrary():
return $default(_that.group,_that.media);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String group, @JsonKey(fromJson: readSections)  Map<String, Map<String, MediaItem>> media)?  $default,) {final _that = this;
switch (_that) {
case _MediaLibrary() when $default != null:
return $default(_that.group,_that.media);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MediaLibrary extends MediaLibrary {
  const _MediaLibrary({required this.group, @JsonKey(fromJson: readSections) required final  Map<String, Map<String, MediaItem>> media}): _media = media,super._();
  factory _MediaLibrary.fromJson(Map<String, dynamic> json) => _$MediaLibraryFromJson(json);

/// The manifest namespace, echoed from the request. `"app"` live.
@override final  String group;
/// section name → slot name → asset. Both key levels are CMS-owned.
///
/// **An EMPTY one arrives as `[]`, not `{}`.** PHP has one array
/// type and Laravel's JSON encoder cannot tell an empty map from
/// an empty list, so a CMS with no media at all answers
/// `"media": []` — which failed the `Map` cast and took the whole
/// library down with it. That is precisely the state this feature
/// exists to bootstrap out of: nothing loaded, so nothing seeded,
/// so nothing ever loaded. [readSections] reads either shape.
 final  Map<String, Map<String, MediaItem>> _media;
/// section name → slot name → asset. Both key levels are CMS-owned.
///
/// **An EMPTY one arrives as `[]`, not `{}`.** PHP has one array
/// type and Laravel's JSON encoder cannot tell an empty map from
/// an empty list, so a CMS with no media at all answers
/// `"media": []` — which failed the `Map` cast and took the whole
/// library down with it. That is precisely the state this feature
/// exists to bootstrap out of: nothing loaded, so nothing seeded,
/// so nothing ever loaded. [readSections] reads either shape.
@override@JsonKey(fromJson: readSections) Map<String, Map<String, MediaItem>> get media {
  if (_media is EqualUnmodifiableMapView) return _media;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_media);
}


/// Create a copy of MediaLibrary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaLibraryCopyWith<_MediaLibrary> get copyWith => __$MediaLibraryCopyWithImpl<_MediaLibrary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaLibraryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MediaLibrary&&(identical(other.group, group) || other.group == group)&&const DeepCollectionEquality().equals(other._media, _media));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,group,const DeepCollectionEquality().hash(_media));

@override
String toString() {
  return 'MediaLibrary(group: $group, media: $media)';
}


}

/// @nodoc
abstract mixin class _$MediaLibraryCopyWith<$Res> implements $MediaLibraryCopyWith<$Res> {
  factory _$MediaLibraryCopyWith(_MediaLibrary value, $Res Function(_MediaLibrary) _then) = __$MediaLibraryCopyWithImpl;
@override @useResult
$Res call({
 String group,@JsonKey(fromJson: readSections) Map<String, Map<String, MediaItem>> media
});




}
/// @nodoc
class __$MediaLibraryCopyWithImpl<$Res>
    implements _$MediaLibraryCopyWith<$Res> {
  __$MediaLibraryCopyWithImpl(this._self, this._then);

  final _MediaLibrary _self;
  final $Res Function(_MediaLibrary) _then;

/// Create a copy of MediaLibrary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = null,Object? media = null,}) {
  return _then(_MediaLibrary(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self._media : media // ignore: cast_nullable_to_non_nullable
as Map<String, Map<String, MediaItem>>,
  ));
}


}

// dart format on
