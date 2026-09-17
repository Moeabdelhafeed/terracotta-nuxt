// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'line_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LineProduct _$LineProductFromJson(Map<String, dynamic> json) => _LineProduct(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  price: json['price'] as String,
  salePrice: json['sale_price'] as String?,
  image: json['image'] == null
      ? null
      : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
  isFeatured: json['is_featured'] as bool,
  isFavorited: json['is_favorited'] as bool,
  inStock: json['in_stock'] as bool?,
  stock: (json['stock'] as num?)?.toInt(),
  maxQuantity: (json['max_quantity'] as num?)?.toInt(),
);

Map<String, dynamic> _$LineProductToJson(_LineProduct instance) =>
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
    };
