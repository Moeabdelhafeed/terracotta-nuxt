// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_redemption.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GiftRedemption _$GiftRedemptionFromJson(Map<String, dynamic> json) =>
    _GiftRedemption(
      amount: json['amount'] as String,
      walletBalance: json['wallet_balance'] as String,
    );

Map<String, dynamic> _$GiftRedemptionToJson(_GiftRedemption instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'wallet_balance': instance.walletBalance,
    };
