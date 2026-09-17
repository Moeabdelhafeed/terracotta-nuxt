// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pdf_bookmarks_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PdfBookmarksState _$PdfBookmarksStateFromJson(Map<String, dynamic> json) =>
    _PdfBookmarksState(
      pages:
          (json['pages'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => (e as num).toInt()).toList(),
            ),
          ) ??
          const <String, List<int>>{},
      lastReadPage:
          (json['last_read_page'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const <String, int>{},
    );

Map<String, dynamic> _$PdfBookmarksStateToJson(_PdfBookmarksState instance) =>
    <String, dynamic>{
      'pages': instance.pages,
      'last_read_page': instance.lastReadPage,
    };
