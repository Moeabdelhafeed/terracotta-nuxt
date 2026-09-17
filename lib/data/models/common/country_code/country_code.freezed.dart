// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'country_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CountryCode {

 String get code; String? get name; String? get flag; String? get dialCode; int? get minLength; int? get maxLength; int? get mobileMinLength; int? get mobileMaxLength; List<int>? get groupSizes; List<String>? get mobilePrefixes;
/// Create a copy of CountryCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CountryCodeCopyWith<CountryCode> get copyWith => _$CountryCodeCopyWithImpl<CountryCode>(this as CountryCode, _$identity);

  /// Serializes this CountryCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CountryCode&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.flag, flag) || other.flag == flag)&&(identical(other.dialCode, dialCode) || other.dialCode == dialCode)&&(identical(other.minLength, minLength) || other.minLength == minLength)&&(identical(other.maxLength, maxLength) || other.maxLength == maxLength)&&(identical(other.mobileMinLength, mobileMinLength) || other.mobileMinLength == mobileMinLength)&&(identical(other.mobileMaxLength, mobileMaxLength) || other.mobileMaxLength == mobileMaxLength)&&const DeepCollectionEquality().equals(other.groupSizes, groupSizes)&&const DeepCollectionEquality().equals(other.mobilePrefixes, mobilePrefixes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name,flag,dialCode,minLength,maxLength,mobileMinLength,mobileMaxLength,const DeepCollectionEquality().hash(groupSizes),const DeepCollectionEquality().hash(mobilePrefixes));

@override
String toString() {
  return 'CountryCode(code: $code, name: $name, flag: $flag, dialCode: $dialCode, minLength: $minLength, maxLength: $maxLength, mobileMinLength: $mobileMinLength, mobileMaxLength: $mobileMaxLength, groupSizes: $groupSizes, mobilePrefixes: $mobilePrefixes)';
}


}

