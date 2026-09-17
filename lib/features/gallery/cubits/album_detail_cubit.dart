import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/models/terracotta/gallery/gallery_album_detail.dart';
import 'album_detail_state.dart';

/// The one call the opened album makes.
typedef AlbumDetailFetch =
    AsyncResult<GalleryAlbumDetail> Function(
      String categoryId, {
      CancelToken? cancelToken,
    });

/// Loads `GET /api/gallery/{category}` — the album's own media.
///
/// The list endpoint gives a cover and two counts and nothing else, so
/// opening an album is always a second request; there is no way to
/// prefill this from what the list already had.
class AlbumDetailCubit extends Cubit<AlbumDetailState> {
  AlbumDetailCubit({required this.albumId, AlbumDetailFetch? fetch})
    : _fetch = fetch ?? ContentApis.getGalleryCategory,
      super(const AlbumDetailLoading());

  final int albumId;

  /// Injectable so the state machine can be tested without a network.
  /// Null in the app.
  final AlbumDetailFetch _fetch;

  /// A sheet is dismissed mid-flight more often than a page is — the
  /// answer would arrive to a closed cubit and `emit` throws.
  final _cancel = CancelToken();

  Future<void> load() async {
    final result = await _fetch('$albumId', cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(AlbumDetailLoaded(value));
      case Failure(:final error):
        // Only when there is nothing on screen yet — a failed retry
        // over media the customer is already looking at leaves it.
        if (state is! AlbumDetailLoaded) emit(AlbumDetailFailed(error));
    }
  }

  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
