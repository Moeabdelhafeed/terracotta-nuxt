// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GalleryAlbum _$GalleryAlbumFromJson(Map<String, dynamic> json) =>
    _GalleryAlbum(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      cover: ApiImage.fromJson(json['cover'] as Map<String, dynamic>),
      imagesCount: (json['images_count'] as num).toInt(),
      videosCount: (json['videos_count'] as num).toInt(),
    );

Map<String, dynamic> _$GalleryAlbumToJson(_GalleryAlbum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'cover': instance.cover,
      'images_count': instance.imagesCount,
      'videos_count': instance.videosCount,
    };
