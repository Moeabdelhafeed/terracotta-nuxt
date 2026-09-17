// Project imports:
import '../../constants/enums/app/log_level.dart';
import 'base_logger.dart';

// ─── LoggerConfig ────────────────────────────────────────────────────

/// Configuration for the global [Logger].
class LoggerConfig {
  final bool colors;
  final int errorMethodCount;
  final int methodCount;
  final int lineLength;
  final LogLevel minLevel;
  final Map<String, String> apiContentTypeColors;

  /// Environment label surfaced in the top bar (e.g. `'DEV'`). Hidden when null.
  final String? environment;

  /// Include `[#N]` sequence counter in the top bar.
  final bool showSequence;

  /// Include `[+Nms]` delta-since-previous-log marker.
  final bool showDelta;

  /// Include `[file.dart:line]` source location. Small perf cost.
  final bool showSource;

  /// Draw the box frame (╭─╮ / │ walls / ╰─╯, compact ┃). Off = plain
  /// lines with the same content.
  final bool showBorders;

  const LoggerConfig({
    this.colors = true,
    this.errorMethodCount = 8,
    this.methodCount = 2,
    this.lineLength = 120,
    this.minLevel = LogLevel.trace,
    this.apiContentTypeColors = const {
      'url': '\x1B[96m', // Bright cyan
      'headers': '\x1B[36m',
      'query': '\x1B[36m',
      'response': '\x1B[32m',
      'data': '\x1B[33m',
      'error': '\x1B[31m',
    },
    this.environment,
    this.showSequence = false,
    this.showDelta = true,
    this.showSource = false,
    this.showBorders = true,
  });

  /// Quieter, colorless config suitable for release builds.
  factory LoggerConfig.production() => const LoggerConfig(
    colors: false,
    minLevel: LogLevel.info,
    errorMethodCount: 3,
    methodCount: 0,
  );
}

// ─── Logger ──────────────────────────────────────────────────────────

/// Global logger facade with centralized configuration.
///
/// ```dart
/// Logger.m.d('Debug message');        // Main logger
/// Logger.a.i('API request sent');     // API logger
/// Logger.configure(colors: false);    // Tweak at runtime
/// Logger.configureWithConfig(LoggerConfig.production()); // Apply preset
/// ```
class Logger {
  static MainLogger _mainLogger = MainLogger();
  static ApiLogger _apiLogger = ApiLogger();

  /// Main application logger (general purpose)
  static MainLogger get m => _mainLogger;

  /// API logger (request/response logging with JSON highlighting)
  static ApiLogger get a => _apiLogger;

  /// Apply a partial update to all loggers.
  static void configure({
    bool? colors,
    int? errorMethodCount,
    int? methodCount,
    int? lineLength,
    LogLevel? minLevel,
    Map<String, String>? apiContentTypeColors,
    String? environment,
    bool? showSequence,
    bool? showDelta,
    bool? showSource,
    bool? showBorders,
  }) {
    _updateConfig(
      LoggerConfig(
        colors: colors ?? _mainLogger.colors,
        errorMethodCount: errorMethodCount ?? _mainLogger.errorMethodCount,
        methodCount: methodCount ?? _mainLogger.methodCount,
        lineLength: lineLength ?? _mainLogger.lineLength,
        minLevel: minLevel ?? _mainLogger.minLevel,
        apiContentTypeColors:
            apiContentTypeColors ?? _apiLogger.contentTypeColors,
        environment: environment ?? _mainLogger.environment,
        showSequence: showSequence ?? _mainLogger.showSequence,
        showDelta: showDelta ?? _mainLogger.showDelta,
        showSource: showSource ?? _mainLogger.showSource,
        showBorders: showBorders ?? _mainLogger.showBorders,
      ),
    );
  }

  /// Apply a full [LoggerConfig] (e.g. [LoggerConfig.production]).
  static void configureWithConfig(LoggerConfig config) => _updateConfig(config);

  /// Reset to default configuration.
  static void reset() => _updateConfig(const LoggerConfig());

  static void _updateConfig(LoggerConfig config) {
    _mainLogger = MainLogger(
      colors: config.colors,
      errorMethodCount: config.errorMethodCount,
      methodCount: config.methodCount,
      lineLength: config.lineLength,
      minLevel: config.minLevel,
      environment: config.environment,
      showSequence: config.showSequence,
      showDelta: config.showDelta,
      showSource: config.showSource,
      showBorders: config.showBorders,
    );

    _apiLogger = ApiLogger(
      colors: config.colors,
      errorMethodCount: config.errorMethodCount,
      methodCount: config.methodCount,
      lineLength: config.lineLength,
      minLevel: config.minLevel,
      contentTypeColors: config.apiContentTypeColors,
      environment: config.environment,
      showSequence: config.showSequence,
      showDelta: config.showDelta,
      showSource: config.showSource,
      showBorders: config.showBorders,
    );
  }
}
