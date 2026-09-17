// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Order {

/// Order id — the `{order}` of `/api/shop/orders/{order}`. This is
/// the human-facing order number the CMS emails about.
 int get id;/// Lifecycle state. Decoded non-throwing; unknown wire values
/// become [OrderStatus.unknown].
@JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire) OrderStatus get status;// ---- money: all decimal strings ----
/// Line items before delivery, discount, VAT and wallet.
 String get subtotal;/// Taken off by [discountCode]. `"0.00"` when none.
 String get discountAmount;/// The promo code applied at checkout, null when none was used.
 String? get discountCode;/// What the order costs. VAT-INCLUSIVE — never add [vatAmount].
 String get totalPrice;/// VAT percentage as a decimal string (`"0.00"` in the live data —
/// VAT is currently switched off, which is not the same as absent).
 String? get vatRate;/// VAT already contained in [totalPrice]. Display only.
 String? get vatAmount;/// Wallet credit consumed at checkout. Refunded if the order is
/// cancelled.
 String get walletApplied;/// [totalPrice] minus [walletApplied] — what the pay call charges.
 String get amountDue;/// `"unpaid"` is the only value observed live. Left as a String
/// rather than an enum because no capture shows the paid or
/// refunded spelling, and guessing an enum here would be fiction.
 String? get paymentStatus;/// Deadline for paying an `awaiting_payment` order. Full ISO-8601
/// with offset. See the class doc.
 DateTime? get paymentExpiresAt;/// What actually came back when the order was cancelled.
///
/// **`null` is not zero.** The server distinguishes "nothing was
/// ever paid, so there is nothing to refund" (null, an abandoned
/// `awaiting_payment` hold) from "the refund was `0.00`" — so show
/// this number or say nothing, and never compute what a customer
/// gets back from [totalPrice] or [walletApplied].
///
/// A decimal STRING like every other money field.
 String? get refundedAmount;// ---- delivery ----
/// Shipping charge folded into [totalPrice]. Decimal string.
 String? get deliveryFee;/// Human-readable zone the fee was priced for (`"Riyadh"`).
 String? get deliveryZone;/// Drop-off latitude as a decimal STRING (`"24.7136000"`) — the API
/// sends coordinates as strings, not numbers. `double.parse` it
/// only at the point you hand it to a map.
 String get deliveryLat;/// Drop-off longitude as a decimal string (`"46.6753000"`).
 String get deliveryLng;/// Contact number for the courier, E.164 (`"+966500000000"`).
 String get deliveryPhone;/// The readable address line, as the address book supplied it.
 String? get deliveryAddress;/// Saudi National Address short code. Null in every capture — the
/// customer had not set one.
 String? get deliveryShortAddress;/// Free-text note for the courier (`"blue door"`), null when the
/// customer left it empty.
 String? get deliveryNotes;// ---- lifecycle ----
/// Whether the API will accept `DELETE /api/shop/orders/{order}`
/// right now. Authoritative — do not second-guess it from
/// [status].
 bool get canCancel;/// When the order was placed. Full ISO-8601 with offset.
 DateTime get createdAt;/// When it was cancelled, null while it has not been.
 DateTime? get cancelledAt;/// The ordered lines. An order always has at least one.
 List<OrderItem> get items;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentExpiresAt, paymentExpiresAt) || other.paymentExpiresAt == paymentExpiresAt)&&(identical(other.refundedAmount, refundedAmount) || other.refundedAmount == refundedAmount)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.deliveryLat, deliveryLat) || other.deliveryLat == deliveryLat)&&(identical(other.deliveryLng, deliveryLng) || other.deliveryLng == deliveryLng)&&(identical(other.deliveryPhone, deliveryPhone) || other.deliveryPhone == deliveryPhone)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryShortAddress, deliveryShortAddress) || other.deliveryShortAddress == deliveryShortAddress)&&(identical(other.deliveryNotes, deliveryNotes) || other.deliveryNotes == deliveryNotes)&&(identical(other.canCancel, canCancel) || other.canCancel == canCancel)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,subtotal,discountAmount,discountCode,totalPrice,vatRate,vatAmount,walletApplied,amountDue,paymentStatus,paymentExpiresAt,refundedAmount,deliveryFee,deliveryZone,deliveryLat,deliveryLng,deliveryPhone,deliveryAddress,deliveryShortAddress,deliveryNotes,canCancel,createdAt,cancelledAt,const DeepCollectionEquality().hash(items)]);

