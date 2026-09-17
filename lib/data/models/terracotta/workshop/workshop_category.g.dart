// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkshopCategory _$WorkshopCategoryFromJson(Map<String, dynamic> json) =>
    _WorkshopCategory(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      subCategories:
          (json['sub_categories'] as List<dynamic>?)
              ?.map(
                (e) => WorkshopSubCategory.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <WorkshopSubCategory>[],
    );

Map<String, dynamic> _$WorkshopCategoryToJson(_WorkshopCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'sub_categories': instance.subCategories,
    };
