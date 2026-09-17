// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Address _$AddressFromJson(Map<String, dynamic> json) => _Address(
  id: (json['id'] as num).toInt(),
  label: json['label'] as String?,
  addressLine: json['address_line'] as String,
  lat: json['lat'] as String,
  lng: json['lng'] as String,
  phone: json['phone'] as String,
  notes: json['notes'] as String?,
  buildingNumber: json['building_number'] as String,
  street: json['street'] as String,
  district: json['district'] as String,
  postalCode: json['postal_code'] as String,
  additionalNumber: json['additional_number'] as String,
  unitNumber: json['unit_number'] as String?,
  shortAddress: json['short_address'] as String?,
  deliveryZoneId: (json['delivery_zone_id'] as num).toInt(),
  deliveryZone: json['delivery_zone'] as String,
  deliveryFee: json['delivery_fee'] as String,
  isDefault: json['is_default'] as bool,
  mapUrl: json['map_url'] as String,
);

Map<String, dynamic> _$AddressToJson(_Address instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'address_line': instance.addressLine,
  'lat': instance.lat,
  'lng': instance.lng,
  'phone': instance.phone,
  'notes': instance.notes,
  'building_number': instance.buildingNumber,
  'street': instance.street,
  'district': instance.district,
  'postal_code': instance.postalCode,
  'additional_number': instance.additionalNumber,
  'unit_number': instance.unitNumber,
  'short_address': instance.shortAddress,
  'delivery_zone_id': instance.deliveryZoneId,
  'delivery_zone': instance.deliveryZone,
  'delivery_fee': instance.deliveryFee,
  'is_default': instance.isDefault,
  'map_url': instance.mapUrl,
};