@override
String toString() {
  return 'Order(id: $id, status: $status, subtotal: $subtotal, discountAmount: $discountAmount, discountCode: $discountCode, totalPrice: $totalPrice, vatRate: $vatRate, vatAmount: $vatAmount, walletApplied: $walletApplied, amountDue: $amountDue, paymentStatus: $paymentStatus, paymentExpiresAt: $paymentExpiresAt, refundedAmount: $refundedAmount, deliveryFee: $deliveryFee, deliveryZone: $deliveryZone, deliveryLat: $deliveryLat, deliveryLng: $deliveryLng, deliveryPhone: $deliveryPhone, deliveryAddress: $deliveryAddress, deliveryShortAddress: $deliveryShortAddress, deliveryNotes: $deliveryNotes, canCancel: $canCancel, createdAt: $createdAt, cancelledAt: $cancelledAt, items: $items)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire) OrderStatus status, String subtotal, String discountAmount, String? discountCode, String totalPrice, String? vatRate, String? vatAmount, String walletApplied, String amountDue, String? paymentStatus, DateTime? paymentExpiresAt, String? refundedAmount, String? deliveryFee, String? deliveryZone, String deliveryLat, String deliveryLng, String deliveryPhone, String? deliveryAddress, String? deliveryShortAddress, String? deliveryNotes, bool canCancel, DateTime createdAt, DateTime? cancelledAt, List<OrderItem> items
});




}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? subtotal = null,Object? discountAmount = null,Object? discountCode = freezed,Object? totalPrice = null,Object? vatRate = freezed,Object? vatAmount = freezed,Object? walletApplied = null,Object? amountDue = null,Object? paymentStatus = freezed,Object? paymentExpiresAt = freezed,Object? refundedAmount = freezed,Object? deliveryFee = freezed,Object? deliveryZone = freezed,Object? deliveryLat = null,Object? deliveryLng = null,Object? deliveryPhone = null,Object? deliveryAddress = freezed,Object? deliveryShortAddress = freezed,Object? deliveryNotes = freezed,Object? canCancel = null,Object? createdAt = null,Object? cancelledAt = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as String?,vatAmount: freezed == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as String?,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,paymentExpiresAt: freezed == paymentExpiresAt ? _self.paymentExpiresAt : paymentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundedAmount: freezed == refundedAmount ? _self.refundedAmount : refundedAmount // ignore: cast_nullable_to_non_nullable
as String?,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String?,deliveryZone: freezed == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String?,deliveryLat: null == deliveryLat ? _self.deliveryLat : deliveryLat // ignore: cast_nullable_to_non_nullable
as String,deliveryLng: null == deliveryLng ? _self.deliveryLng : deliveryLng // ignore: cast_nullable_to_non_nullable
as String,deliveryPhone: null == deliveryPhone ? _self.deliveryPhone : deliveryPhone // ignore: cast_nullable_to_non_nullable
as String,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryShortAddress: freezed == deliveryShortAddress ? _self.deliveryShortAddress : deliveryShortAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryNotes: freezed == deliveryNotes ? _self.deliveryNotes : deliveryNotes // ignore: cast_nullable_to_non_nullable
as String?,canCancel: null == canCancel ? _self.canCancel : canCancel // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire)  OrderStatus status,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String? vatRate,  String? vatAmount,  String walletApplied,  String amountDue,  String? paymentStatus,  DateTime? paymentExpiresAt,  String? refundedAmount,  String? deliveryFee,  String? deliveryZone,  String deliveryLat,  String deliveryLng,  String deliveryPhone,  String? deliveryAddress,  String? deliveryShortAddress,  String? deliveryNotes,  bool canCancel,  DateTime createdAt,  DateTime? cancelledAt,  List<OrderItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.status,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.vatRate,_that.vatAmount,_that.walletApplied,_that.amountDue,_that.paymentStatus,_that.paymentExpiresAt,_that.refundedAmount,_that.deliveryFee,_that.deliveryZone,_that.deliveryLat,_that.deliveryLng,_that.deliveryPhone,_that.deliveryAddress,_that.deliveryShortAddress,_that.deliveryNotes,_that.canCancel,_that.createdAt,_that.cancelledAt,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire)  OrderStatus status,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String? vatRate,  String? vatAmount,  String walletApplied,  String amountDue,  String? paymentStatus,  DateTime? paymentExpiresAt,  String? refundedAmount,  String? deliveryFee,  String? deliveryZone,  String deliveryLat,  String deliveryLng,  String deliveryPhone,  String? deliveryAddress,  String? deliveryShortAddress,  String? deliveryNotes,  bool canCancel,  DateTime createdAt,  DateTime? cancelledAt,  List<OrderItem> items)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.status,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.vatRate,_that.vatAmount,_that.walletApplied,_that.amountDue,_that.paymentStatus,_that.paymentExpiresAt,_that.refundedAmount,_that.deliveryFee,_that.deliveryZone,_that.deliveryLat,_that.deliveryLng,_that.deliveryPhone,_that.deliveryAddress,_that.deliveryShortAddress,_that.deliveryNotes,_that.canCancel,_that.createdAt,_that.cancelledAt,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire)  OrderStatus status,  String subtotal,  String discountAmount,  String? discountCode,  String totalPrice,  String? vatRate,  String? vatAmount,  String walletApplied,  String amountDue,  String? paymentStatus,  DateTime? paymentExpiresAt,  String? refundedAmount,  String? deliveryFee,  String? deliveryZone,  String deliveryLat,  String deliveryLng,  String deliveryPhone,  String? deliveryAddress,  String? deliveryShortAddress,  String? deliveryNotes,  bool canCancel,  DateTime createdAt,  DateTime? cancelledAt,  List<OrderItem> items)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.status,_that.subtotal,_that.discountAmount,_that.discountCode,_that.totalPrice,_that.vatRate,_that.vatAmount,_that.walletApplied,_that.amountDue,_that.paymentStatus,_that.paymentExpiresAt,_that.refundedAmount,_that.deliveryFee,_that.deliveryZone,_that.deliveryLat,_that.deliveryLng,_that.deliveryPhone,_that.deliveryAddress,_that.deliveryShortAddress,_that.deliveryNotes,_that.canCancel,_that.createdAt,_that.cancelledAt,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order extends Order {
  const _Order({required this.id, @JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire) required this.status, required this.subtotal, required this.discountAmount, this.discountCode, required this.totalPrice, this.vatRate, this.vatAmount, required this.walletApplied, required this.amountDue, this.paymentStatus, this.paymentExpiresAt, this.refundedAmount, this.deliveryFee, this.deliveryZone, required this.deliveryLat, required this.deliveryLng, required this.deliveryPhone, this.deliveryAddress, this.deliveryShortAddress, this.deliveryNotes, required this.canCancel, required this.createdAt, this.cancelledAt, required final  List<OrderItem> items}): _items = items,super._();
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

