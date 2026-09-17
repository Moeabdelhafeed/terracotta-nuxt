// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductDetail _$ProductDetailFromJson(Map<String, dynamic> json) =>
    _ProductDetail(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      price: json['price'] as String,
      salePrice: json['sale_price'] as String?,
      image: json['image'] == null
          ? null
          : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
      isFeatured: json['is_featured'] as bool,
      isFavorited: json['is_favorited'] as bool,
      inStock: json['in_stock'] as bool,
      stock: (json['stock'] as num?)?.toInt(),
      maxQuantity: (json['max_quantity'] as num).toInt(),
      description: json['description'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ApiImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ApiImage>[],
      colors:
          (json['colors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      height: json['height'] as String?,
      width: json['width'] as String?,
      length: json['length'] as String?,
      category: json['category'] as String?,
      subCategory: json['sub_category'] as String?,
      relatedProducts:
          (json['related_products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Product>[],
    );

Map<String, dynamic> _$ProductDetailToJson(_ProductDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'price': instance.price,
      'sale_price': instance.salePrice,
      'image': instance.image,
      'is_featured': instance.isFeatured,
      'is_favorited': instance.isFavorited,
      'in_stock': instance.inStock,
      'stock': instance.stock,
      'max_quantity': instance.maxQuantity,
      'description': instance.description,
      'images': instance.images,
      'colors': instance.colors,
      'height': instance.height,
      'width': instance.width,
      'length': instance.length,
      'category': instance.category,
      'sub_category': instance.subCategory,
      'related_products': instance.relatedProducts,
    };