/// @nodoc
abstract mixin class $CountryCodeCopyWith<$Res>  {
  factory $CountryCodeCopyWith(CountryCode value, $Res Function(CountryCode) _then) = _$CountryCodeCopyWithImpl;
@useResult
$Res call({
 String code, String? name, String? flag, String? dialCode, int? minLength, int? maxLength, int? mobileMinLength, int? mobileMaxLength, List<int>? groupSizes, List<String>? mobilePrefixes
});




}
/// @nodoc
class _$CountryCodeCopyWithImpl<$Res>
    implements $CountryCodeCopyWith<$Res> {
  _$CountryCodeCopyWithImpl(this._self, this._then);

  final CountryCode _self;
  final $Res Function(CountryCode) _then;

/// Create a copy of CountryCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? name = freezed,Object? flag = freezed,Object? dialCode = freezed,Object? minLength = freezed,Object? maxLength = freezed,Object? mobileMinLength = freezed,Object? mobileMaxLength = freezed,Object? groupSizes = freezed,Object? mobilePrefixes = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String?,dialCode: freezed == dialCode ? _self.dialCode : dialCode // ignore: cast_nullable_to_non_nullable
as String?,minLength: freezed == minLength ? _self.minLength : minLength // ignore: cast_nullable_to_non_nullable
as int?,maxLength: freezed == maxLength ? _self.maxLength : maxLength // ignore: cast_nullable_to_non_nullable
as int?,mobileMinLength: freezed == mobileMinLength ? _self.mobileMinLength : mobileMinLength // ignore: cast_nullable_to_non_nullable
as int?,mobileMaxLength: freezed == mobileMaxLength ? _self.mobileMaxLength : mobileMaxLength // ignore: cast_nullable_to_non_nullable
as int?,groupSizes: freezed == groupSizes ? _self.groupSizes : groupSizes // ignore: cast_nullable_to_non_nullable
as List<int>?,mobilePrefixes: freezed == mobilePrefixes ? _self.mobilePrefixes : mobilePrefixes // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [CountryCode].
extension CountryCodePatterns on CountryCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CountryCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CountryCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CountryCode value)  $default,){
final _that = this;
switch (_that) {
case _CountryCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CountryCode value)?  $default,){
final _that = this;
switch (_that) {
case _CountryCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String? name,  String? flag,  String? dialCode,  int? minLength,  int? maxLength,  int? mobileMinLength,  int? mobileMaxLength,  List<int>? groupSizes,  List<String>? mobilePrefixes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CountryCode() when $default != null:
return $default(_that.code,_that.name,_that.flag,_that.dialCode,_that.minLength,_that.maxLength,_that.mobileMinLength,_that.mobileMaxLength,_that.groupSizes,_that.mobilePrefixes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String? name,  String? flag,  String? dialCode,  int? minLength,  int? maxLength,  int? mobileMinLength,  int? mobileMaxLength,  List<int>? groupSizes,  List<String>? mobilePrefixes)  $default,) {final _that = this;
switch (_that) {
case _CountryCode():
return $default(_that.code,_that.name,_that.flag,_that.dialCode,_that.minLength,_that.maxLength,_that.mobileMinLength,_that.mobileMaxLength,_that.groupSizes,_that.mobilePrefixes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String? name,  String? flag,  String? dialCode,  int? minLength,  int? maxLength,  int? mobileMinLength,  int? mobileMaxLength,  List<int>? groupSizes,  List<String>? mobilePrefixes)?  $default,) {final _that = this;
switch (_that) {
case _CountryCode() when $default != null:
return $default(_that.code,_that.name,_that.flag,_that.dialCode,_that.minLength,_that.maxLength,_that.mobileMinLength,_that.mobileMaxLength,_that.groupSizes,_that.mobilePrefixes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CountryCode implements CountryCode {
  const _CountryCode({required this.code, this.name, this.flag, this.dialCode, this.minLength, this.maxLength, this.mobileMinLength, this.mobileMaxLength, final  List<int>? groupSizes, final  List<String>? mobilePrefixes}): _groupSizes = groupSizes,_mobilePrefixes = mobilePrefixes;
  factory _CountryCode.fromJson(Map<String, dynamic> json) => _$CountryCodeFromJson(json);

@override final  String code;
@override final  String? name;
@override final  String? flag;
@override final  String? dialCode;
@override final  int? minLength;
@override final  int? maxLength;
@override final  int? mobileMinLength;
@override final  int? mobileMaxLength;
 final  List<int>? _groupSizes;
@override List<int>? get groupSizes {
  final value = _groupSizes;
  if (value == null) return null;
  if (_groupSizes is EqualUnmodifiableListView) return _groupSizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _mobilePrefixes;
@override List<String>? get mobilePrefixes {
  final value = _mobilePrefixes;
  if (value == null) return null;
  if (_mobilePrefixes is EqualUnmodifiableListView) return _mobilePrefixes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of CountryCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CountryCodeCopyWith<_CountryCode> get copyWith => __$CountryCodeCopyWithImpl<_CountryCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CountryCodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CountryCode&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.flag, flag) || other.flag == flag)&&(identical(other.dialCode, dialCode) || other.dialCode == dialCode)&&(identical(other.minLength, minLength) || other.minLength == minLength)&&(identical(other.maxLength, maxLength) || other.maxLength == maxLength)&&(identical(other.mobileMinLength, mobileMinLength) || other.mobileMinLength == mobileMinLength)&&(identical(other.mobileMaxLength, mobileMaxLength) || other.mobileMaxLength == mobileMaxLength)&&const DeepCollectionEquality().equals(other._groupSizes, _groupSizes)&&const DeepCollectionEquality().equals(other._mobilePrefixes, _mobilePrefixes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,name,flag,dialCode,minLength,maxLength,mobileMinLength,mobileMaxLength,const DeepCollectionEquality().hash(_groupSizes),const DeepCollectionEquality().hash(_mobilePrefixes));

@override
String toString() {
  return 'CountryCode(code: $code, name: $name, flag: $flag, dialCode: $dialCode, minLength: $minLength, maxLength: $maxLength, mobileMinLength: $mobileMinLength, mobileMaxLength: $mobileMaxLength, groupSizes: $groupSizes, mobilePrefixes: $mobilePrefixes)';
}


}

/// @nodoc
abstract mixin class _$CountryCodeCopyWith<$Res> implements $CountryCodeCopyWith<$Res> {
  factory _$CountryCodeCopyWith(_CountryCode value, $Res Function(_CountryCode) _then) = __$CountryCodeCopyWithImpl;
@override @useResult
$Res call({
 String code, String? name, String? flag, String? dialCode, int? minLength, int? maxLength, int? mobileMinLength, int? mobileMaxLength, List<int>? groupSizes, List<String>? mobilePrefixes
});




}
/// @nodoc
class __$CountryCodeCopyWithImpl<$Res>
    implements _$CountryCodeCopyWith<$Res> {
  __$CountryCodeCopyWithImpl(this._self, this._then);

  final _CountryCode _self;
  final $Res Function(_CountryCode) _then;

/// Create a copy of CountryCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? name = freezed,Object? flag = freezed,Object? dialCode = freezed,Object? minLength = freezed,Object? maxLength = freezed,Object? mobileMinLength = freezed,Object? mobileMaxLength = freezed,Object? groupSizes = freezed,Object? mobilePrefixes = freezed,}) {
  return _then(_CountryCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,flag: freezed == flag ? _self.flag : flag // ignore: cast_nullable_to_non_nullable
as String?,dialCode: freezed == dialCode ? _self.dialCode : dialCode // ignore: cast_nullable_to_non_nullable
as String?,minLength: freezed == minLength ? _self.minLength : minLength // ignore: cast_nullable_to_non_nullable
as int?,maxLength: freezed == maxLength ? _self.maxLength : maxLength // ignore: cast_nullable_to_non_nullable
as int?,mobileMinLength: freezed == mobileMinLength ? _self.mobileMinLength : mobileMinLength // ignore: cast_nullable_to_non_nullable
as int?,mobileMaxLength: freezed == mobileMaxLength ? _self.mobileMaxLength : mobileMaxLength // ignore: cast_nullable_to_non_nullable
as int?,groupSizes: freezed == groupSizes ? _self._groupSizes : groupSizes // ignore: cast_nullable_to_non_nullable
as List<int>?,mobilePrefixes: freezed == mobilePrefixes ? _self._mobilePrefixes : mobilePrefixes // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
