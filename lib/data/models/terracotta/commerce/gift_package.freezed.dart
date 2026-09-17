// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gift_package.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GiftPackage {

/// Face value of one gift, as a decimal string (`"200.00"`).
 String get amount;/// Whether gifting is currently on offer. False = hide the flow.
 bool get isActive;
/// Create a copy of GiftPackage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftPackageCopyWith<GiftPackage> get copyWith => _$GiftPackageCopyWithImpl<GiftPackage>(this as GiftPackage, _$identity);

  /// Serializes this GiftPackage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftPackage&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,isActive);

@override
String toString() {
  return 'GiftPackage(amount: $amount, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $GiftPackageCopyWith<$Res>  {
  factory $GiftPackageCopyWith(GiftPackage value, $Res Function(GiftPackage) _then) = _$GiftPackageCopyWithImpl;
@useResult
$Res call({
 String amount, bool isActive
});




}
/// @nodoc
class _$GiftPackageCopyWithImpl<$Res>
    implements $GiftPackageCopyWith<$Res> {
  _$GiftPackageCopyWithImpl(this._self, this._then);

  final GiftPackage _self;
  final $Res Function(GiftPackage) _then;

/// Create a copy of GiftPackage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftPackage].
extension GiftPackagePatterns on GiftPackage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftPackage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftPackage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftPackage value)  $default,){
final _that = this;
switch (_that) {
case _GiftPackage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftPackage value)?  $default,){
final _that = this;
switch (_that) {
case _GiftPackage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String amount,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftPackage() when $default != null:
return $default(_that.amount,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String amount,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _GiftPackage():
return $default(_that.amount,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String amount,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _GiftPackage() when $default != null:
return $default(_that.amount,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftPackage implements GiftPackage {
  const _GiftPackage({required this.amount, required this.isActive});
  factory _GiftPackage.fromJson(Map<String, dynamic> json) => _$GiftPackageFromJson(json);

/// Face value of one gift, as a decimal string (`"200.00"`).
@override final  String amount;
/// Whether gifting is currently on offer. False = hide the flow.
@override final  bool isActive;

/// Create a copy of GiftPackage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftPackageCopyWith<_GiftPackage> get copyWith => __$GiftPackageCopyWithImpl<_GiftPackage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftPackageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftPackage&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,isActive);

@override
String toString() {
  return 'GiftPackage(amount: $amount, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$GiftPackageCopyWith<$Res> implements $GiftPackageCopyWith<$Res> {
  factory _$GiftPackageCopyWith(_GiftPackage value, $Res Function(_GiftPackage) _then) = __$GiftPackageCopyWithImpl;
@override @useResult
$Res call({
 String amount, bool isActive
});




}
/// @nodoc
class __$GiftPackageCopyWithImpl<$Res>
    implements _$GiftPackageCopyWith<$Res> {
  __$GiftPackageCopyWithImpl(this._self, this._then);

  final _GiftPackage _self;
  final $Res Function(_GiftPackage) _then;

/// Create a copy of GiftPackage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? isActive = null,}) {
  return _then(_GiftPackage(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
