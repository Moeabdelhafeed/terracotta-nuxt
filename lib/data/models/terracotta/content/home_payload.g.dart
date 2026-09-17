// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomePayload _$HomePayloadFromJson(Map<String, dynamic> json) => _HomePayload(
  banners: (json['banners'] as List<dynamic>)
      .map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
      .toList(),
  categories: (json['categories'] as List<dynamic>)
      .map((e) => HomeCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
  currentBooking: json['current_booking'] as Map<String, dynamic>?,
  featuredProducts: (json['featured_products'] as List<dynamic>)
      .map((e) => HomeProductCard.fromJson(e as Map<String, dynamic>))
      .toList(),
  offers: (json['offers'] as List<dynamic>)
      .map((e) => HomeProductCard.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$HomePayloadToJson(_HomePayload instance) =>
    <String, dynamic>{
      'banners': instance.banners,
      'categories': instance.categories,
      'current_booking': instance.currentBooking,
      'featured_products': instance.featuredProducts,
      'offers': instance.offers,
    };
