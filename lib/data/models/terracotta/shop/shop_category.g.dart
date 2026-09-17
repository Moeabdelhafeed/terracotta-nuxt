// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShopCategory _$ShopCategoryFromJson(Map<String, dynamic> json) =>
    _ShopCategory(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      image: json['image'] == null
          ? null
          : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
      subCategories:
          (json['sub_categories'] as List<dynamic>?)
              ?.map((e) => ShopSubCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ShopSubCategory>[],
    );

Map<String, dynamic> _$ShopCategoryToJson(_ShopCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image': instance.image,
      'sub_categories': instance.subCategories,
    };
