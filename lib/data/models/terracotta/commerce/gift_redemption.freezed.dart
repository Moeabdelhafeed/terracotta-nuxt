// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gift_redemption.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GiftRedemption {

/// What the gift was worth, as a decimal string.
 String get amount;/// The wallet AFTER the credit landed. Decimal string.
 String get walletBalance;
/// Create a copy of GiftRedemption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftRedemptionCopyWith<GiftRedemption> get copyWith => _$GiftRedemptionCopyWithImpl<GiftRedemption>(this as GiftRedemption, _$identity);

  /// Serializes this GiftRedemption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftRedemption&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,walletBalance);

@override
String toString() {
  return 'GiftRedemption(amount: $amount, walletBalance: $walletBalance)';
}


}

/// @nodoc
abstract mixin class $GiftRedemptionCopyWith<$Res>  {
  factory $GiftRedemptionCopyWith(GiftRedemption value, $Res Function(GiftRedemption) _then) = _$GiftRedemptionCopyWithImpl;
@useResult
$Res call({
 String amount, String walletBalance
});




}
/// @nodoc
class _$GiftRedemptionCopyWithImpl<$Res>
    implements $GiftRedemptionCopyWith<$Res> {
  _$GiftRedemptionCopyWithImpl(this._self, this._then);

  final GiftRedemption _self;
  final $Res Function(GiftRedemption) _then;

/// Create a copy of GiftRedemption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? walletBalance = null,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftRedemption].
extension GiftRedemptionPatterns on GiftRedemption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftRedemption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftRedemption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftRedemption value)  $default,){
final _that = this;
switch (_that) {
case _GiftRedemption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftRedemption value)?  $default,){
final _that = this;
switch (_that) {
case _GiftRedemption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String amount,  String walletBalance)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftRedemption() when $default != null:
return $default(_that.amount,_that.walletBalance);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String amount,  String walletBalance)  $default,) {final _that = this;
switch (_that) {
case _GiftRedemption():
return $default(_that.amount,_that.walletBalance);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String amount,  String walletBalance)?  $default,) {final _that = this;
switch (_that) {
case _GiftRedemption() when $default != null:
return $default(_that.amount,_that.walletBalance);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftRedemption implements GiftRedemption {
  const _GiftRedemption({required this.amount, required this.walletBalance});
  factory _GiftRedemption.fromJson(Map<String, dynamic> json) => _$GiftRedemptionFromJson(json);

/// What the gift was worth, as a decimal string.
@override final  String amount;
/// The wallet AFTER the credit landed. Decimal string.
@override final  String walletBalance;

/// Create a copy of GiftRedemption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftRedemptionCopyWith<_GiftRedemption> get copyWith => __$GiftRedemptionCopyWithImpl<_GiftRedemption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftRedemptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftRedemption&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,walletBalance);

@override
String toString() {
  return 'GiftRedemption(amount: $amount, walletBalance: $walletBalance)';
}


}

/// @nodoc
abstract mixin class _$GiftRedemptionCopyWith<$Res> implements $GiftRedemptionCopyWith<$Res> {
  factory _$GiftRedemptionCopyWith(_GiftRedemption value, $Res Function(_GiftRedemption) _then) = __$GiftRedemptionCopyWithImpl;
@override @useResult
$Res call({
 String amount, String walletBalance
});




}
/// @nodoc
class __$GiftRedemptionCopyWithImpl<$Res>
    implements _$GiftRedemptionCopyWith<$Res> {
  __$GiftRedemptionCopyWithImpl(this._self, this._then);

  final _GiftRedemption _self;
  final $Res Function(_GiftRedemption) _then;

/// Create a copy of GiftRedemption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? walletBalance = null,}) {
  return _then(_GiftRedemption(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
