// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discount_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiscountCode {

/// Upper-cased by the server on save, and matched case-insensitively
/// when typed.
 String get code;/// `percent` or `fixed`. Read via [isPercent] rather than switching
/// on the string: a third kind added later must not crash a
/// shipped build.
 String get type;/// A DECIMAL STRING either way — `"10.00"` is ten percent on a
/// percent code and ten riyals on a fixed one.
 String get value;/// The ceiling on a percent code's discount. Null means none.
 String? get maxDiscount;/// What the goods have to come to before the code applies. Null
/// means any total. The server refuses below it with
/// `api.discount_code_min_total_not_met`.
 String? get minOrderTotal;/// When it stops working. Null is open-ended.
 DateTime? get endsAt;
/// Create a copy of DiscountCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscountCodeCopyWith<DiscountCode> get copyWith => _$DiscountCodeCopyWithImpl<DiscountCode>(this as DiscountCode, _$identity);

  /// Serializes this DiscountCode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscountCode&&(identical(other.code, code) || other.code == code)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.maxDiscount, maxDiscount) || other.maxDiscount == maxDiscount)&&(identical(other.minOrderTotal, minOrderTotal) || other.minOrderTotal == minOrderTotal)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,type,value,maxDiscount,minOrderTotal,endsAt);

@override
String toString() {
  return 'DiscountCode(code: $code, type: $type, value: $value, maxDiscount: $maxDiscount, minOrderTotal: $minOrderTotal, endsAt: $endsAt)';
}


}

/// @nodoc
abstract mixin class $DiscountCodeCopyWith<$Res>  {
  factory $DiscountCodeCopyWith(DiscountCode value, $Res Function(DiscountCode) _then) = _$DiscountCodeCopyWithImpl;
@useResult
$Res call({
 String code, String type, String value, String? maxDiscount, String? minOrderTotal, DateTime? endsAt
});




}
/// @nodoc
class _$DiscountCodeCopyWithImpl<$Res>
    implements $DiscountCodeCopyWith<$Res> {
  _$DiscountCodeCopyWithImpl(this._self, this._then);

  final DiscountCode _self;
  final $Res Function(DiscountCode) _then;

/// Create a copy of DiscountCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? type = null,Object? value = null,Object? maxDiscount = freezed,Object? minOrderTotal = freezed,Object? endsAt = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,maxDiscount: freezed == maxDiscount ? _self.maxDiscount : maxDiscount // ignore: cast_nullable_to_non_nullable
as String?,minOrderTotal: freezed == minOrderTotal ? _self.minOrderTotal : minOrderTotal // ignore: cast_nullable_to_non_nullable
as String?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscountCode].
extension DiscountCodePatterns on DiscountCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscountCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscountCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscountCode value)  $default,){
final _that = this;
switch (_that) {
case _DiscountCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscountCode value)?  $default,){
final _that = this;
switch (_that) {
case _DiscountCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String type,  String value,  String? maxDiscount,  String? minOrderTotal,  DateTime? endsAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscountCode() when $default != null:
return $default(_that.code,_that.type,_that.value,_that.maxDiscount,_that.minOrderTotal,_that.endsAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String type,  String value,  String? maxDiscount,  String? minOrderTotal,  DateTime? endsAt)  $default,) {final _that = this;
switch (_that) {
case _DiscountCode():
return $default(_that.code,_that.type,_that.value,_that.maxDiscount,_that.minOrderTotal,_that.endsAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String type,  String value,  String? maxDiscount,  String? minOrderTotal,  DateTime? endsAt)?  $default,) {final _that = this;
switch (_that) {
case _DiscountCode() when $default != null:
return $default(_that.code,_that.type,_that.value,_that.maxDiscount,_that.minOrderTotal,_that.endsAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiscountCode extends DiscountCode {
  const _DiscountCode({required this.code, required this.type, required this.value, this.maxDiscount, this.minOrderTotal, this.endsAt}): super._();
  factory _DiscountCode.fromJson(Map<String, dynamic> json) => _$DiscountCodeFromJson(json);

/// Upper-cased by the server on save, and matched case-insensitively
/// when typed.
@override final  String code;
/// `percent` or `fixed`. Read via [isPercent] rather than switching
/// on the string: a third kind added later must not crash a
/// shipped build.
@override final  String type;
/// A DECIMAL STRING either way — `"10.00"` is ten percent on a
/// percent code and ten riyals on a fixed one.
@override final  String value;
/// The ceiling on a percent code's discount. Null means none.
@override final  String? maxDiscount;
/// What the goods have to come to before the code applies. Null
/// means any total. The server refuses below it with
/// `api.discount_code_min_total_not_met`.
@override final  String? minOrderTotal;
/// When it stops working. Null is open-ended.
@override final  DateTime? endsAt;

/// Create a copy of DiscountCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscountCodeCopyWith<_DiscountCode> get copyWith => __$DiscountCodeCopyWithImpl<_DiscountCode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscountCodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscountCode&&(identical(other.code, code) || other.code == code)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.maxDiscount, maxDiscount) || other.maxDiscount == maxDiscount)&&(identical(other.minOrderTotal, minOrderTotal) || other.minOrderTotal == minOrderTotal)&&(identical(other.endsAt, endsAt) || other.endsAt == endsAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,type,value,maxDiscount,minOrderTotal,endsAt);

@override
String toString() {
  return 'DiscountCode(code: $code, type: $type, value: $value, maxDiscount: $maxDiscount, minOrderTotal: $minOrderTotal, endsAt: $endsAt)';
}


}

/// @nodoc
abstract mixin class _$DiscountCodeCopyWith<$Res> implements $DiscountCodeCopyWith<$Res> {
  factory _$DiscountCodeCopyWith(_DiscountCode value, $Res Function(_DiscountCode) _then) = __$DiscountCodeCopyWithImpl;
@override @useResult
$Res call({
 String code, String type, String value, String? maxDiscount, String? minOrderTotal, DateTime? endsAt
});




}
/// @nodoc
class __$DiscountCodeCopyWithImpl<$Res>
    implements _$DiscountCodeCopyWith<$Res> {
  __$DiscountCodeCopyWithImpl(this._self, this._then);

  final _DiscountCode _self;
  final $Res Function(_DiscountCode) _then;

/// Create a copy of DiscountCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? type = null,Object? value = null,Object? maxDiscount = freezed,Object? minOrderTotal = freezed,Object? endsAt = freezed,}) {
  return _then(_DiscountCode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,maxDiscount: freezed == maxDiscount ? _self.maxDiscount : maxDiscount // ignore: cast_nullable_to_non_nullable
as String?,minOrderTotal: freezed == minOrderTotal ? _self.minOrderTotal : minOrderTotal // ignore: cast_nullable_to_non_nullable
as String?,endsAt: freezed == endsAt ? _self.endsAt : endsAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
