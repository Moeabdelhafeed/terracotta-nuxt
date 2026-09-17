// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Order _$OrderFromJson(Map<String, dynamic> json) => _Order(
  id: (json['id'] as num).toInt(),
  status: OrderStatus.fromWire(json['status'] as String?),
  subtotal: json['subtotal'] as String,
  discountAmount: json['discount_amount'] as String,
  discountCode: json['discount_code'] as String?,
  totalPrice: json['total_price'] as String,
  vatRate: json['vat_rate'] as String?,
  vatAmount: json['vat_amount'] as String?,
  walletApplied: json['wallet_applied'] as String,
  amountDue: json['amount_due'] as String,
  paymentStatus: json['payment_status'] as String?,
  paymentExpiresAt: json['payment_expires_at'] == null
      ? null
      : DateTime.parse(json['payment_expires_at'] as String),
  refundedAmount: json['refunded_amount'] as String?,
  deliveryFee: json['delivery_fee'] as String?,
  deliveryZone: json['delivery_zone'] as String?,
  deliveryLat: json['delivery_lat'] as String,
  deliveryLng: json['delivery_lng'] as String,
  deliveryPhone: json['delivery_phone'] as String,
  deliveryAddress: json['delivery_address'] as String?,
  deliveryShortAddress: json['delivery_short_address'] as String?,
  deliveryNotes: json['delivery_notes'] as String?,
  canCancel: json['can_cancel'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  cancelledAt: json['cancelled_at'] == null
      ? null
      : DateTime.parse(json['cancelled_at'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OrderToJson(_Order instance) => <String, dynamic>{
  'id': instance.id,
  'status': OrderStatus.toWire(instance.status),
  'subtotal': instance.subtotal,
  'discount_amount': instance.discountAmount,
  'discount_code': instance.discountCode,
  'total_price': instance.totalPrice,
  'vat_rate': instance.vatRate,
  'vat_amount': instance.vatAmount,
  'wallet_applied': instance.walletApplied,
  'amount_due': instance.amountDue,
  'payment_status': instance.paymentStatus,
  'payment_expires_at': instance.paymentExpiresAt?.toIso8601String(),
  'refunded_amount': instance.refundedAmount,
  'delivery_fee': instance.deliveryFee,
  'delivery_zone': instance.deliveryZone,
  'delivery_lat': instance.deliveryLat,
  'delivery_lng': instance.deliveryLng,
  'delivery_phone': instance.deliveryPhone,
  'delivery_address': instance.deliveryAddress,
  'delivery_short_address': instance.deliveryShortAddress,
  'delivery_notes': instance.deliveryNotes,
  'can_cancel': instance.canCancel,
  'created_at': instance.createdAt.toIso8601String(),
  'cancelled_at': instance.cancelledAt?.toIso8601String(),
  'items': instance.items,
};