/// Order id — the `{order}` of `/api/shop/orders/{order}`. This is
/// the human-facing order number the CMS emails about.
@override final  int id;
/// Lifecycle state. Decoded non-throwing; unknown wire values
/// become [OrderStatus.unknown].
@override@JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire) final  OrderStatus status;
// ---- money: all decimal strings ----
/// Line items before delivery, discount, VAT and wallet.
@override final  String subtotal;
/// Taken off by [discountCode]. `"0.00"` when none.
@override final  String discountAmount;
/// The promo code applied at checkout, null when none was used.
@override final  String? discountCode;
/// What the order costs. VAT-INCLUSIVE — never add [vatAmount].
@override final  String totalPrice;
/// VAT percentage as a decimal string (`"0.00"` in the live data —
/// VAT is currently switched off, which is not the same as absent).
@override final  String? vatRate;
/// VAT already contained in [totalPrice]. Display only.
@override final  String? vatAmount;
/// Wallet credit consumed at checkout. Refunded if the order is
/// cancelled.
@override final  String walletApplied;
/// [totalPrice] minus [walletApplied] — what the pay call charges.
@override final  String amountDue;
/// `"unpaid"` is the only value observed live. Left as a String
/// rather than an enum because no capture shows the paid or
/// refunded spelling, and guessing an enum here would be fiction.
@override final  String? paymentStatus;
/// Deadline for paying an `awaiting_payment` order. Full ISO-8601
/// with offset. See the class doc.
@override final  DateTime? paymentExpiresAt;
/// What actually came back when the order was cancelled.
///
/// **`null` is not zero.** The server distinguishes "nothing was
/// ever paid, so there is nothing to refund" (null, an abandoned
/// `awaiting_payment` hold) from "the refund was `0.00`" — so show
/// this number or say nothing, and never compute what a customer
/// gets back from [totalPrice] or [walletApplied].
///
/// A decimal STRING like every other money field.
@override final  String? refundedAmount;
// ---- delivery ----
/// Shipping charge folded into [totalPrice]. Decimal string.
@override final  String? deliveryFee;
/// Human-readable zone the fee was priced for (`"Riyadh"`).
@override final  String? deliveryZone;
/// Drop-off latitude as a decimal STRING (`"24.7136000"`) — the API
/// sends coordinates as strings, not numbers. `double.parse` it
/// only at the point you hand it to a map.
@override final  String deliveryLat;
/// Drop-off longitude as a decimal string (`"46.6753000"`).
@override final  String deliveryLng;
/// Contact number for the courier, E.164 (`"+966500000000"`).
@override final  String deliveryPhone;
/// The readable address line, as the address book supplied it.
@override final  String? deliveryAddress;
/// Saudi National Address short code. Null in every capture — the
/// customer had not set one.
@override final  String? deliveryShortAddress;
/// Free-text note for the courier (`"blue door"`), null when the
/// customer left it empty.
@override final  String? deliveryNotes;
// ---- lifecycle ----
/// Whether the API will accept `DELETE /api/shop/orders/{order}`
/// right now. Authoritative — do not second-guess it from
/// [status].
@override final  bool canCancel;
/// When the order was placed. Full ISO-8601 with offset.
@override final  DateTime createdAt;
/// When it was cancelled, null while it has not been.
@override final  DateTime? cancelledAt;
/// The ordered lines. An order always has at least one.
 final  List<OrderItem> _items;
