// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GalleryMediaItem _$GalleryMediaItemFromJson(Map<String, dynamic> json) =>
    _GalleryMediaItem(
      id: (json['id'] as num).toInt(),
      type: GalleryMediaType.fromWire(json['type'] as String?),
      image: json['image'] == null
          ? null
          : ApiImage.fromJson(json['image'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GalleryMediaItemToJson(_GalleryMediaItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': galleryMediaTypeToWire(instance.type),
      'image': instance.image,
    };
