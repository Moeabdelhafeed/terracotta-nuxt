enum ImageFormat {
  png,
  jpg,
  jpeg,
  gif,
  webp,
  svg;

  String get displayName => switch (this) {
    .png => 'PNG',
    .jpg => 'JPG',
    .jpeg => 'JPEG',
    .gif => 'GIF',
    .webp => 'WEBP',
    .svg => 'SVG',
  };

  String get extension => switch (this) {
    .png => 'png',
    .jpg => 'jpg',
    .jpeg => 'jpeg',
    .gif => 'gif',
    .webp => 'webp',
    .svg => 'svg',
  };

  static ImageFormat fromString(String value) => values.firstWhere(
    (e) => e.displayName == value || e.name == value,
    orElse: () => ImageFormat.png,
  );
}
