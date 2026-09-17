// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gift.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Gift {

/// Gift id — the `{gift}` of `POST /api/gifts/{gift}/pay`. NOT the
/// redeem key; that is [token].
 int get id;/// Who it is for, as the buyer typed it. The only field
/// `POST /api/gifts` requires.
 String get recipientName;/// Note shown on the redeem screen. Null when the buyer left it
/// empty.
 String? get message;/// Contact note for the buyer's own reference, E.164
/// (`"+966500000000"`). The API does not message it.
 String? get recipientPhone;/// Face value of the gift — what lands in the recipient's wallet.
/// Decimal string.
 String get amount;/// Purchase subtotal before discount and wallet. Decimal string.
 String get subtotal;/// Taken off by [discountCode]. `"0.00"` when none.
 String get discountAmount;/// Promo code applied at purchase, null when none was used.
 String? get discountCode;/// What the buyer was charged. Decimal string. Can be LESS than
/// [amount] when a code applied — the recipient still receives
/// [amount].
 String get totalPrice;/// Buyer's wallet credit consumed by this purchase.
 String get walletApplied;/// [totalPrice] minus [walletApplied] — what the pay call charges.
 String get amountDue;/// `"unpaid"` is the only value observed live. Kept a String
/// rather than an enum until a capture shows the other spellings.
 String? get paymentStatus;/// WHERE THE PURCHASE ITSELF GOT TO — `awaiting_payment`, `paid`
/// or `cancelled`. Not the same question as [isRedeemed], which is
/// about the CLAIM.
///
/// `cancelled` means the buyer never paid and the hold lapsed: the
/// link is dead and the gift cannot be revived, so nothing should
/// offer to share it. Arrived with `GET /api/gifts/history` on
/// 2026-09-16; read it through [isDead].
 String? get status;/// Deadline for paying an unpaid gift. Full ISO-8601 with offset.
 DateTime? get paymentExpiresAt;/// The claim secret — a UUID. Keys the redeem endpoints. Treat as
/// a credential.
 String get token;/// The shareable claim link, `.../gift/{token}`. This is what the
/// share sheet sends.
 String get shareUrl;/// Whether the gift has been claimed. Independent of payment.
 bool get isRedeemed;/// When it was claimed, null while unclaimed. Full ISO-8601.
 DateTime? get redeemedAt;/// When the gift was bought. Full ISO-8601 with offset.
 DateTime get createdAt;
/// Create a copy of Gift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftCopyWith<Gift> get copyWith => _$GiftCopyWithImpl<Gift>(this as Gift, _$identity);

  /// Serializes this Gift to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gift&&(identical(other.id, id) || other.id == id)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.message, message) || other.message == message)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentExpiresAt, paymentExpiresAt) || other.paymentExpiresAt == paymentExpiresAt)&&(identical(other.token, token) || other.token == token)&&(identical(other.shareUrl, shareUrl) || other.shareUrl == shareUrl)&&(identical(other.isRedeemed, isRedeemed) || other.isRedeemed == isRedeemed)&&(identical(other.redeemedAt, redeemedAt) || other.redeemedAt == redeemedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,recipientName,message,recipientPhone,amount,subtotal,discountAmount,discountCode,totalPrice,walletApplied,amountDue,paymentStatus,status,paymentExpiresAt,token,shareUrl,isRedeemed,redeemedAt,createdAt]);

