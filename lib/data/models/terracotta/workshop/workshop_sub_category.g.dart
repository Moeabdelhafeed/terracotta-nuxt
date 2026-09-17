// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_sub_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkshopSubCategory _$WorkshopSubCategoryFromJson(Map<String, dynamic> json) =>
    _WorkshopSubCategory(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => WorkshopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WorkshopProduct>[],
    );

Map<String, dynamic> _$WorkshopSubCategoryToJson(
  _WorkshopSubCategory instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'products': instance.products,
};
