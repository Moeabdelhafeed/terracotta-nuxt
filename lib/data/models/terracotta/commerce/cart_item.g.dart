// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartItem _$CartItemFromJson(Map<String, dynamic> json) => _CartItem(
  id: (json['id'] as num).toInt(),
  product: LineProduct.fromJson(json['product'] as Map<String, dynamic>),
  color: json['color'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: json['unit_price'] as String,
  lineTotal: json['line_total'] as String,
  inStock: json['in_stock'] as bool? ?? true,
  availableStock: (json['available_stock'] as num?)?.toInt(),
);

Map<String, dynamic> _$CartItemToJson(_CartItem instance) => <String, dynamic>{
  'id': instance.id,
  'product': instance.product,
  'color': instance.color,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'line_total': instance.lineTotal,
  'in_stock': instance.inStock,
  'available_stock': instance.availableStock,
};
