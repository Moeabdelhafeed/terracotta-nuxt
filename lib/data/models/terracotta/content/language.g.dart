// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Language _$LanguageFromJson(Map<String, dynamic> json) => _Language(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  nativeName: json['native_name'] as String,
  direction: LanguageDirection.fromWire(json['direction'] as String?),
  isDefault: json['is_default'] as bool,
  image: json['image'] == null
      ? null
      : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LanguageToJson(_Language instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'native_name': instance.nativeName,
  'direction': languageDirectionToWire(instance.direction),
  'is_default': instance.isDefault,
  'image': instance.image,
};
