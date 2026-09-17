// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_inbox.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationInbox _$NotificationInboxFromJson(Map<String, dynamic> json) =>
    _NotificationInbox(
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      notifications: json['notifications'] == null
          ? const <AppNotification>[]
          : _readNotifications(json['notifications']),
    );

Map<String, dynamic> _$NotificationInboxToJson(_NotificationInbox instance) =>
    <String, dynamic>{
      'unread_count': instance.unreadCount,
      'notifications': instance.notifications,
    };
