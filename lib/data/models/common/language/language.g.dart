// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Language _$LanguageFromJson(Map<String, dynamic> json) => _Language(
  id: (json['id'] as num).toInt(),
  locale: json['locale'] as String,
  name: json['name'] as String?,
  direction: json['direction'] as String?,
  flag: json['flag'] as String?,
  isDefault: json['is_default'] as bool? ?? false,
  status: json['status'] as bool? ?? true,
);

Map<String, dynamic> _$LanguageToJson(_Language instance) => <String, dynamic>{
  'id': instance.id,
  'locale': instance.locale,
  'name': instance.name,
  'direction': instance.direction,
  'flag': instance.flag,
  'is_default': instance.isDefault,
  'status': instance.status,
};
