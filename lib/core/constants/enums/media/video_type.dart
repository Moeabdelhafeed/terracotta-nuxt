import 'video_format.dart';

enum VideoType {
  asset,
  network,
  memory,
  file,
  ;

  /// All video types support the same formats.
  static const List<VideoFormat> supportedFormats = VideoFormat.values;

  bool supportsExtension(VideoFormat videoFormat) =>
      supportedFormats.contains(videoFormat);

  static VideoType? detectFromPath(String path) =>
      path.startsWith('http://') || path.startsWith('https://')
      ? VideoType.network
      : path.startsWith('assets/')
      ? VideoType.asset
      : path.startsWith('/') || path.contains('\\')
      ? VideoType.file
      : null;
}
