// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceList _$DeviceListFromJson(Map<String, dynamic> json) => _DeviceList(
  devices:
      (json['devices'] as List<dynamic>?)
          ?.map((e) => DeviceSession.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <DeviceSession>[],
);

Map<String, dynamic> _$DeviceListToJson(_DeviceList instance) =>
    <String, dynamic>{'devices': instance.devices};
