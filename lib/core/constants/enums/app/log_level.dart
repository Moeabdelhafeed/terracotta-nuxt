enum LogLevel {
  trace,
  debug,
  info,
  warning,
  error,
  fatal,
  ;

  String get label => switch (this) {
    .trace => 'TRACE',
    .debug => 'DEBUG',
    .info => 'INFO',
    .warning => 'WARNING',
    .error => 'ERROR',
    .fatal => 'FATAL',
  };

  static LogLevel fromString(String value) => values.firstWhere(
    (e) => e.label == value || e.name == value,
    orElse: () => LogLevel.debug,
  );
}
