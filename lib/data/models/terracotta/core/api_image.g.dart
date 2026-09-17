// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApiImage _$ApiImageFromJson(Map<String, dynamic> json) => _ApiImage(
  id: (json['id'] as num).toInt(),
  url: json['url'] as String,
  type: json['type'] as String,
  blurhash: json['blurhash'] as String,
  imageApi: json['image_api'] as String?,
);

Map<String, dynamic> _$ApiImageToJson(_ApiImage instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'type': instance.type,
  'blurhash': instance.blurhash,
  'image_api': instance.imageApi,
};
