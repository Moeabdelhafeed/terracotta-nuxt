// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GiftPreview _$GiftPreviewFromJson(Map<String, dynamic> json) => _GiftPreview(
  token: json['token'] as String,
  recipientName: json['recipient_name'] as String,
  message: json['message'] as String? ?? '',
  amount: json['amount'] as String,
  from: json['from'] as String? ?? '',
  isRedeemed: json['is_redeemed'] as bool,
  redeemedAt: json['redeemed_at'] == null
      ? null
      : DateTime.parse(json['redeemed_at'] as String),
  isClaimable: json['is_claimable'] as bool,
  deepLink: json['deep_link'] as String?,
  storeLinks:
      (json['store_links'] as List<dynamic>?)
          ?.map((e) => GiftStoreLink.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GiftStoreLink>[],
);

Map<String, dynamic> _$GiftPreviewToJson(_GiftPreview instance) =>
    <String, dynamic>{
      'token': instance.token,
      'recipient_name': instance.recipientName,
      'message': instance.message,
      'amount': instance.amount,
      'from': instance.from,
      'is_redeemed': instance.isRedeemed,
      'redeemed_at': instance.redeemedAt?.toIso8601String(),
      'is_claimable': instance.isClaimable,
      'deep_link': instance.deepLink,
      'store_links': instance.storeLinks,
    };

_GiftStoreLink _$GiftStoreLinkFromJson(Map<String, dynamic> json) =>
    _GiftStoreLink(type: json['type'] as String, url: json['url'] as String);

Map<String, dynamic> _$GiftStoreLinkToJson(_GiftStoreLink instance) =>
    <String, dynamic>{'type': instance.type, 'url': instance.url};
