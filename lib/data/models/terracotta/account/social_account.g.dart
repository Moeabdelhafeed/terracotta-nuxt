// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SocialAccount _$SocialAccountFromJson(Map<String, dynamic> json) =>
    _SocialAccount(
      id: (json['id'] as num).toInt(),
      provider: json['provider'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$SocialAccountToJson(_SocialAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'provider': instance.provider,
      'email': instance.email,
      'name': instance.name,
    };
