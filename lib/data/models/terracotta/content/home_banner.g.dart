// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeBanner _$HomeBannerFromJson(Map<String, dynamic> json) => _HomeBanner(
  id: (json['id'] as num).toInt(),
  label: json['label'] as String,
  title: json['title'] as String,
  ctaText: json['cta_text'] as String?,
  linkType: HomeLinkType.fromWire(json['link_type'] as String?),
  linkTargetId: (json['link_target_id'] as num?)?.toInt(),
  link: json['link'] as String?,
  image: json['image'] == null
      ? null
      : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$HomeBannerToJson(_HomeBanner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'title': instance.title,
      'cta_text': instance.ctaText,
      'link_type': homeLinkTypeToWire(instance.linkType),
      'link_target_id': instance.linkTargetId,
      'link': instance.link,
      'image': instance.image,
    };
