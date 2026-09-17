// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_banner.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeBanner {

 int get id;/// **Body copy**, not a caption — the long line.
 String get label;/// **Headline** — the short line.
 String get title;/// CTA button label. Null when the banner is not a call to action.
 String? get ctaText;/// Where the banner goes. See [HomeLinkType].
@JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire) HomeLinkType get linkType;/// CMS id of the destination row, for the id-carrying link types.
/// Null for section-level and external destinations.
 int? get linkTargetId;/// Absolute off-app URL. Non-null only for `external`.
 String? get link;/// Banner artwork.
 ApiImage? get image;
/// Create a copy of HomeBanner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeBannerCopyWith<HomeBanner> get copyWith => _$HomeBannerCopyWithImpl<HomeBanner>(this as HomeBanner, _$identity);

  /// Serializes this HomeBanner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeBanner&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.title, title) || other.title == title)&&(identical(other.ctaText, ctaText) || other.ctaText == ctaText)&&(identical(other.linkType, linkType) || other.linkType == linkType)&&(identical(other.linkTargetId, linkTargetId) || other.linkTargetId == linkTargetId)&&(identical(other.link, link) || other.link == link)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,title,ctaText,linkType,linkTargetId,link,image);

@override
String toString() {
  return 'HomeBanner(id: $id, label: $label, title: $title, ctaText: $ctaText, linkType: $linkType, linkTargetId: $linkTargetId, link: $link, image: $image)';
}


}

/// @nodoc
abstract mixin class $HomeBannerCopyWith<$Res>  {
  factory $HomeBannerCopyWith(HomeBanner value, $Res Function(HomeBanner) _then) = _$HomeBannerCopyWithImpl;
@useResult
$Res call({
 int id, String label, String title, String? ctaText,@JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire) HomeLinkType linkType, int? linkTargetId, String? link, ApiImage? image
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$HomeBannerCopyWithImpl<$Res>
    implements $HomeBannerCopyWith<$Res> {
  _$HomeBannerCopyWithImpl(this._self, this._then);

  final HomeBanner _self;
  final $Res Function(HomeBanner) _then;

/// Create a copy of HomeBanner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? title = null,Object? ctaText = freezed,Object? linkType = null,Object? linkTargetId = freezed,Object? link = freezed,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ctaText: freezed == ctaText ? _self.ctaText : ctaText // ignore: cast_nullable_to_non_nullable
as String?,linkType: null == linkType ? _self.linkType : linkType // ignore: cast_nullable_to_non_nullable
as HomeLinkType,linkTargetId: freezed == linkTargetId ? _self.linkTargetId : linkTargetId // ignore: cast_nullable_to_non_nullable
as int?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}
/// Create a copy of HomeBanner
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


/// Adds pattern-matching-related methods to [HomeBanner].
extension HomeBannerPatterns on HomeBanner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeBanner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeBanner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeBanner value)  $default,){
final _that = this;
switch (_that) {
case _HomeBanner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeBanner value)?  $default,){
final _that = this;
switch (_that) {
case _HomeBanner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label,  String title,  String? ctaText, @JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire)  HomeLinkType linkType,  int? linkTargetId,  String? link,  ApiImage? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeBanner() when $default != null:
return $default(_that.id,_that.label,_that.title,_that.ctaText,_that.linkType,_that.linkTargetId,_that.link,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label,  String title,  String? ctaText, @JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire)  HomeLinkType linkType,  int? linkTargetId,  String? link,  ApiImage? image)  $default,) {final _that = this;
switch (_that) {
case _HomeBanner():
return $default(_that.id,_that.label,_that.title,_that.ctaText,_that.linkType,_that.linkTargetId,_that.link,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label,  String title,  String? ctaText, @JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire)  HomeLinkType linkType,  int? linkTargetId,  String? link,  ApiImage? image)?  $default,) {final _that = this;
switch (_that) {
case _HomeBanner() when $default != null:
return $default(_that.id,_that.label,_that.title,_that.ctaText,_that.linkType,_that.linkTargetId,_that.link,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeBanner implements HomeBanner {
  const _HomeBanner({required this.id, required this.label, required this.title, this.ctaText, @JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire) required this.linkType, this.linkTargetId, this.link, this.image});
  factory _HomeBanner.fromJson(Map<String, dynamic> json) => _$HomeBannerFromJson(json);

@override final  int id;
/// **Body copy**, not a caption — the long line.
@override final  String label;
/// **Headline** — the short line.
@override final  String title;
/// CTA button label. Null when the banner is not a call to action.
@override final  String? ctaText;
/// Where the banner goes. See [HomeLinkType].
@override@JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire) final  HomeLinkType linkType;
/// CMS id of the destination row, for the id-carrying link types.
/// Null for section-level and external destinations.
@override final  int? linkTargetId;
/// Absolute off-app URL. Non-null only for `external`.
@override final  String? link;
/// Banner artwork.
@override final  ApiImage? image;

/// Create a copy of HomeBanner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeBannerCopyWith<_HomeBanner> get copyWith => __$HomeBannerCopyWithImpl<_HomeBanner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeBannerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeBanner&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.title, title) || other.title == title)&&(identical(other.ctaText, ctaText) || other.ctaText == ctaText)&&(identical(other.linkType, linkType) || other.linkType == linkType)&&(identical(other.linkTargetId, linkTargetId) || other.linkTargetId == linkTargetId)&&(identical(other.link, link) || other.link == link)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,title,ctaText,linkType,linkTargetId,link,image);

@override
String toString() {
  return 'HomeBanner(id: $id, label: $label, title: $title, ctaText: $ctaText, linkType: $linkType, linkTargetId: $linkTargetId, link: $link, image: $image)';
}


}

/// @nodoc
abstract mixin class _$HomeBannerCopyWith<$Res> implements $HomeBannerCopyWith<$Res> {
  factory _$HomeBannerCopyWith(_HomeBanner value, $Res Function(_HomeBanner) _then) = __$HomeBannerCopyWithImpl;
@override @useResult
$Res call({
 int id, String label, String title, String? ctaText,@JsonKey(fromJson: HomeLinkType.fromWire, toJson: homeLinkTypeToWire) HomeLinkType linkType, int? linkTargetId, String? link, ApiImage? image
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$HomeBannerCopyWithImpl<$Res>
    implements _$HomeBannerCopyWith<$Res> {
  __$HomeBannerCopyWithImpl(this._self, this._then);

  final _HomeBanner _self;
  final $Res Function(_HomeBanner) _then;

/// Create a copy of HomeBanner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? title = null,Object? ctaText = freezed,Object? linkType = null,Object? linkTargetId = freezed,Object? link = freezed,Object? image = freezed,}) {
  return _then(_HomeBanner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ctaText: freezed == ctaText ? _self.ctaText : ctaText // ignore: cast_nullable_to_non_nullable
as String?,linkType: null == linkType ? _self.linkType : linkType // ignore: cast_nullable_to_non_nullable
as HomeLinkType,linkTargetId: freezed == linkTargetId ? _self.linkTargetId : linkTargetId // ignore: cast_nullable_to_non_nullable
as int?,link: freezed == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String?,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}

/// Create a copy of HomeBanner
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
