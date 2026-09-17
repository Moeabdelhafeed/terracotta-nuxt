// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

/// Social profiles — Instagram, TikTok in the capture.
@JsonKey(fromJson: readLinks) List<LinkItem> get social;/// Ways to reach the studio. Mixed schemes (`https:`, `mailto:`).
@JsonKey(fromJson: readLinks) List<LinkItem> get contact;/// Apple App Store badge/link.
@JsonKey(fromJson: readLinks) List<LinkItem> get appStore;/// Google Play badge/link.
@JsonKey(fromJson: readLinks) List<LinkItem> get googlePlay;/// Huawei AppGallery badge/link.
@JsonKey(fromJson: readLinks) List<LinkItem> get appGallery;/// Business / corporate links. **Empty in the live capture** —
/// check `isNotEmpty` before drawing a section for it.
@JsonKey(fromJson: readLinks) List<LinkItem> get business;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&const DeepCollectionEquality().equals(other.social, social)&&const DeepCollectionEquality().equals(other.contact, contact)&&const DeepCollectionEquality().equals(other.appStore, appStore)&&const DeepCollectionEquality().equals(other.googlePlay, googlePlay)&&const DeepCollectionEquality().equals(other.appGallery, appGallery)&&const DeepCollectionEquality().equals(other.business, business));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(social),const DeepCollectionEquality().hash(contact),const DeepCollectionEquality().hash(appStore),const DeepCollectionEquality().hash(googlePlay),const DeepCollectionEquality().hash(appGallery),const DeepCollectionEquality().hash(business));

@override
String toString() {
  return 'AppSettings(social: $social, contact: $contact, appStore: $appStore, googlePlay: $googlePlay, appGallery: $appGallery, business: $business)';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: readLinks) List<LinkItem> social,@JsonKey(fromJson: readLinks) List<LinkItem> contact,@JsonKey(fromJson: readLinks) List<LinkItem> appStore,@JsonKey(fromJson: readLinks) List<LinkItem> googlePlay,@JsonKey(fromJson: readLinks) List<LinkItem> appGallery,@JsonKey(fromJson: readLinks) List<LinkItem> business
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? social = null,Object? contact = null,Object? appStore = null,Object? googlePlay = null,Object? appGallery = null,Object? business = null,}) {
  return _then(_self.copyWith(
social: null == social ? _self.social : social // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,contact: null == contact ? _self.contact : contact // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,appStore: null == appStore ? _self.appStore : appStore // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,googlePlay: null == googlePlay ? _self.googlePlay : googlePlay // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,appGallery: null == appGallery ? _self.appGallery : appGallery // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,business: null == business ? _self.business : business // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: readLinks)  List<LinkItem> social, @JsonKey(fromJson: readLinks)  List<LinkItem> contact, @JsonKey(fromJson: readLinks)  List<LinkItem> appStore, @JsonKey(fromJson: readLinks)  List<LinkItem> googlePlay, @JsonKey(fromJson: readLinks)  List<LinkItem> appGallery, @JsonKey(fromJson: readLinks)  List<LinkItem> business)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.social,_that.contact,_that.appStore,_that.googlePlay,_that.appGallery,_that.business);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: readLinks)  List<LinkItem> social, @JsonKey(fromJson: readLinks)  List<LinkItem> contact, @JsonKey(fromJson: readLinks)  List<LinkItem> appStore, @JsonKey(fromJson: readLinks)  List<LinkItem> googlePlay, @JsonKey(fromJson: readLinks)  List<LinkItem> appGallery, @JsonKey(fromJson: readLinks)  List<LinkItem> business)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.social,_that.contact,_that.appStore,_that.googlePlay,_that.appGallery,_that.business);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: readLinks)  List<LinkItem> social, @JsonKey(fromJson: readLinks)  List<LinkItem> contact, @JsonKey(fromJson: readLinks)  List<LinkItem> appStore, @JsonKey(fromJson: readLinks)  List<LinkItem> googlePlay, @JsonKey(fromJson: readLinks)  List<LinkItem> appGallery, @JsonKey(fromJson: readLinks)  List<LinkItem> business)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.social,_that.contact,_that.appStore,_that.googlePlay,_that.appGallery,_that.business);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings implements AppSettings {
  const _AppSettings({@JsonKey(fromJson: readLinks) required final  List<LinkItem> social, @JsonKey(fromJson: readLinks) required final  List<LinkItem> contact, @JsonKey(fromJson: readLinks) required final  List<LinkItem> appStore, @JsonKey(fromJson: readLinks) required final  List<LinkItem> googlePlay, @JsonKey(fromJson: readLinks) required final  List<LinkItem> appGallery, @JsonKey(fromJson: readLinks) required final  List<LinkItem> business}): _social = social,_contact = contact,_appStore = appStore,_googlePlay = googlePlay,_appGallery = appGallery,_business = business;
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

/// Social profiles — Instagram, TikTok in the capture.
 final  List<LinkItem> _social;
/// Social profiles — Instagram, TikTok in the capture.
@override@JsonKey(fromJson: readLinks) List<LinkItem> get social {
  if (_social is EqualUnmodifiableListView) return _social;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_social);
}

/// Ways to reach the studio. Mixed schemes (`https:`, `mailto:`).
 final  List<LinkItem> _contact;
/// Ways to reach the studio. Mixed schemes (`https:`, `mailto:`).
@override@JsonKey(fromJson: readLinks) List<LinkItem> get contact {
  if (_contact is EqualUnmodifiableListView) return _contact;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_contact);
}

/// Apple App Store badge/link.
 final  List<LinkItem> _appStore;
/// Apple App Store badge/link.
@override@JsonKey(fromJson: readLinks) List<LinkItem> get appStore {
  if (_appStore is EqualUnmodifiableListView) return _appStore;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appStore);
}

