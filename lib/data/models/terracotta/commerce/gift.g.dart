// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Gift _$GiftFromJson(Map<String, dynamic> json) => _Gift(
  id: (json['id'] as num).toInt(),
  recipientName: json['recipient_name'] as String,
  message: json['message'] as String?,
  recipientPhone: json['recipient_phone'] as String?,
  amount: json['amount'] as String,
  subtotal: json['subtotal'] as String,
  discountAmount: json['discount_amount'] as String,
  discountCode: json['discount_code'] as String?,
  totalPrice: json['total_price'] as String,
  walletApplied: json['wallet_applied'] as String,
  amountDue: json['amount_due'] as String,
  paymentStatus: json['payment_status'] as String?,
  status: json['status'] as String?,
  paymentExpiresAt: json['payment_expires_at'] == null
      ? null
      : DateTime.parse(json['payment_expires_at'] as String),
  token: json['token'] as String,
  shareUrl: json['share_url'] as String,
  isRedeemed: json['is_redeemed'] as bool,
  redeemedAt: json['redeemed_at'] == null
      ? null
      : DateTime.parse(json['redeemed_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$GiftToJson(_Gift instance) => <String, dynamic>{
  'id': instance.id,
  'recipient_name': instance.recipientName,
  'message': instance.message,
  'recipient_phone': instance.recipientPhone,
  'amount': instance.amount,
  'subtotal': instance.subtotal,
  'discount_amount': instance.discountAmount,
  'discount_code': instance.discountCode,
  'total_price': instance.totalPrice,
  'wallet_applied': instance.walletApplied,
  'amount_due': instance.amountDue,
  'payment_status': instance.paymentStatus,
  'status': instance.status,
  'payment_expires_at': instance.paymentExpiresAt?.toIso8601String(),
  'token': instance.token,
  'share_url': instance.shareUrl,
  'is_redeemed': instance.isRedeemed,
  'redeemed_at': instance.redeemedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};
