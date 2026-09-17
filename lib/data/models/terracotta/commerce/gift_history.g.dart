// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gift_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GiftTotals _$GiftTotalsFromJson(Map<String, dynamic> json) => _GiftTotals(
  sentCount: (json['sent_count'] as num?)?.toInt() ?? 0,
  sentTotalPaid: json['sent_total_paid'] as String? ?? '0.00',
  receivedCount: (json['received_count'] as num?)?.toInt() ?? 0,
  receivedTotal: json['received_total'] as String? ?? '0.00',
);

Map<String, dynamic> _$GiftTotalsToJson(_GiftTotals instance) =>
    <String, dynamic>{
      'sent_count': instance.sentCount,
      'sent_total_paid': instance.sentTotalPaid,
      'received_count': instance.receivedCount,
      'received_total': instance.receivedTotal,
    };
