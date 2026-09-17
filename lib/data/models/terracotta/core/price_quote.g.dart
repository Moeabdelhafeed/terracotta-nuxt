// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_quote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PriceQuote _$PriceQuoteFromJson(Map<String, dynamic> json) => _PriceQuote(
  subtotal: json['subtotal'] as String,
  discountAmount: json['discount_amount'] as String,
  totalPrice: json['total_price'] as String,
  walletApplied: json['wallet_applied'] as String,
  amountDue: json['amount_due'] as String,
  discountCode: json['discount_code'] as String?,
  vatRate: json['vat_rate'] as String?,
  vatAmount: json['vat_amount'] as String?,
  totalExcludingVat: json['total_excluding_vat'] as String?,
  deliveryFee: json['delivery_fee'] as String?,
  deliveryZone: json['delivery_zone'] as String?,
  giftValue: json['gift_value'] as String?,
  workshopId: (json['workshop_id'] as num?)?.toInt(),
  workshopSlotId: (json['workshop_slot_id'] as num?)?.toInt(),
  peopleCount: (json['people_count'] as num?)?.toInt(),
  unitPrice: json['unit_price'] as String?,
  hasCelebration: json['has_celebration'] as bool?,
  celebrationPrice: json['celebration_price'] as String?,
  alreadyPaid: json['already_paid'] as bool?,
);

Map<String, dynamic> _$PriceQuoteToJson(_PriceQuote instance) =>
    <String, dynamic>{
      'subtotal': instance.subtotal,
      'discount_amount': instance.discountAmount,
      'total_price': instance.totalPrice,
      'wallet_applied': instance.walletApplied,
      'amount_due': instance.amountDue,
      'discount_code': instance.discountCode,
      'vat_rate': instance.vatRate,
      'vat_amount': instance.vatAmount,
      'total_excluding_vat': instance.totalExcludingVat,
      'delivery_fee': instance.deliveryFee,
      'delivery_zone': instance.deliveryZone,
      'gift_value': instance.giftValue,
      'workshop_id': instance.workshopId,
      'workshop_slot_id': instance.workshopSlotId,
      'people_count': instance.peopleCount,
      'unit_price': instance.unitPrice,
      'has_celebration': instance.hasCelebration,
      'celebration_price': instance.celebrationPrice,
      'already_paid': instance.alreadyPaid,
    };
