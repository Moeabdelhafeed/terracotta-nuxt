// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppConfig _$AppConfigFromJson(Map<String, dynamic> json) => _AppConfig(
  identifiers: (json['identifiers'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  hasUsernameField: json['has_username_field'] as bool,
  hasEmailField: json['has_email_field'] as bool,
  hasPhoneField: json['has_phone_field'] as bool,
  socialProviders: (json['social_providers'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  maxSocialAccounts: (json['max_social_accounts'] as num).toInt(),
  socialAuthAvailable: json['social_auth_available'] as bool,
  isOtpWhatsapp: json['is_otp_whatsapp'] as bool,
  multiSession: json['multi_session'] as bool,
  appUsers: json['app_users'] as bool,
  appGuests: json['app_guests'] as bool,
  allowGift: json['allow_gift'] as bool?,
  authMode: json['auth_mode'] as String,
  allowedEmailDomains: json['allowed_email_domains'] as String,
  allowedPhoneCountries: json['allowed_phone_countries'] as String,
  fcmTopics:
      (json['fcm_topics'] as List<dynamic>?)
          ?.map((e) => FcmTopic.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FcmTopic>[],
);

Map<String, dynamic> _$AppConfigToJson(_AppConfig instance) =>
    <String, dynamic>{
      'identifiers': instance.identifiers,
      'has_username_field': instance.hasUsernameField,
      'has_email_field': instance.hasEmailField,
      'has_phone_field': instance.hasPhoneField,
      'social_providers': instance.socialProviders,
      'max_social_accounts': instance.maxSocialAccounts,
      'social_auth_available': instance.socialAuthAvailable,
      'is_otp_whatsapp': instance.isOtpWhatsapp,
      'multi_session': instance.multiSession,
      'app_users': instance.appUsers,
      'app_guests': instance.appGuests,
      'allow_gift': instance.allowGift,
      'auth_mode': instance.authMode,
      'allowed_email_domains': instance.allowedEmailDomains,
      'allowed_phone_countries': instance.allowedPhoneCountries,
      'fcm_topics': instance.fcmTopics,
    };

_FcmTopic _$FcmTopicFromJson(Map<String, dynamic> json) => _FcmTopic(
  name: json['name'] as String,
  base: json['base'] as String,
  lang: json['lang'] as String?,
);

Map<String, dynamic> _$FcmTopicToJson(_FcmTopic instance) => <String, dynamic>{
  'name': instance.name,
  'base': instance.base,
  'lang': instance.lang,
};
