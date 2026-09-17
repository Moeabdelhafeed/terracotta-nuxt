// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    _WalletTransaction(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String?,
      amount: json['amount'] as String?,
      reason: json['reason'] as String?,
      workshopBookingId: (json['workshop_booking_id'] as num?)?.toInt(),
      shopOrderId: (json['shop_order_id'] as num?)?.toInt(),
      balanceAfter: json['balance_after'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$WalletTransactionToJson(_WalletTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'reason': instance.reason,
      'workshop_booking_id': instance.workshopBookingId,
      'shop_order_id': instance.shopOrderId,
      'balance_after': instance.balanceAfter,
      'created_at': instance.createdAt?.toIso8601String(),
    };
