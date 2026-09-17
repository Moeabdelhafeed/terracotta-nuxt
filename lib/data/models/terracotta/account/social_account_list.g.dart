// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_account_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SocialAccountList _$SocialAccountListFromJson(Map<String, dynamic> json) =>
    _SocialAccountList(
      socialAccounts:
          (json['social_accounts'] as List<dynamic>?)
              ?.map((e) => SocialAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SocialAccount>[],
      allowedProviders:
          (json['allowed_providers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      maxAccounts: (json['max_accounts'] as num?)?.toInt(),
      canLinkMore: json['can_link_more'] as bool?,
    );

Map<String, dynamic> _$SocialAccountListToJson(_SocialAccountList instance) =>
    <String, dynamic>{
      'social_accounts': instance.socialAccounts,
      'allowed_providers': instance.allowedProviders,
      'max_accounts': instance.maxAccounts,
      'can_link_more': instance.canLinkMore,
    };
