// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LinkItem _$LinkItemFromJson(Map<String, dynamic> json) => _LinkItem(
  id: (json['id'] as num).toInt(),
  text: json['text'] as String,
  url: json['url'] as String,
  image: ApiImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LinkItemToJson(_LinkItem instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'url': instance.url,
  'image': instance.image,
};
