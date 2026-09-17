// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discount_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiscountCode _$DiscountCodeFromJson(Map<String, dynamic> json) =>
    _DiscountCode(
      code: json['code'] as String,
      type: json['type'] as String,
      value: json['value'] as String,
      maxDiscount: json['max_discount'] as String?,
      minOrderTotal: json['min_order_total'] as String?,
      endsAt: json['ends_at'] == null
          ? null
          : DateTime.parse(json['ends_at'] as String),
    );

Map<String, dynamic> _$DiscountCodeToJson(_DiscountCode instance) =>
    <String, dynamic>{
      'code': instance.code,
      'type': instance.type,
      'value': instance.value,
      'max_discount': instance.maxDiscount,
      'min_order_total': instance.minOrderTotal,
      'ends_at': instance.endsAt?.toIso8601String(),
    };
