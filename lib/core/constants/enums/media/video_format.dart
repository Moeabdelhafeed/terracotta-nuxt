enum VideoFormat {
  mp4,
  mov,
  avi,
  wmv,
  flv,
  webm,
  mkv,
  m4v,
  ;

  String get displayName => switch (this) {
    .mp4 => 'MP4',
    .mov => 'MOV',
    .avi => 'AVI',
    .wmv => 'WMV',
    .flv => 'FLV',
    .webm => 'WEBM',
    .mkv => 'MKV',
    .m4v => 'M4V',
  };

  String get extension => switch (this) {
    .mp4 => 'mp4',
    .mov => 'mov',
    .avi => 'avi',
    .wmv => 'wmv',
    .flv => 'flv',
    .webm => 'webm',
    .mkv => 'mkv',
    .m4v => 'm4v',
  };

  static VideoFormat fromString(String value) => values.firstWhere(
    (e) => e.displayName == value || e.name == value,
    orElse: () => VideoFormat.mp4,
  );
}
