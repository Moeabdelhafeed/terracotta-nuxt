// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workshop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Workshop _$WorkshopFromJson(Map<String, dynamic> json) => _Workshop(
  id: (json['id'] as num).toInt(),
  type: const WorkshopTypeConverter().fromJson(json['type'] as String?),
  title: json['title'] as String,
  shortDescription: json['short_description'] as String,
  color: json['color'] as String,
  price: json['price'] as String,
  capacityPerSession: (json['capacity_per_session'] as num).toInt(),
  maxPeoplePerBooking: (json['max_people_per_booking'] as num).toInt(),
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  locationUrl: json['location_url'] as String?,
  celebrationPrice: json['celebration_price'] as String,
  cancellationWindowHours: (json['cancellation_window_hours'] as num).toInt(),
  audience: json['audience'] == null
      ? WorkshopAudience.mixed
      : const WorkshopAudienceConverter().fromJson(json['audience'] as String?),
  pieceWarningDays: (json['piece_warning_days'] as num?)?.toInt() ?? 7,
  hasDelivery: json['has_delivery'] as bool,
  image: json['image'] == null
      ? null
      : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
  minProductsPerPerson: (json['min_products_per_person'] as num?)?.toInt(),
  maxProductsPerPerson: (json['max_products_per_person'] as num?)?.toInt(),
  longDescription: json['long_description'] as String?,
);

Map<String, dynamic> _$WorkshopToJson(_Workshop instance) => <String, dynamic>{
  'id': instance.id,
  'type': const WorkshopTypeConverter().toJson(instance.type),
  'title': instance.title,
  'short_description': instance.shortDescription,
  'color': instance.color,
  'price': instance.price,
  'capacity_per_session': instance.capacityPerSession,
  'max_people_per_booking': instance.maxPeoplePerBooking,
  'duration_minutes': instance.durationMinutes,
  'location_url': instance.locationUrl,
  'celebration_price': instance.celebrationPrice,
  'cancellation_window_hours': instance.cancellationWindowHours,
  'audience': const WorkshopAudienceConverter().toJson(instance.audience),
  'piece_warning_days': instance.pieceWarningDays,
  'has_delivery': instance.hasDelivery,
  'image': instance.image,
  'min_products_per_person': instance.minProductsPerPerson,
  'max_products_per_person': instance.maxProductsPerPerson,
  'long_description': instance.longDescription,
};