@override
String toString() {
  return 'Gift(id: $id, recipientName: $recipientName, message: $message, recipientPhone: $recipientPhone, amount: $amount, subtotal: $subtotal, discountAmount: $discountAmount, discountCode: $discountCode, totalPrice: $totalPrice, walletApplied: $walletApplied, amountDue: $amountDue, paymentStatus: $paymentStatus, status: $status, paymentExpiresAt: $paymentExpiresAt, token: $token, shareUrl: $shareUrl, isRedeemed: $isRedeemed, redeemedAt: $redeemedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GiftCopyWith<$Res>  {
  factory $GiftCopyWith(Gift value, $Res Function(Gift) _then) = _$GiftCopyWithImpl;
@useResult
$Res call({
 int id, String recipientName, String? message, String? recipientPhone, String amount, String subtotal, String discountAmount, String? discountCode, String totalPrice, String walletApplied, String amountDue, String? paymentStatus, String? status, DateTime? paymentExpiresAt, String token, String shareUrl, bool isRedeemed, DateTime? redeemedAt, DateTime createdAt
});




}
/// @nodoc
class _$GiftCopyWithImpl<$Res>
    implements $GiftCopyWith<$Res> {
  _$GiftCopyWithImpl(this._self, this._then);

  final Gift _self;
  final $Res Function(Gift) _then;

/// Create a copy of Gift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? recipientName = null,Object? message = freezed,Object? recipientPhone = freezed,Object? amount = null,Object? subtotal = null,Object? discountAmount = null,Object? discountCode = freezed,Object? totalPrice = null,Object? walletApplied = null,Object? amountDue = null,Object? paymentStatus = freezed,Object? status = freezed,Object? paymentExpiresAt = freezed,Object? token = null,Object? shareUrl = null,Object? isRedeemed = null,Object? redeemedAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,paymentExpiresAt: freezed == paymentExpiresAt ? _self.paymentExpiresAt : paymentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,shareUrl: null == shareUrl ? _self.shareUrl : shareUrl // ignore: cast_nullable_to_non_nullable
as String,isRedeemed: null == isRedeemed ? _self.isRedeemed : isRedeemed // ignore: cast_nullable_to_non_nullable
as bool,redeemedAt: freezed == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Gift].
extension GiftPatterns on Gift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Gift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Gift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Gift value)  $default,){
final _that = this;
switch (_that) {
case _Gift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Gift value)?  $default,){
final _that = this;
switch (_that) {
case _Gift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String recipientName,  String? message,  String? recipientPhone,  String amount,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String walletApplied,  String amountDue,  String? paymentStatus,  String? status,  DateTime? paymentExpiresAt,  String token,  String shareUrl,  bool isRedeemed,  DateTime? redeemedAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Gift() when $default != null:
return $default(_that.id,_that.recipientName,_that.message,_that.recipientPhone,_that.amount,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.walletApplied,_that.amountDue,_that.paymentStatus,_that.status,_that.paymentExpiresAt,_that.token,_that.shareUrl,_that.isRedeemed,_that.redeemedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String recipientName,  String? message,  String? recipientPhone,  String amount,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String walletApplied,  String amountDue,  String? paymentStatus,  String? status,  DateTime? paymentExpiresAt,  String token,  String shareUrl,  bool isRedeemed,  DateTime? redeemedAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Gift():
return $default(_that.id,_that.recipientName,_that.message,_that.recipientPhone,_that.amount,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.walletApplied,_that.amountDue,_that.paymentStatus,_that.status,_that.paymentExpiresAt,_that.token,_that.shareUrl,_that.isRedeemed,_that.redeemedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String recipientName,  String? message,  String? recipientPhone,  String amount,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String walletApplied,  String amountDue,  String? paymentStatus,  String? status,  DateTime? paymentExpiresAt,  String token,  String shareUrl,  bool isRedeemed,  DateTime? redeemedAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Gift() when $default != null:
return $default(_that.id,_that.recipientName,_that.message,_that.recipientPhone,_that.amount,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.walletApplied,_that.amountDue,_that.paymentStatus,_that.status,_that.paymentExpiresAt,_that.token,_that.shareUrl,_that.isRedeemed,_that.redeemedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Gift extends Gift {
  const _Gift({required this.id, required this.recipientName, this.message, this.recipientPhone, required this.amount, required this.subtotal, required this.discountAmount, this.discountCode, required this.totalPrice, required this.walletApplied, required this.amountDue, this.paymentStatus, this.status, this.paymentExpiresAt, required this.token, required this.shareUrl, required this.isRedeemed, this.redeemedAt, required this.createdAt}): super._();
  factory _Gift.fromJson(Map<String, dynamic> json) => _$GiftFromJson(json);

/// Gift id — the `{gift}` of `POST /api/gifts/{gift}/pay`. NOT the
/// redeem key; that is [token].
@override final  int id;
/// Who it is for, as the buyer typed it. The only field
/// `POST /api/gifts` requires.
@override final  String recipientName;
/// Note shown on the redeem screen. Null when the buyer left it
/// empty.
@override final  String? message;
/// Contact note for the buyer's own reference, E.164
/// (`"+966500000000"`). The API does not message it.
@override final  String? recipientPhone;
/// Face value of the gift — what lands in the recipient's wallet.
/// Decimal string.
@override final  String amount;
/// Purchase subtotal before discount and wallet. Decimal string.
@override final  String subtotal;
/// Taken off by [discountCode]. `"0.00"` when none.
@override final  String discountAmount;
/// Promo code applied at purchase, null when none was used.
@override final  String? discountCode;
/// What the buyer was charged. Decimal string. Can be LESS than
/// [amount] when a code applied — the recipient still receives
/// [amount].
@override final  String totalPrice;
/// Buyer's wallet credit consumed by this purchase.
@override final  String walletApplied;
/// [totalPrice] minus [walletApplied] — what the pay call charges.
@override final  String amountDue;
/// `"unpaid"` is the only value observed live. Kept a String
/// rather than an enum until a capture shows the other spellings.
@override final  String? paymentStatus;
/// WHERE THE PURCHASE ITSELF GOT TO — `awaiting_payment`, `paid`
/// or `cancelled`. Not the same question as [isRedeemed], which is
/// about the CLAIM.
///
/// `cancelled` means the buyer never paid and the hold lapsed: the
/// link is dead and the gift cannot be revived, so nothing should
/// offer to share it. Arrived with `GET /api/gifts/history` on
/// 2026-09-16; read it through [isDead].
@override final  String? status;
/// Deadline for paying an unpaid gift. Full ISO-8601 with offset.
@override final  DateTime? paymentExpiresAt;
/// The claim secret — a UUID. Keys the redeem endpoints. Treat as
/// a credential.
@override final  String token;
/// The shareable claim link, `.../gift/{token}`. This is what the
/// share sheet sends.
@override final  String shareUrl;
/// Whether the gift has been claimed. Independent of payment.
@override final  bool isRedeemed;
/// When it was claimed, null while unclaimed. Full ISO-8601.
@override final  DateTime? redeemedAt;
/// When the gift was bought. Full ISO-8601 with offset.
@override final  DateTime createdAt;

/// Create a copy of Gift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftCopyWith<_Gift> get copyWith => __$GiftCopyWithImpl<_Gift>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Gift&&(identical(other.id, id) || other.id == id)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.message, message) || other.message == message)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentExpiresAt, paymentExpiresAt) || other.paymentExpiresAt == paymentExpiresAt)&&(identical(other.token, token) || other.token == token)&&(identical(other.shareUrl, shareUrl) || other.shareUrl == shareUrl)&&(identical(other.isRedeemed, isRedeemed) || other.isRedeemed == isRedeemed)&&(identical(other.redeemedAt, redeemedAt) || other.redeemedAt == redeemedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,recipientName,message,recipientPhone,amount,subtotal,discountAmount,discountCode,totalPrice,walletApplied,amountDue,paymentStatus,status,paymentExpiresAt,token,shareUrl,isRedeemed,redeemedAt,createdAt]);

@override
String toString() {
  return 'Gift(id: $id, recipientName: $recipientName, message: $message, recipientPhone: $recipientPhone, amount: $amount, subtotal: $subtotal, discountAmount: $discountAmount, discountCode: $discountCode, totalPrice: $totalPrice, walletApplied: $walletApplied, amountDue: $amountDue, paymentStatus: $paymentStatus, status: $status, paymentExpiresAt: $paymentExpiresAt, token: $token, shareUrl: $shareUrl, isRedeemed: $isRedeemed, redeemedAt: $redeemedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GiftCopyWith<$Res> implements $GiftCopyWith<$Res> {
  factory _$GiftCopyWith(_Gift value, $Res Function(_Gift) _then) = __$GiftCopyWithImpl;
@override @useResult
$Res call({
 int id, String recipientName, String? message, String? recipientPhone, String amount, String subtotal, String discountAmount, String? discountCode, String totalPrice, String walletApplied, String amountDue, String? paymentStatus, String? status, DateTime? paymentExpiresAt, String token, String shareUrl, bool isRedeemed, DateTime? redeemedAt, DateTime createdAt
});




}
/// @nodoc
class __$GiftCopyWithImpl<$Res>
    implements _$GiftCopyWith<$Res> {
  __$GiftCopyWithImpl(this._self, this._then);

  final _Gift _self;
  final $Res Function(_Gift) _then;

/// Create a copy of Gift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? recipientName = null,Object? message = freezed,Object? recipientPhone = freezed,Object? amount = null,Object? subtotal = null,Object? discountAmount = null,Object? discountCode = freezed,Object? totalPrice = null,Object? walletApplied = null,Object? amountDue = null,Object? paymentStatus = freezed,Object? status = freezed,Object? paymentExpiresAt = freezed,Object? token = null,Object? shareUrl = null,Object? isRedeemed = null,Object? redeemedAt = freezed,Object? createdAt = null,}) {
  return _then(_Gift(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,recipientName: null == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,paymentExpiresAt: freezed == paymentExpiresAt ? _self.paymentExpiresAt : paymentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,shareUrl: null == shareUrl ? _self.shareUrl : shareUrl // ignore: cast_nullable_to_non_nullable
as String,isRedeemed: null == isRedeemed ? _self.isRedeemed : isRedeemed // ignore: cast_nullable_to_non_nullable
as bool,redeemedAt: freezed == redeemedAt ? _self.redeemedAt : redeemedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
