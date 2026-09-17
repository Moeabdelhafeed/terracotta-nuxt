// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Cart _$CartFromJson(Map<String, dynamic> json) => _Cart(
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CartItem>[],
  totalPrice: json['total_price'] as String,
);

Map<String, dynamic> _$CartToJson(_Cart instance) => <String, dynamic>{
  'items': instance.items,
  'total_price': instance.totalPrice,
};