/// Google Play badge/link.
 final  List<LinkItem> _googlePlay;
/// Google Play badge/link.
@override@JsonKey(fromJson: readLinks) List<LinkItem> get googlePlay {
  if (_googlePlay is EqualUnmodifiableListView) return _googlePlay;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_googlePlay);
}

/// Huawei AppGallery badge/link.
 final  List<LinkItem> _appGallery;
/// Huawei AppGallery badge/link.
@override@JsonKey(fromJson: readLinks) List<LinkItem> get appGallery {
  if (_appGallery is EqualUnmodifiableListView) return _appGallery;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appGallery);
}

/// Business / corporate links. **Empty in the live capture** —
/// check `isNotEmpty` before drawing a section for it.
 final  List<LinkItem> _business;
/// Business / corporate links. **Empty in the live capture** —
/// check `isNotEmpty` before drawing a section for it.
@override@JsonKey(fromJson: readLinks) List<LinkItem> get business {
  if (_business is EqualUnmodifiableListView) return _business;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_business);
}


/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&const DeepCollectionEquality().equals(other._social, _social)&&const DeepCollectionEquality().equals(other._contact, _contact)&&const DeepCollectionEquality().equals(other._appStore, _appStore)&&const DeepCollectionEquality().equals(other._googlePlay, _googlePlay)&&const DeepCollectionEquality().equals(other._appGallery, _appGallery)&&const DeepCollectionEquality().equals(other._business, _business));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_social),const DeepCollectionEquality().hash(_contact),const DeepCollectionEquality().hash(_appStore),const DeepCollectionEquality().hash(_googlePlay),const DeepCollectionEquality().hash(_appGallery),const DeepCollectionEquality().hash(_business));

@override
String toString() {
  return 'AppSettings(social: $social, contact: $contact, appStore: $appStore, googlePlay: $googlePlay, appGallery: $appGallery, business: $business)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: readLinks) List<LinkItem> social,@JsonKey(fromJson: readLinks) List<LinkItem> contact,@JsonKey(fromJson: readLinks) List<LinkItem> appStore,@JsonKey(fromJson: readLinks) List<LinkItem> googlePlay,@JsonKey(fromJson: readLinks) List<LinkItem> appGallery,@JsonKey(fromJson: readLinks) List<LinkItem> business
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? social = null,Object? contact = null,Object? appStore = null,Object? googlePlay = null,Object? appGallery = null,Object? business = null,}) {
  return _then(_AppSettings(
social: null == social ? _self._social : social // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,contact: null == contact ? _self._contact : contact // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,appStore: null == appStore ? _self._appStore : appStore // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,googlePlay: null == googlePlay ? _self._googlePlay : googlePlay // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,appGallery: null == appGallery ? _self._appGallery : appGallery // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,business: null == business ? _self._business : business // ignore: cast_nullable_to_non_nullable
as List<LinkItem>,
  ));
}


}

// dart format on
