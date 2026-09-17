// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_zones.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeliveryZones _$DeliveryZonesFromJson(Map<String, dynamic> json) =>
    _DeliveryZones(
      zones: (json['zones'] as List<dynamic>)
          .map((e) => DeliveryZone.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultFee: json['default_fee'] as String,
      freeDeliveryOver: json['free_delivery_over'] as String,
    );

Map<String, dynamic> _$DeliveryZonesToJson(_DeliveryZones instance) =>
    <String, dynamic>{
      'zones': instance.zones,
      'default_fee': instance.defaultFee,
      'free_delivery_over': instance.freeDeliveryOver,
    };
