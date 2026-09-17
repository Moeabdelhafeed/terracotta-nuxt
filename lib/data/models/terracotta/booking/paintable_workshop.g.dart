// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paintable_workshop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaintableWorkshop _$PaintableWorkshopFromJson(Map<String, dynamic> json) =>
    _PaintableWorkshop(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String?,
      image: json['image'] == null
          ? null
          : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PaintableWorkshopToJson(_PaintableWorkshop instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image': instance.image,
    };
