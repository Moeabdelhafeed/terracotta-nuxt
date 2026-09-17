enum AudioFormat {
  mp3,
  aac,
  wav,
  flac,
  ogg,
  wma,
  m4a,
  opus,
  ;

  String get displayName => switch (this) {
    .mp3 => 'MP3',
    .aac => 'AAC',
    .wav => 'WAV',
    .flac => 'FLAC',
    .ogg => 'OGG',
    .wma => 'WMA',
    .m4a => 'M4A',
    .opus => 'OPUS',
  };

  String get extension => switch (this) {
    .mp3 => 'mp3',
    .aac => 'aac',
    .wav => 'wav',
    .flac => 'flac',
    .ogg => 'ogg',
    .wma => 'wma',
    .m4a => 'm4a',
    .opus => 'opus',
  };

  String get mimeType => switch (this) {
    .mp3 => 'audio/mpeg',
    .aac => 'audio/aac',
    .wav => 'audio/wav',
    .flac => 'audio/flac',
    .ogg => 'audio/ogg',
    .wma => 'audio/x-ms-wma',
    .m4a => 'audio/mp4',
    .opus => 'audio/opus',
  };

  static AudioFormat fromString(String value) => values.firstWhere(
    (e) => e.displayName == value || e.name == value || e.extension == value,
    orElse: () => AudioFormat.mp3,
  );

  static AudioFormat? fromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    try {
      return values.firstWhere((e) => e.extension == ext);
    } catch (_) {
      return null;
    }
  }
}
