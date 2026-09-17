// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkshopProduct _$WorkshopProductFromJson(Map<String, dynamic> json) =>
    _WorkshopProduct(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      price: json['price'] as String,
      subtitle: json['subtitle'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ApiImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ApiImage>[],
    );

Map<String, dynamic> _$WorkshopProductToJson(_WorkshopProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'price': instance.price,
      'subtitle': instance.subtitle,
      'images': instance.images,
    };
