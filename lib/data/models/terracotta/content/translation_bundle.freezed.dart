// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'translation_bundle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TranslationBundle {

/// The namespace requested, echoed back. `"app"` live.
 String get group;/// The locale these strings are for, echoed back. `"en"` live.
 String get locale;/// key → translated string. **Empty in the live capture, where the
/// API sends `[]` rather than `{}`.**
@JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson) Map<String, String> get translations;
/// Create a copy of TranslationBundle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TranslationBundleCopyWith<TranslationBundle> get copyWith => _$TranslationBundleCopyWithImpl<TranslationBundle>(this as TranslationBundle, _$identity);

  /// Serializes this TranslationBundle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TranslationBundle&&(identical(other.group, group) || other.group == group)&&(identical(other.locale, locale) || other.locale == locale)&&const DeepCollectionEquality().equals(other.translations, translations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,group,locale,const DeepCollectionEquality().hash(translations));

@override
String toString() {
  return 'TranslationBundle(group: $group, locale: $locale, translations: $translations)';
}


}

/// @nodoc
abstract mixin class $TranslationBundleCopyWith<$Res>  {
  factory $TranslationBundleCopyWith(TranslationBundle value, $Res Function(TranslationBundle) _then) = _$TranslationBundleCopyWithImpl;
@useResult
$Res call({
 String group, String locale,@JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson) Map<String, String> translations
});




}
/// @nodoc
class _$TranslationBundleCopyWithImpl<$Res>
    implements $TranslationBundleCopyWith<$Res> {
  _$TranslationBundleCopyWithImpl(this._self, this._then);

  final TranslationBundle _self;
  final $Res Function(TranslationBundle) _then;

/// Create a copy of TranslationBundle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? group = null,Object? locale = null,Object? translations = null,}) {
  return _then(_self.copyWith(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,translations: null == translations ? _self.translations : translations // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TranslationBundle].
extension TranslationBundlePatterns on TranslationBundle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TranslationBundle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TranslationBundle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TranslationBundle value)  $default,){
final _that = this;
switch (_that) {
case _TranslationBundle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TranslationBundle value)?  $default,){
final _that = this;
switch (_that) {
case _TranslationBundle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String group,  String locale, @JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson)  Map<String, String> translations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TranslationBundle() when $default != null:
return $default(_that.group,_that.locale,_that.translations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String group,  String locale, @JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson)  Map<String, String> translations)  $default,) {final _that = this;
switch (_that) {
case _TranslationBundle():
return $default(_that.group,_that.locale,_that.translations);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String group,  String locale, @JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson)  Map<String, String> translations)?  $default,) {final _that = this;
switch (_that) {
case _TranslationBundle() when $default != null:
return $default(_that.group,_that.locale,_that.translations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TranslationBundle extends TranslationBundle {
  const _TranslationBundle({required this.group, required this.locale, @JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson) required final  Map<String, String> translations}): _translations = translations,super._();
  factory _TranslationBundle.fromJson(Map<String, dynamic> json) => _$TranslationBundleFromJson(json);

/// The namespace requested, echoed back. `"app"` live.
@override final  String group;
/// The locale these strings are for, echoed back. `"en"` live.
@override final  String locale;
/// key → translated string. **Empty in the live capture, where the
/// API sends `[]` rather than `{}`.**
 final  Map<String, String> _translations;
/// key → translated string. **Empty in the live capture, where the
/// API sends `[]` rather than `{}`.**
@override@JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson) Map<String, String> get translations {
  if (_translations is EqualUnmodifiableMapView) return _translations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_translations);
}


/// Create a copy of TranslationBundle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TranslationBundleCopyWith<_TranslationBundle> get copyWith => __$TranslationBundleCopyWithImpl<_TranslationBundle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TranslationBundleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TranslationBundle&&(identical(other.group, group) || other.group == group)&&(identical(other.locale, locale) || other.locale == locale)&&const DeepCollectionEquality().equals(other._translations, _translations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,group,locale,const DeepCollectionEquality().hash(_translations));

@override
String toString() {
  return 'TranslationBundle(group: $group, locale: $locale, translations: $translations)';
}


}

/// @nodoc
abstract mixin class _$TranslationBundleCopyWith<$Res> implements $TranslationBundleCopyWith<$Res> {
  factory _$TranslationBundleCopyWith(_TranslationBundle value, $Res Function(_TranslationBundle) _then) = __$TranslationBundleCopyWithImpl;
@override @useResult
$Res call({
 String group, String locale,@JsonKey(fromJson: _translationsFromJson, toJson: _translationsToJson) Map<String, String> translations
});




}
/// @nodoc
class __$TranslationBundleCopyWithImpl<$Res>
    implements _$TranslationBundleCopyWith<$Res> {
  __$TranslationBundleCopyWithImpl(this._self, this._then);

  final _TranslationBundle _self;
  final $Res Function(_TranslationBundle) _then;

/// Create a copy of TranslationBundle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? group = null,Object? locale = null,Object? translations = null,}) {
  return _then(_TranslationBundle(
group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,translations: null == translations ? _self._translations : translations // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
