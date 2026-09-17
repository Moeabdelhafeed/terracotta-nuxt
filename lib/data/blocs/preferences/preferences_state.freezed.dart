// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'preferences_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PreferencesState {

 Language get language;@_ThemeModeConverter() ThemeMode get themeMode; AppRole get appRole; ColorSaturation get colorSaturation; String get revealShapeKey; String get revealDirectionName; bool get seenOnboarding; bool get isFirstTime; double get fontScale; bool get dynamicColor;
/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreferencesStateCopyWith<PreferencesState> get copyWith => _$PreferencesStateCopyWithImpl<PreferencesState>(this as PreferencesState, _$identity);

  /// Serializes this PreferencesState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreferencesState&&(identical(other.language, language) || other.language == language)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.appRole, appRole) || other.appRole == appRole)&&(identical(other.colorSaturation, colorSaturation) || other.colorSaturation == colorSaturation)&&(identical(other.revealShapeKey, revealShapeKey) || other.revealShapeKey == revealShapeKey)&&(identical(other.revealDirectionName, revealDirectionName) || other.revealDirectionName == revealDirectionName)&&(identical(other.seenOnboarding, seenOnboarding) || other.seenOnboarding == seenOnboarding)&&(identical(other.isFirstTime, isFirstTime) || other.isFirstTime == isFirstTime)&&(identical(other.fontScale, fontScale) || other.fontScale == fontScale)&&(identical(other.dynamicColor, dynamicColor) || other.dynamicColor == dynamicColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,themeMode,appRole,colorSaturation,revealShapeKey,revealDirectionName,seenOnboarding,isFirstTime,fontScale,dynamicColor);

@override
String toString() {
  return 'PreferencesState(language: $language, themeMode: $themeMode, appRole: $appRole, colorSaturation: $colorSaturation, revealShapeKey: $revealShapeKey, revealDirectionName: $revealDirectionName, seenOnboarding: $seenOnboarding, isFirstTime: $isFirstTime, fontScale: $fontScale, dynamicColor: $dynamicColor)';
}


}

/// @nodoc
abstract mixin class $PreferencesStateCopyWith<$Res>  {
  factory $PreferencesStateCopyWith(PreferencesState value, $Res Function(PreferencesState) _then) = _$PreferencesStateCopyWithImpl;
@useResult
$Res call({
 Language language,@_ThemeModeConverter() ThemeMode themeMode, AppRole appRole, ColorSaturation colorSaturation, String revealShapeKey, String revealDirectionName, bool seenOnboarding, bool isFirstTime, double fontScale, bool dynamicColor
});


$LanguageCopyWith<$Res> get language;

}
/// @nodoc
class _$PreferencesStateCopyWithImpl<$Res>
    implements $PreferencesStateCopyWith<$Res> {
  _$PreferencesStateCopyWithImpl(this._self, this._then);

  final PreferencesState _self;
  final $Res Function(PreferencesState) _then;

/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? themeMode = null,Object? appRole = null,Object? colorSaturation = null,Object? revealShapeKey = null,Object? revealDirectionName = null,Object? seenOnboarding = null,Object? isFirstTime = null,Object? fontScale = null,Object? dynamicColor = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as Language,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,appRole: null == appRole ? _self.appRole : appRole // ignore: cast_nullable_to_non_nullable
as AppRole,colorSaturation: null == colorSaturation ? _self.colorSaturation : colorSaturation // ignore: cast_nullable_to_non_nullable
as ColorSaturation,revealShapeKey: null == revealShapeKey ? _self.revealShapeKey : revealShapeKey // ignore: cast_nullable_to_non_nullable
as String,revealDirectionName: null == revealDirectionName ? _self.revealDirectionName : revealDirectionName // ignore: cast_nullable_to_non_nullable
as String,seenOnboarding: null == seenOnboarding ? _self.seenOnboarding : seenOnboarding // ignore: cast_nullable_to_non_nullable
as bool,isFirstTime: null == isFirstTime ? _self.isFirstTime : isFirstTime // ignore: cast_nullable_to_non_nullable
as bool,fontScale: null == fontScale ? _self.fontScale : fontScale // ignore: cast_nullable_to_non_nullable
as double,dynamicColor: null == dynamicColor ? _self.dynamicColor : dynamicColor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LanguageCopyWith<$Res> get language {
  
  return $LanguageCopyWith<$Res>(_self.language, (value) {
    return _then(_self.copyWith(language: value));
  });
}
}


