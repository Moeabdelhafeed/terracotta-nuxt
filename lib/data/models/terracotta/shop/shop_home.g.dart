// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShopHome _$ShopHomeFromJson(Map<String, dynamic> json) => _ShopHome(
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => ShopCategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ShopCategory>[],
  featuredProducts:
      (json['featured_products'] as List<dynamic>?)
          ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Product>[],
  offers:
      (json['offers'] as List<dynamic>?)
          ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Product>[],
);

Map<String, dynamic> _$ShopHomeToJson(_ShopHome instance) => <String, dynamic>{
  'categories': instance.categories,
  'featured_products': instance.featuredProducts,
  'offers': instance.offers,
};
