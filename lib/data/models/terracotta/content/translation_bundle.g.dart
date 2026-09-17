// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_bundle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TranslationBundle _$TranslationBundleFromJson(Map<String, dynamic> json) =>
    _TranslationBundle(
      group: json['group'] as String,
      locale: json['locale'] as String,
      translations: _translationsFromJson(json['translations']),
    );

Map<String, dynamic> _$TranslationBundleToJson(_TranslationBundle instance) =>
    <String, dynamic>{
      'group': instance.group,
      'locale': instance.locale,
      'translations': _translationsToJson(instance.translations),
    };
