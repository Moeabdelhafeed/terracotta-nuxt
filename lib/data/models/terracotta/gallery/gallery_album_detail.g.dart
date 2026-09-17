// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_album_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GalleryAlbumDetail _$GalleryAlbumDetailFromJson(Map<String, dynamic> json) =>
    _GalleryAlbumDetail(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      imagesCount: (json['images_count'] as num).toInt(),
      videosCount: (json['videos_count'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => GalleryMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$GalleryAlbumDetailToJson(_GalleryAlbumDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'images_count': instance.imagesCount,
      'videos_count': instance.videosCount,
      'items': instance.items,
    };
