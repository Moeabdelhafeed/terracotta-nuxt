// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'language.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Language {

 int get id;/// BCP-47 tag — `"en"`, `"ar"`. The value every other endpoint wants.
 String get code;/// The language named in the requested locale ("Arabic").
 String get name;/// The language named in itself ("العربية"). Show this in a picker.
 String get nativeName;/// Layout direction. Drives `Directionality`; see [LanguageDirection].
@JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire) LanguageDirection get direction;/// The backend's fallback locale. `ar` in the live capture.
 bool get isDefault;/// Flag / badge asset. **Null for every language captured.**
 ApiImage? get image;
/// Create a copy of Language
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LanguageCopyWith<Language> get copyWith => _$LanguageCopyWithImpl<Language>(this as Language, _$identity);

  /// Serializes this Language to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Language&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nativeName, nativeName) || other.nativeName == nativeName)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,nativeName,direction,isDefault,image);

@override
String toString() {
  return 'Language(id: $id, code: $code, name: $name, nativeName: $nativeName, direction: $direction, isDefault: $isDefault, image: $image)';
}


}

/// @nodoc
abstract mixin class $LanguageCopyWith<$Res>  {
  factory $LanguageCopyWith(Language value, $Res Function(Language) _then) = _$LanguageCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name, String nativeName,@JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire) LanguageDirection direction, bool isDefault, ApiImage? image
});


$ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class _$LanguageCopyWithImpl<$Res>
    implements $LanguageCopyWith<$Res> {
  _$LanguageCopyWithImpl(this._self, this._then);

  final Language _self;
  final $Res Function(Language) _then;

/// Create a copy of Language
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? nativeName = null,Object? direction = null,Object? isDefault = null,Object? image = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nativeName: null == nativeName ? _self.nativeName : nativeName // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as LanguageDirection,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}
/// Create a copy of Language
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


/// Adds pattern-matching-related methods to [Language].
extension LanguagePatterns on Language {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Language value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Language() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Language value)  $default,){
final _that = this;
switch (_that) {
case _Language():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Language value)?  $default,){
final _that = this;
switch (_that) {
case _Language() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String nativeName, @JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire)  LanguageDirection direction,  bool isDefault,  ApiImage? image)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Language() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.nativeName,_that.direction,_that.isDefault,_that.image);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String nativeName, @JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire)  LanguageDirection direction,  bool isDefault,  ApiImage? image)  $default,) {final _that = this;
switch (_that) {
case _Language():
return $default(_that.id,_that.code,_that.name,_that.nativeName,_that.direction,_that.isDefault,_that.image);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name,  String nativeName, @JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire)  LanguageDirection direction,  bool isDefault,  ApiImage? image)?  $default,) {final _that = this;
switch (_that) {
case _Language() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.nativeName,_that.direction,_that.isDefault,_that.image);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Language implements Language {
  const _Language({required this.id, required this.code, required this.name, required this.nativeName, @JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire) required this.direction, required this.isDefault, this.image});
  factory _Language.fromJson(Map<String, dynamic> json) => _$LanguageFromJson(json);

@override final  int id;
/// BCP-47 tag — `"en"`, `"ar"`. The value every other endpoint wants.
@override final  String code;
/// The language named in the requested locale ("Arabic").
@override final  String name;
/// The language named in itself ("العربية"). Show this in a picker.
@override final  String nativeName;
/// Layout direction. Drives `Directionality`; see [LanguageDirection].
@override@JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire) final  LanguageDirection direction;
/// The backend's fallback locale. `ar` in the live capture.
@override final  bool isDefault;
/// Flag / badge asset. **Null for every language captured.**
@override final  ApiImage? image;

/// Create a copy of Language
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LanguageCopyWith<_Language> get copyWith => __$LanguageCopyWithImpl<_Language>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LanguageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Language&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.nativeName, nativeName) || other.nativeName == nativeName)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.image, image) || other.image == image));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,nativeName,direction,isDefault,image);

@override
String toString() {
  return 'Language(id: $id, code: $code, name: $name, nativeName: $nativeName, direction: $direction, isDefault: $isDefault, image: $image)';
}


}

/// @nodoc
abstract mixin class _$LanguageCopyWith<$Res> implements $LanguageCopyWith<$Res> {
  factory _$LanguageCopyWith(_Language value, $Res Function(_Language) _then) = __$LanguageCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name, String nativeName,@JsonKey(fromJson: LanguageDirection.fromWire, toJson: languageDirectionToWire) LanguageDirection direction, bool isDefault, ApiImage? image
});


@override $ApiImageCopyWith<$Res>? get image;

}
/// @nodoc
class __$LanguageCopyWithImpl<$Res>
    implements _$LanguageCopyWith<$Res> {
  __$LanguageCopyWithImpl(this._self, this._then);

  final _Language _self;
  final $Res Function(_Language) _then;

/// Create a copy of Language
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? nativeName = null,Object? direction = null,Object? isDefault = null,Object? image = freezed,}) {
  return _then(_Language(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nativeName: null == nativeName ? _self.nativeName : nativeName // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as LanguageDirection,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as ApiImage?,
  ));
}

/// Create a copy of Language
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