/// The ordered lines. An order always has at least one.
@override List<OrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.discountAmount, discountAmount) || other.discountAmount == discountAmount)&&(identical(other.discountCode, discountCode) || other.discountCode == discountCode)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.vatRate, vatRate) || other.vatRate == vatRate)&&(identical(other.vatAmount, vatAmount) || other.vatAmount == vatAmount)&&(identical(other.walletApplied, walletApplied) || other.walletApplied == walletApplied)&&(identical(other.amountDue, amountDue) || other.amountDue == amountDue)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentExpiresAt, paymentExpiresAt) || other.paymentExpiresAt == paymentExpiresAt)&&(identical(other.refundedAmount, refundedAmount) || other.refundedAmount == refundedAmount)&&(identical(other.deliveryFee, deliveryFee) || other.deliveryFee == deliveryFee)&&(identical(other.deliveryZone, deliveryZone) || other.deliveryZone == deliveryZone)&&(identical(other.deliveryLat, deliveryLat) || other.deliveryLat == deliveryLat)&&(identical(other.deliveryLng, deliveryLng) || other.deliveryLng == deliveryLng)&&(identical(other.deliveryPhone, deliveryPhone) || other.deliveryPhone == deliveryPhone)&&(identical(other.deliveryAddress, deliveryAddress) || other.deliveryAddress == deliveryAddress)&&(identical(other.deliveryShortAddress, deliveryShortAddress) || other.deliveryShortAddress == deliveryShortAddress)&&(identical(other.deliveryNotes, deliveryNotes) || other.deliveryNotes == deliveryNotes)&&(identical(other.canCancel, canCancel) || other.canCancel == canCancel)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.cancelledAt, cancelledAt) || other.cancelledAt == cancelledAt)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,subtotal,discountAmount,discountCode,totalPrice,vatRate,vatAmount,walletApplied,amountDue,paymentStatus,paymentExpiresAt,refundedAmount,deliveryFee,deliveryZone,deliveryLat,deliveryLng,deliveryPhone,deliveryAddress,deliveryShortAddress,deliveryNotes,canCancel,createdAt,cancelledAt,const DeepCollectionEquality().hash(_items)]);

