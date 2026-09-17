// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  social: readLinks(json['social']),
  contact: readLinks(json['contact']),
  appStore: readLinks(json['app_store']),
  googlePlay: readLinks(json['google_play']),
  appGallery: readLinks(json['app_gallery']),
  business: readLinks(json['business']),
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'social': instance.social,
      'contact': instance.contact,
      'app_store': instance.appStore,
      'google_play': instance.googlePlay,
      'app_gallery': instance.appGallery,
      'business': instance.business,
    };
