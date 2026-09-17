// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeliveryZone _$DeliveryZoneFromJson(Map<String, dynamic> json) =>
    _DeliveryZone(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      fee: json['fee'] as String,
      freeOver: json['free_over'] as String?,
      neverFree: json['never_free'] as bool,
    );

Map<String, dynamic> _$DeliveryZoneToJson(_DeliveryZone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'fee': instance.fee,
      'free_over': instance.freeOver,
      'never_free': instance.neverFree,
    };
