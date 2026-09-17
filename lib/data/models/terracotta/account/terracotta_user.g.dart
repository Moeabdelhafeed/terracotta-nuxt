// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'terracotta_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TerracottaUser _$TerracottaUserFromJson(Map<String, dynamic> json) =>
    _TerracottaUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      isActive: (json['is_active'] as num?)?.toInt() ?? 1,
      isGuest: json['is_guest'] as bool? ?? false,
      isReviewer: json['is_reviewer'] as bool? ?? false,
      platform: json['platform'] as String?,
      guestId: json['guest_id'] as String?,
      lastSeenAt: json['last_seen_at'] == null
          ? null
          : DateTime.parse(json['last_seen_at'] as String),
      currentLang: json['current_lang'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      walletBalance: json['wallet_balance'] as String? ?? '0.00',
      hasPassword: json['has_password'] as bool? ?? false,
    );

Map<String, dynamic> _$TerracottaUserToJson(_TerracottaUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'is_active': instance.isActive,
      'is_guest': instance.isGuest,
      'is_reviewer': instance.isReviewer,
      'platform': instance.platform,
      'guest_id': instance.guestId,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'current_lang': instance.currentLang,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'wallet_balance': instance.walletBalance,
      'has_password': instance.hasPassword,
    };