/// Adds pattern-matching-related methods to [PreferencesState].
extension PreferencesStatePatterns on PreferencesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreferencesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreferencesState value)  $default,){
final _that = this;
switch (_that) {
case _PreferencesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreferencesState value)?  $default,){
final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Language language, @_ThemeModeConverter()  ThemeMode themeMode,  AppRole appRole,  ColorSaturation colorSaturation,  String revealShapeKey,  String revealDirectionName,  bool seenOnboarding,  bool isFirstTime,  double fontScale,  bool dynamicColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
return $default(_that.language,_that.themeMode,_that.appRole,_that.colorSaturation,_that.revealShapeKey,_that.revealDirectionName,_that.seenOnboarding,_that.isFirstTime,_that.fontScale,_that.dynamicColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Language language, @_ThemeModeConverter()  ThemeMode themeMode,  AppRole appRole,  ColorSaturation colorSaturation,  String revealShapeKey,  String revealDirectionName,  bool seenOnboarding,  bool isFirstTime,  double fontScale,  bool dynamicColor)  $default,) {final _that = this;
switch (_that) {
case _PreferencesState():
return $default(_that.language,_that.themeMode,_that.appRole,_that.colorSaturation,_that.revealShapeKey,_that.revealDirectionName,_that.seenOnboarding,_that.isFirstTime,_that.fontScale,_that.dynamicColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Language language, @_ThemeModeConverter()  ThemeMode themeMode,  AppRole appRole,  ColorSaturation colorSaturation,  String revealShapeKey,  String revealDirectionName,  bool seenOnboarding,  bool isFirstTime,  double fontScale,  bool dynamicColor)?  $default,) {final _that = this;
switch (_that) {
case _PreferencesState() when $default != null:
return $default(_that.language,_that.themeMode,_that.appRole,_that.colorSaturation,_that.revealShapeKey,_that.revealDirectionName,_that.seenOnboarding,_that.isFirstTime,_that.fontScale,_that.dynamicColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreferencesState implements PreferencesState {
  const _PreferencesState({this.language = defaultLanguage, @_ThemeModeConverter() this.themeMode = ThemeMode.system, this.appRole = AppRole.user, this.colorSaturation = ColorSaturation.normal, this.revealShapeKey = 'circle', this.revealDirectionName = 'expand', this.seenOnboarding = false, this.isFirstTime = true, this.fontScale = 1.0, this.dynamicColor = false});
  factory _PreferencesState.fromJson(Map<String, dynamic> json) => _$PreferencesStateFromJson(json);

@override@JsonKey() final  Language language;
@override@JsonKey()@_ThemeModeConverter() final  ThemeMode themeMode;
@override@JsonKey() final  AppRole appRole;
@override@JsonKey() final  ColorSaturation colorSaturation;
@override@JsonKey() final  String revealShapeKey;
@override@JsonKey() final  String revealDirectionName;
@override@JsonKey() final  bool seenOnboarding;
@override@JsonKey() final  bool isFirstTime;
@override@JsonKey() final  double fontScale;
@override@JsonKey() final  bool dynamicColor;

/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreferencesStateCopyWith<_PreferencesState> get copyWith => __$PreferencesStateCopyWithImpl<_PreferencesState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreferencesStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreferencesState&&(identical(other.language, language) || other.language == language)&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.appRole, appRole) || other.appRole == appRole)&&(identical(other.colorSaturation, colorSaturation) || other.colorSaturation == colorSaturation)&&(identical(other.revealShapeKey, revealShapeKey) || other.revealShapeKey == revealShapeKey)&&(identical(other.revealDirectionName, revealDirectionName) || other.revealDirectionName == revealDirectionName)&&(identical(other.seenOnboarding, seenOnboarding) || other.seenOnboarding == seenOnboarding)&&(identical(other.isFirstTime, isFirstTime) || other.isFirstTime == isFirstTime)&&(identical(other.fontScale, fontScale) || other.fontScale == fontScale)&&(identical(other.dynamicColor, dynamicColor) || other.dynamicColor == dynamicColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language,themeMode,appRole,colorSaturation,revealShapeKey,revealDirectionName,seenOnboarding,isFirstTime,fontScale,dynamicColor);

@override
String toString() {
  return 'PreferencesState(language: $language, themeMode: $themeMode, appRole: $appRole, colorSaturation: $colorSaturation, revealShapeKey: $revealShapeKey, revealDirectionName: $revealDirectionName, seenOnboarding: $seenOnboarding, isFirstTime: $isFirstTime, fontScale: $fontScale, dynamicColor: $dynamicColor)';
}


}

/// @nodoc
abstract mixin class _$PreferencesStateCopyWith<$Res> implements $PreferencesStateCopyWith<$Res> {
  factory _$PreferencesStateCopyWith(_PreferencesState value, $Res Function(_PreferencesState) _then) = __$PreferencesStateCopyWithImpl;
@override @useResult
$Res call({
 Language language,@_ThemeModeConverter() ThemeMode themeMode, AppRole appRole, ColorSaturation colorSaturation, String revealShapeKey, String revealDirectionName, bool seenOnboarding, bool isFirstTime, double fontScale, bool dynamicColor
});


@override $LanguageCopyWith<$Res> get language;

}
/// @nodoc
class __$PreferencesStateCopyWithImpl<$Res>
    implements _$PreferencesStateCopyWith<$Res> {
  __$PreferencesStateCopyWithImpl(this._self, this._then);

  final _PreferencesState _self;
  final $Res Function(_PreferencesState) _then;

/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? themeMode = null,Object? appRole = null,Object? colorSaturation = null,Object? revealShapeKey = null,Object? revealDirectionName = null,Object? seenOnboarding = null,Object? isFirstTime = null,Object? fontScale = null,Object? dynamicColor = null,}) {
  return _then(_PreferencesState(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as Language,themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,appRole: null == appRole ? _self.appRole : appRole // ignore: cast_nullable_to_non_nullable
as AppRole,colorSaturation: null == colorSaturation ? _self.colorSaturation : colorSaturation // ignore: cast_nullable_to_non_nullable
as ColorSaturation,revealShapeKey: null == revealShapeKey ? _self.revealShapeKey : revealShapeKey // ignore: cast_nullable_to_non_nullable
as String,revealDirectionName: null == revealDirectionName ? _self.revealDirectionName : revealDirectionName // ignore: cast_nullable_to_non_nullable
as String,seenOnboarding: null == seenOnboarding ? _self.seenOnboarding : seenOnboarding // ignore: cast_nullable_to_non_nullable
as bool,isFirstTime: null == isFirstTime ? _self.isFirstTime : isFirstTime // ignore: cast_nullable_to_non_nullable
as bool,fontScale: null == fontScale ? _self.fontScale : fontScale // ignore: cast_nullable_to_non_nullable
as double,dynamicColor: null == dynamicColor ? _self.dynamicColor : dynamicColor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LanguageCopyWith<$Res> get language {
  
  return $LanguageCopyWith<$Res>(_self.language, (value) {
    return _then(_self.copyWith(language: value));
  });
}
}

// dart format on
