import '../../../generated/l10n.dart';
import '../tr.dart';

/// Gallery — album list and the opened album sheet.
class GalleryStrings {
  GalleryStrings._();

  static String get title => Tr.t('gallery_title', S.current.gallery_title);

  static String get subtitle =>
      Tr.t('gallery_subtitle', S.current.gallery_subtitle);

  /// «١٠ صور · ١١ فيديو» — or just one half of it.
  ///
  /// A zero is not worth a word. An album of three photographs and no
  /// film reads "3 photos", not "3 photos · 0 videos", which is a
  /// sentence about something that is not there.
  ///
  /// Empty when the album has nothing at all: the caller draws no line
  /// rather than a line saying so.
  static String counts(int photos, int videos) {
    if (photos > 0 && videos > 0) {
      return Tr.t('gallery_counts', S.current.gallery_counts(photos, videos));
    }
    if (photos > 0) {
      return Tr.t(
        'gallery_counts_photos',
        S.current.gallery_counts_photos(photos),
      );
    }
    if (videos > 0) {
      return Tr.t(
        'gallery_counts_videos',
        S.current.gallery_counts_videos(videos),
      );
    }
    return '';
  }

  static String get empty => Tr.t('gallery_empty', S.current.gallery_empty);

  /// An album with nothing in it — a different sentence from an app
  /// with no albums.
  static String get albumEmpty =>
      Tr.t('gallery_album_empty', S.current.gallery_album_empty);
}
