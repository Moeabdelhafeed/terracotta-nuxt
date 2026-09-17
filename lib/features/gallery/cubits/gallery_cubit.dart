import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/content_apis.dart';
import '../../../data/models/terracotta/gallery/gallery_album.dart';
import '../../_shared/locale_scoped_load.dart';
import 'gallery_state.dart';

/// The one call this screen makes.
typedef GalleryFetch =
    AsyncResult<List<GalleryAlbum>> Function({CancelToken? cancelToken});

/// Loads `GET /api/gallery-categories` — the album list, each row
/// carrying its own `images_count` and `videos_count`, so the counts
/// need no second call.
class GalleryCubit extends Cubit<GalleryState> with LocaleScopedLoad {
  GalleryCubit({GalleryFetch? fetch})
    : _fetch = fetch ?? ContentApis.getGalleryCategories,
      super(const GalleryLoading());

  /// Injectable so the state machine can be tested without a network.
  /// Null in the app.
  final GalleryFetch _fetch;

  /// Stashed so an in-flight request is dropped when the screen goes —
  /// the answer would otherwise arrive to a closed cubit and `emit`
  /// throws.
  final _cancel = CancelToken();

  @override
  bool get hasData => state is GalleryLoaded;

  @override
  Future<void> load() async {
    final result = await _fetch(cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(GalleryLoaded(value));
      case Failure(:final error):
        // Only when there is nothing on screen yet. A refresh that
        // fails over albums the customer is already looking at leaves
        // them alone.
        if (state is! GalleryLoaded) emit(GalleryFailed(error));
    }
  }

  /// Pull to refresh. Records the language it ran in, so returning to
  /// the tab does not immediately repeat it.
  Future<void> refresh(String locale) => refreshIn(locale);

  @override
  Future<void> close() {
    _cancel.cancel();
    return super.close();
  }
}
