// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletTransaction {

 int get id;/// `"credit"` or `"debit"`. Read via [kind].
 String? get type;/// Absolute value moved, as a DECIMAL STRING. The direction is in
/// [type], not in a minus sign.
 String? get amount;/// Why it moved (`"delivery_fee"`, `"booking_cancelled"`). An open,
/// server-defined set — do not switch on it exhaustively.
 String? get reason;/// Booking this row settled, when it came from one.
 int? get workshopBookingId;/// Shop order this row settled, when it came from one.
 int? get shopOrderId;/// Running balance right after this row, as a DECIMAL STRING.
 String? get balanceAfter; DateTime? get createdAt;
/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletTransactionCopyWith<WalletTransaction> get copyWith => _$WalletTransactionCopyWithImpl<WalletTransaction>(this as WalletTransaction, _$identity);

  /// Serializes this WalletTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.workshopBookingId, workshopBookingId) || other.workshopBookingId == workshopBookingId)&&(identical(other.shopOrderId, shopOrderId) || other.shopOrderId == shopOrderId)&&(identical(other.balanceAfter, balanceAfter) || other.balanceAfter == balanceAfter)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,amount,reason,workshopBookingId,shopOrderId,balanceAfter,createdAt);

@override
String toString() {
  return 'WalletTransaction(id: $id, type: $type, amount: $amount, reason: $reason, workshopBookingId: $workshopBookingId, shopOrderId: $shopOrderId, balanceAfter: $balanceAfter, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WalletTransactionCopyWith<$Res>  {
  factory $WalletTransactionCopyWith(WalletTransaction value, $Res Function(WalletTransaction) _then) = _$WalletTransactionCopyWithImpl;
@useResult
$Res call({
 int id, String? type, String? amount, String? reason, int? workshopBookingId, int? shopOrderId, String? balanceAfter, DateTime? createdAt
});




}
/// @nodoc
class _$WalletTransactionCopyWithImpl<$Res>
    implements $WalletTransactionCopyWith<$Res> {
  _$WalletTransactionCopyWithImpl(this._self, this._then);

  final WalletTransaction _self;
  final $Res Function(WalletTransaction) _then;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = freezed,Object? amount = freezed,Object? reason = freezed,Object? workshopBookingId = freezed,Object? shopOrderId = freezed,Object? balanceAfter = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,workshopBookingId: freezed == workshopBookingId ? _self.workshopBookingId : workshopBookingId // ignore: cast_nullable_to_non_nullable
as int?,shopOrderId: freezed == shopOrderId ? _self.shopOrderId : shopOrderId // ignore: cast_nullable_to_non_nullable
as int?,balanceAfter: freezed == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletTransaction].
extension WalletTransactionPatterns on WalletTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletTransaction value)  $default,){
final _that = this;
switch (_that) {
case _WalletTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? type,  String? amount,  String? reason,  int? workshopBookingId,  int? shopOrderId,  String? balanceAfter,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.reason,_that.workshopBookingId,_that.shopOrderId,_that.balanceAfter,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? type,  String? amount,  String? reason,  int? workshopBookingId,  int? shopOrderId,  String? balanceAfter,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _WalletTransaction():
return $default(_that.id,_that.type,_that.amount,_that.reason,_that.workshopBookingId,_that.shopOrderId,_that.balanceAfter,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? type,  String? amount,  String? reason,  int? workshopBookingId,  int? shopOrderId,  String? balanceAfter,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.reason,_that.workshopBookingId,_that.shopOrderId,_that.balanceAfter,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletTransaction extends WalletTransaction {
  const _WalletTransaction({required this.id, this.type, this.amount, this.reason, this.workshopBookingId, this.shopOrderId, this.balanceAfter, this.createdAt}): super._();
  factory _WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);

@override final  int id;
/// `"credit"` or `"debit"`. Read via [kind].
@override final  String? type;
/// Absolute value moved, as a DECIMAL STRING. The direction is in
/// [type], not in a minus sign.
@override final  String? amount;
/// Why it moved (`"delivery_fee"`, `"booking_cancelled"`). An open,
/// server-defined set — do not switch on it exhaustively.
@override final  String? reason;
/// Booking this row settled, when it came from one.
@override final  int? workshopBookingId;
/// Shop order this row settled, when it came from one.
@override final  int? shopOrderId;
/// Running balance right after this row, as a DECIMAL STRING.
@override final  String? balanceAfter;
@override final  DateTime? createdAt;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletTransactionCopyWith<_WalletTransaction> get copyWith => __$WalletTransactionCopyWithImpl<_WalletTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.workshopBookingId, workshopBookingId) || other.workshopBookingId == workshopBookingId)&&(identical(other.shopOrderId, shopOrderId) || other.shopOrderId == shopOrderId)&&(identical(other.balanceAfter, balanceAfter) || other.balanceAfter == balanceAfter)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,amount,reason,workshopBookingId,shopOrderId,balanceAfter,createdAt);

@override
String toString() {
  return 'WalletTransaction(id: $id, type: $type, amount: $amount, reason: $reason, workshopBookingId: $workshopBookingId, shopOrderId: $shopOrderId, balanceAfter: $balanceAfter, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WalletTransactionCopyWith<$Res> implements $WalletTransactionCopyWith<$Res> {
  factory _$WalletTransactionCopyWith(_WalletTransaction value, $Res Function(_WalletTransaction) _then) = __$WalletTransactionCopyWithImpl;
@override @useResult
$Res call({
 int id, String? type, String? amount, String? reason, int? workshopBookingId, int? shopOrderId, String? balanceAfter, DateTime? createdAt
});




}
/// @nodoc
class __$WalletTransactionCopyWithImpl<$Res>
    implements _$WalletTransactionCopyWith<$Res> {
  __$WalletTransactionCopyWithImpl(this._self, this._then);

  final _WalletTransaction _self;
  final $Res Function(_WalletTransaction) _then;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = freezed,Object? amount = freezed,Object? reason = freezed,Object? workshopBookingId = freezed,Object? shopOrderId = freezed,Object? balanceAfter = freezed,Object? createdAt = freezed,}) {
  return _then(_WalletTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,workshopBookingId: freezed == workshopBookingId ? _self.workshopBookingId : workshopBookingId // ignore: cast_nullable_to_non_nullable
as int?,shopOrderId: freezed == shopOrderId ? _self.shopOrderId : shopOrderId // ignore: cast_nullable_to_non_nullable
as int?,balanceAfter: freezed == balanceAfter ? _self.balanceAfter : balanceAfter // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
