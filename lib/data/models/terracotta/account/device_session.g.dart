// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceSession _$DeviceSessionFromJson(Map<String, dynamic> json) =>
    _DeviceSession(
      id: (json['id'] as num).toInt(),
      deviceName: json['device_name'] as String?,
      platform: json['platform'] as String,
      ip: json['ip'] as String,
      userAgent: json['user_agent'] as String,
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isCurrent: json['is_current'] as bool,
    );

Map<String, dynamic> _$DeviceSessionToJson(_DeviceSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_name': instance.deviceName,
      'platform': instance.platform,
      'ip': instance.ip,
      'user_agent': instance.userAgent,
      'last_seen_at': instance.lastSeenAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'is_current': instance.isCurrent,
    };
