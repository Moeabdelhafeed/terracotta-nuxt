import 'image_format.dart';

enum ImageType {
  asset,
  network,
  memory,
  file,

  /// An `ImageProvider` the caller already has.
  ///
  /// Not a source this module can INSPECT — a provider decides for
  /// itself where its bytes come from — so it has no format list and no
  /// path to detect. It exists because three widgets in this app take a
  /// provider from their caller (a container's background, a sliver app
  /// bar's backdrop, an avatar's picture) and had no way to draw one
  /// through `GlobalImage`.
  provider;

  List<ImageFormat> get supportedImageFormats => switch (this) {
    .asset => [
      ImageFormat.png,
      ImageFormat.jpg,
      ImageFormat.jpeg,
      ImageFormat.gif,
      ImageFormat.webp,
      ImageFormat.svg,
    ],
    .network => [
      ImageFormat.png,
      ImageFormat.jpg,
      ImageFormat.jpeg,
      ImageFormat.gif,
      ImageFormat.webp,
      ImageFormat.svg,
    ],
    .memory => [
      ImageFormat.png,
      ImageFormat.jpg,
      ImageFormat.jpeg,
      ImageFormat.gif,
      ImageFormat.webp,
    ],
    .file => [
      ImageFormat.png,
      ImageFormat.jpg,
      ImageFormat.jpeg,
      ImageFormat.gif,
      ImageFormat.webp,
    ],
    // A provider is opaque: it may be a network fetch, an asset, a
    // memory blob or something an app wrote itself. Claiming a format
    // list for it would be a guess.
    .provider => const [],
  };

  bool supportsExtension(ImageFormat imageFormat) =>
      supportedImageFormats.contains(imageFormat);

  static ImageType? detectFromPath(String path) =>
      path.startsWith('http://') || path.startsWith('https://')
      ? ImageType.network
      : path.startsWith('assets/')
      ? ImageType.asset
      : path.startsWith('/') || path.contains('\\')
      ? ImageType.file
      : null;
}
