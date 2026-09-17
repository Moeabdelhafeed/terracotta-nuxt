// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => _AuthSession(
  token: json['token'] as String?,
  user: json['user'] == null
      ? null
      : TerracottaUser.fromJson(json['user'] as Map<String, dynamic>),
  tokenId: (json['token_id'] as num?)?.toInt(),
  isVerified: json['is_verified'] as bool?,
  otpExpiresInMinutes: (json['otp_expires_in_minutes'] as num?)?.toInt(),
  otp: json['otp'] as String?,
  isScanner: json['is_scanner'] as bool?,
);

Map<String, dynamic> _$AuthSessionToJson(_AuthSession instance) =>
    <String, dynamic>{
      'token': instance.token,
      'user': instance.user,
      'token_id': instance.tokenId,
      'is_verified': instance.isVerified,
      'otp_expires_in_minutes': instance.otpExpiresInMinutes,
      'otp': instance.otp,
      'is_scanner': instance.isScanner,
    };
