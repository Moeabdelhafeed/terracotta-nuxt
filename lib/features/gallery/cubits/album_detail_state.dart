import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/gallery/gallery_album_detail.dart';

/// What one opened album knows. Same three states as the album list.
@immutable
sealed class AlbumDetailState {
  const AlbumDetailState();
}

final class AlbumDetailLoading extends AlbumDetailState {
  const AlbumDetailLoading();
}

final class AlbumDetailLoaded extends AlbumDetailState {
  const AlbumDetailLoaded(this.album);

  final GalleryAlbumDetail album;
}

final class AlbumDetailFailed extends AlbumDetailState {
  const AlbumDetailFailed(this.error);

  final AppException error;
}
