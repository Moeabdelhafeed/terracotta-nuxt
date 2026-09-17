import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/gallery/gallery_album.dart';

/// What the album list knows. Same three states as the home screen, for
/// the same reason: the screen draws something different for each, and
/// a bag of booleans lets two of them be true at once.
@immutable
sealed class GalleryState {
  const GalleryState();
}

final class GalleryLoading extends GalleryState {
  const GalleryLoading();
}

final class GalleryLoaded extends GalleryState {
  const GalleryLoaded(this.albums);

  final List<GalleryAlbum> albums;
}

final class GalleryFailed extends GalleryState {
  const GalleryFailed(this.error);

  final AppException error;
}
