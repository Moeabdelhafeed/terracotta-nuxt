// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeCategory _$HomeCategoryFromJson(Map<String, dynamic> json) =>
    _HomeCategory(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      image: json['image'] == null
          ? null
          : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$HomeCategoryToJson(_HomeCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image': instance.image,
    };