@override
String toString() {
  return 'Order(id: $id, status: $status, subtotal: $subtotal, discountAmount: $discountAmount, discountCode: $discountCode, totalPrice: $totalPrice, vatRate: $vatRate, vatAmount: $vatAmount, walletApplied: $walletApplied, amountDue: $amountDue, paymentStatus: $paymentStatus, paymentExpiresAt: $paymentExpiresAt, refundedAmount: $refundedAmount, deliveryFee: $deliveryFee, deliveryZone: $deliveryZone, deliveryLat: $deliveryLat, deliveryLng: $deliveryLng, deliveryPhone: $deliveryPhone, deliveryAddress: $deliveryAddress, deliveryShortAddress: $deliveryShortAddress, deliveryNotes: $deliveryNotes, canCancel: $canCancel, createdAt: $createdAt, cancelledAt: $cancelledAt, items: $items)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire) OrderStatus status, String subtotal, String discountAmount, String? discountCode, String totalPrice, String? vatRate, String? vatAmount, String walletApplied, String amountDue, String? paymentStatus, DateTime? paymentExpiresAt, String? refundedAmount, String? deliveryFee, String? deliveryZone, String deliveryLat, String deliveryLng, String deliveryPhone, String? deliveryAddress, String? deliveryShortAddress, String? deliveryNotes, bool canCancel, DateTime createdAt, DateTime? cancelledAt, List<OrderItem> items
});




}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? subtotal = null,Object? discountAmount = null,Object? discountCode = freezed,Object? totalPrice = null,Object? vatRate = freezed,Object? vatAmount = freezed,Object? walletApplied = null,Object? amountDue = null,Object? paymentStatus = freezed,Object? paymentExpiresAt = freezed,Object? refundedAmount = freezed,Object? deliveryFee = freezed,Object? deliveryZone = freezed,Object? deliveryLat = null,Object? deliveryLng = null,Object? deliveryPhone = null,Object? deliveryAddress = freezed,Object? deliveryShortAddress = freezed,Object? deliveryNotes = freezed,Object? canCancel = null,Object? createdAt = null,Object? cancelledAt = freezed,Object? items = null,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as String,discountAmount: null == discountAmount ? _self.discountAmount : discountAmount // ignore: cast_nullable_to_non_nullable
as String,discountCode: freezed == discountCode ? _self.discountCode : discountCode // ignore: cast_nullable_to_non_nullable
as String?,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as String,vatRate: freezed == vatRate ? _self.vatRate : vatRate // ignore: cast_nullable_to_non_nullable
as String?,vatAmount: freezed == vatAmount ? _self.vatAmount : vatAmount // ignore: cast_nullable_to_non_nullable
as String?,walletApplied: null == walletApplied ? _self.walletApplied : walletApplied // ignore: cast_nullable_to_non_nullable
as String,amountDue: null == amountDue ? _self.amountDue : amountDue // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: freezed == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as String?,paymentExpiresAt: freezed == paymentExpiresAt ? _self.paymentExpiresAt : paymentExpiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,refundedAmount: freezed == refundedAmount ? _self.refundedAmount : refundedAmount // ignore: cast_nullable_to_non_nullable
as String?,deliveryFee: freezed == deliveryFee ? _self.deliveryFee : deliveryFee // ignore: cast_nullable_to_non_nullable
as String?,deliveryZone: freezed == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as String?,deliveryLat: null == deliveryLat ? _self.deliveryLat : deliveryLat // ignore: cast_nullable_to_non_nullable
as String,deliveryLng: null == deliveryLng ? _self.deliveryLng : deliveryLng // ignore: cast_nullable_to_non_nullable
as String,deliveryPhone: null == deliveryPhone ? _self.deliveryPhone : deliveryPhone // ignore: cast_nullable_to_non_nullable
as String,deliveryAddress: freezed == deliveryAddress ? _self.deliveryAddress : deliveryAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryShortAddress: freezed == deliveryShortAddress ? _self.deliveryShortAddress : deliveryShortAddress // ignore: cast_nullable_to_non_nullable
as String?,deliveryNotes: freezed == deliveryNotes ? _self.deliveryNotes : deliveryNotes // ignore: cast_nullable_to_non_nullable
as String?,canCancel: null == canCancel ? _self.canCancel : canCancel // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,cancelledAt: freezed == cancelledAt ? _self.cancelledAt : cancelledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>,
  ));
}


}

// dart format on
