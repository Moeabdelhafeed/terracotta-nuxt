// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'static_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StaticPage _$StaticPageFromJson(Map<String, dynamic> json) => _StaticPage(
  id: (json['id'] as num).toInt(),
  slug: json['slug'] as String,
  name: json['name'] as String,
  content: json['content'] as String,
  image: json['image'] == null
      ? null
      : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$StaticPageToJson(_StaticPage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'name': instance.name,
      'content': instance.content,
      'image': instance.image,
    };
