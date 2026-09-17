// Dart imports:
import 'dart:async';
import 'dart:developer' as developer;

// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import '../../constants/enums/app/log_level.dart';
import 'log_buffer.dart';

export 'log_buffer.dart' show LogBuffer, LogEntry;

/// Build-time flag that controls the stdout emission half of the
/// dual-channel logger. Defaults to `true` (terminal-friendly).
///
/// Behavior in `kDebugMode`:
///   - `developer.log` always runs → posts to VM Service → IDE Debug
///     Console shows the formatted `[APP]` line.
///   - `Zone.root.print` runs only when this flag is `true` → stdout →
///     bare `flutter run` terminal shows colored output. IDE Debug
///     Consoles ALSO surface stdout as `I/flutter (PID):` lines,
///     producing a visible duplicate of every log entry.
///
/// IDE launches (VS Code `.vscode/launch.json`) pass
/// `--dart-define=LOG_TO_STDOUT=false` so the IDE only shows the
/// formatted `developer.log` channel — no `I/flutter` dupes.
///
/// Terminal launches (`make run-dev`, `./scripts/flutter-run-color.sh`)
/// leave the flag at default → colored output reaches the terminal
/// via the PTY pipe.
const bool _kLogToStdout = bool.fromEnvironment(
  'LOG_TO_STDOUT',
  defaultValue: true,
);

/// Global log capture callback for crash-reporter integration (e.g. Crashlytics).
/// Receives a structured [LogEntry] so you can filter by level, format
/// however you like, or forward selectively.
typedef LogCaptureCallback = void Function(LogEntry entry);
LogCaptureCallback? _globalLogCaptureCallback;

/// Static methods to control global log capturing
class LogCapture {
  static void setCallback(LogCaptureCallback callback) {
    _globalLogCaptureCallback = callback;
  }

  static void clearCallback() {
    _globalLogCaptureCallback = null;
  }
}

/// Cross-chunk state for the stateful JSON highlighter. When a long line is
/// word-wrapped mid-string, the next chunk needs to know it started inside
/// a string so the colouring stays consistent across rows.
class _JsonHighlightState {
  bool inString = false;
  bool escapeNext = false;
  bool isKey = false;
}

/// Base logger class that provides common logging functionality
/// to eliminate code duplication between different logger implementations.
abstract class BaseLogger {
  final bool colors;
  final int errorMethodCount;
  final int methodCount;
  final int lineLength;
  final LogLevel minLevel;
  final String logName;

  /// Optional environment label surfaced in the top bar (e.g. `'DEV'`).
  final String? environment;

  /// Include a monotonic `[#N]` sequence counter in the top bar.
  final bool showSequence;

  /// Include a `[+Nms]` delta-since-previous-log marker.
  final bool showDelta;

  /// Include a `[file.dart:line]` source location in the top bar.
  /// Requires parsing `StackTrace.current` — small perf cost.
  final bool showSource;

  /// Draw the box frame (╭─╮ top bar, │ walls, ├─┤ dividers, ╰─╯
  /// bottom, compact ┃). Off = identical content as plain lines —
  /// easier to copy/grep, and immune to wrap-broken frames in narrow
  /// terminals.
  final bool showBorders;

  BaseLogger({
    this.colors = true,
    this.errorMethodCount = 8,
    this.methodCount = 2,
    this.lineLength = 150,
    this.minLevel = LogLevel.trace,
    this.logName = 'APP',
    this.environment,
    this.showSequence = false,
    this.showDelta = true,
    this.showSource = false,
    this.showBorders = true,
  });

  /// Monotonic log counter (shared across loggers).
  static int _sequenceCounter = 0;

  /// Timestamp of the previous log — used for `[+Nms]` delta.
  static DateTime? _lastLogTime;

  // ─── Convenience methods ───────────────────────────────────────────

  void d(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) => log(
    LogLevel.debug,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name ?? logName,
  );
  void i(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) => log(
    LogLevel.info,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name ?? logName,
  );
  void w(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) => log(
    LogLevel.warning,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name ?? logName,
  );
  void e(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) => log(
    LogLevel.error,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name ?? logName,
  );
  void f(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) => log(
    LogLevel.fatal,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name ?? logName,
  );
  void t(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? name,
  }) => log(
    LogLevel.trace,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name ?? logName,
  );

  // ─── Core logging ─────────────────────────────────────────────────

  /// Main logging method that all subclasses should use
  void log(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    required String name,
  }) {
    if (level.index < minLevel.index) return;

    // Build a structured entry once — feeds the in-memory ring buffer and
    // the optional capture callback. Both run in debug AND release.
    final entry = LogEntry(
      seq: _sequenceCounter + 1,
      time: DateTime.now(),
      level: level,
      name: name,
      message: message,
    );
    LogBuffer.append(entry);

    if (_globalLogCaptureCallback != null) {
      _globalLogCaptureCallback!(entry);
    }

    // Pretty console output is debug-only.
    if (!kDebugMode) return;

    final formattedLines = formatLog(level, message, stackTrace, name);
    developer.log(formattedLines.join('\n'), name: name);

    // Stdout emit — gated on the [_kLogToStdout] compile-time flag.
    // IDE launches set `LOG_TO_STDOUT=false` so the Debug Console only
    // shows the formatted `developer.log` channel; terminal launches
    // leave the flag at default so colored output reaches `stdout`.
    //
    // Uses Zone.root.print to bypass the bootstrap zone's print override
    // (see lib/core/bootstrap/bootstrap_zone.dart) — calling plain print()
    // here would route back into Logger.m.d and infinite-loop.
    if (_kLogToStdout) {
      for (final line in formattedLines) {
        Zone.root.print(line);
      }
    }
  }

  /// Abstract method for formatting logs - implemented by subclasses
  List<String> formatLog(
    LogLevel level,
    String message,
    StackTrace? stackTrace,
    String name,
  );

  /// Colorizes text using ANSI color codes
  String colorize(String text, String ansiCode) {
    return colors ? '$ansiCode$text\x1B[0m' : text;
  }

  /// Gets the ANSI color code for a log level
  String getColor(LogLevel level) => switch (level) {
    .trace => colors ? '\x1B[90m' : '', // Bright black (dim)
    .debug => colors ? '\x1B[36m' : '', // Cyan
    .info => colors ? '\x1B[32m' : '', // Green
    .warning => colors ? '\x1B[33m' : '', // Yellow
    .error => colors ? '\x1B[31m' : '', // Red
    .fatal => colors ? '\x1B[95m' : '', // Bright magenta
  };

  /// Full level name for headers / compact mode.
  String _getLevelLabel(LogLevel level) => switch (level) {
    .trace => 'TRACE',
    .debug => 'DEBUG',
    .info => 'INFO',
    .warning => 'WARN',
    .error => 'ERROR',
    .fatal => 'FATAL',
  };

  /// Dim gray used for section dividers and secondary markers.
  String get _dimColor => colors ? '\x1B[90m' : '';

  /// HH:mm:ss.mmm in local time.
  String _getFormattedTimestamp() {
    final now = DateTime.now().toLocal();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final ms = now.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  /// Format inter-log delta with adaptive units and fixed width so the
  /// `[+...]` column stays vertically aligned across rows.
  ///
  /// Buckets: `<1s` → `Nms`, `<1min` → `N.Ns`, `<1h` → `MmSSs`,
  /// otherwise `HhMMm`. Right-padded to 6 chars.
  String _formatDelta(int ms) {
    final String raw;
    if (ms < 1000) {
      raw = '${ms}ms';
    } else if (ms < 60 * 1000) {
      raw = '${(ms / 1000).toStringAsFixed(1)}s';
    } else if (ms < 60 * 60 * 1000) {
      final m = ms ~/ (60 * 1000);
      final s = (ms % (60 * 1000)) ~/ 1000;
      raw = '${m}m${s.toString().padLeft(2, '0')}s';
    } else {
      final h = ms ~/ (60 * 60 * 1000);
      final m = (ms % (60 * 60 * 1000)) ~/ (60 * 1000);
      raw = '${h}h${m.toString().padLeft(2, '0')}m';
    }
    return raw.padLeft(6);
  }

  // ─── Box helpers ──────────────────────────────────────────────────────
  //
  // Pads plain text to [lineLength] BEFORE colorizing, then wraps with │.
  // Requires a monospace font (JetBrains Mono, Fira Code, etc.) in the
  // debug console for correct alignment.

  /// Pull the leading-whitespace prefix off [plain] so continuation rows can
  /// reproduce the same indent. Returns `(indent, rest)`.
  (String, String) _splitLeadingIndent(String plain) {
    var i = 0;
    while (i < plain.length && (plain[i] == ' ' || plain[i] == '\t')) {
      i++;
    }
    return (plain.substring(0, i), plain.substring(i));
  }

  /// Find a word-friendly wrap point within [text] no further than [maxLen].
  /// Breaks AFTER the last whitespace at position >= [maxLen] / 2 so wraps
  /// stay near the requested width but don't chop words in half.
  /// If no good break is found, hard-breaks at [maxLen].
  int _findWrapPoint(String text, int maxLen) {
    if (text.length <= maxLen) return text.length;
    final minAt = maxLen ~/ 2;
    for (var i = maxLen - 1; i >= minAt; i--) {
      if (text[i] == ' ' || text[i] == '\t') return i + 1;
    }
    return maxLen;
  }

  /// Wraps plain text into one or more box rows, each padded to [lineLength].
  /// Long lines are word-wrapped and continuation rows reproduce the leading
  /// indent of the first row.
  List<String> _row(String plain, String contentColor, String borderColor) {
    // Borderless: no walls, no padding, and NO wrapping — [lineLength]
    // only matters for framing; the terminal soft-wraps long lines.
    if (!showBorders) return [colorize(plain, contentColor)];
    if (plain.length <= lineLength) {
      final padded = plain.padRight(lineLength);
      return [
        '${colorize('│', borderColor)}${colorize(padded, contentColor)}${colorize('│', borderColor)}',
      ];
    }
    final (indent, _) = _splitLeadingIndent(plain);
    final rows = <String>[];
    var remaining = plain;
    var first = true;
    while (remaining.isNotEmpty) {
      final prefix = first ? '' : indent;
      final maxLen = lineLength - prefix.length;
      final end = _findWrapPoint(remaining, maxLen);
      final chunk = remaining.substring(0, end);
      remaining = remaining.substring(end);
      final visible = prefix + chunk;
      final padded = visible.padRight(lineLength);
      rows.add(
        '${colorize('│', borderColor)}${colorize(padded, contentColor)}${colorize('│', borderColor)}',
      );
      first = false;
    }
    return rows;
  }

  /// Wraps JSON-highlighted content into box rows.
  /// Uses a shared [_JsonHighlightState] so a string value that spans
  /// multiple wrapped rows stays coloured consistently.
  /// Continuation rows reproduce the leading indent of the first row.
  List<String> _rowHighlighted(String plainText, String borderColor) {
    // Borderless: single unwrapped line — see [_row].
    if (!showBorders) return [_highlightJsonSyntax(plainText)];
    if (plainText.length <= lineLength) {
      final highlighted = _highlightJsonSyntax(plainText);
      final pad = ' ' * (lineLength - plainText.length);
      return [
        '${colorize('│', borderColor)}$highlighted$pad${colorize('│', borderColor)}',
      ];
    }
    final (indent, _) = _splitLeadingIndent(plainText);
    final rows = <String>[];
    final state = _JsonHighlightState();
    var remaining = plainText;
    var first = true;
    while (remaining.isNotEmpty) {
      final prefix = first ? '' : indent;
      final maxLen = lineLength - prefix.length;
      final end = _findWrapPoint(remaining, maxLen);
      final chunk = remaining.substring(0, end);
      remaining = remaining.substring(end);
      final highlighted = _highlightJsonSyntax(chunk, state: state);
      final visibleLen = prefix.length + chunk.length;
      final pad = visibleLen < lineLength
          ? ' ' * (lineLength - visibleLen)
          : '';
      rows.add(
        '${colorize('│', borderColor)}$prefix$highlighted$pad${colorize('│', borderColor)}',
      );
      first = false;
    }
    return rows;
  }

  /// Horizontal rule: ├───...───┤ or └───...───┘
  String _hr(String left, String fill, String right, String borderColor) {
    return colorize('$left${fill * lineLength}$right', borderColor);
  }

  /// Labeled horizontal rule: `├─ Label ────────────┤`.
  /// Junctions are drawn in [borderColor]; the rule fill + label are dimmed.
  /// Borderless mode keeps a short dimmed marker so sections stay scannable.
  String _hrLabeled(String label, String borderColor, String dimColor) {
    if (!showBorders) return colorize('── $label ──', dimColor);
    final prefix = '─ $label ';
    final fill = '─' * (lineLength - prefix.length);
    return '${colorize('├', borderColor)}${colorize('$prefix$fill', dimColor)}${colorize('┤', borderColor)}';
  }

  // ─── Main formatting ────────────────────────────────────────────────

  /// Returns true if a log can be rendered as a single-line compact entry
  /// rather than a full box.
  bool _canBeCompact(
    String message,
    StackTrace? stackTrace,
    Map<String, String>? contentTypeColors,
  ) {
    if (stackTrace != null) return false;
    if (message.contains('\n')) return false;
    if (contentTypeColors != null && contentTypeColors.isNotEmpty) {
      if (_detectContentType(message.trim(), contentTypeColors) != null) {
        return false;
      }
    }
    return true;
  }

  /// HTTP methods recognized for API-log top-bar promotion.
  static final RegExp _httpMethodPattern = RegExp(
    r'^\[>\]\s+(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\b',
    caseSensitive: false,
  );

  /// HTTP status code recognized in `[!] NNN …` error lines.
  static final RegExp _httpStatusPattern = RegExp(r'^\[!\]\s+(\d{3})\b');

  /// Strip `[>]` + optional HTTP method prefix from URL lines.
  static final RegExp _urlPrefixStrip = RegExp(
    r'^(\s*)\[>\]\s+(?:GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)?\s*',
    caseSensitive: false,
  );

  /// Strip `[!]` + optional 3-digit status code from error lines.
  static final RegExp _errorPrefixStrip = RegExp(
    r'^(\s*)\[!\]\s*(?:\d{3}\s+)?',
  );

  /// Duration marker emitted by the API interceptor: `[t] 312ms`.
  static final RegExp _durationPattern = RegExp(
    r'^\[t\]\s+(\d+(?:\.\d+)?ms)\b',
  );

  /// In-string truncation marker emitted by the smart JSON formatter:
  /// `" ... +2920 chars ... "`. Rendered in dim so the break is visible
  /// against the surrounding string colour.
  static final RegExp _stringMarkerRe = RegExp(
    r' \.\.\. \+(\d+) chars \.\.\. ',
  );

  /// Bare array-truncation marker line: `... +4980 truncated ...`.
  static bool _isTruncationMarker(String trimmed) =>
      trimmed.startsWith('...') && trimmed.contains('truncated');

  /// Extract a stack-trace frame `(file:line:col)`.
  static final RegExp _stackFramePattern = RegExp(r'\(([^()]+?):(\d+):\d+\)');

  /// Stack-trace frames containing any of these substrings are skipped
  /// when resolving the caller location. Customize to hide more frameworks.
  static const List<String> _sourceSkipSubstrings = [
    'base_logger.dart',
    'loggers/logger.dart',
    'api_interceptors.dart',
    'api_service.dart',
    'package:dio/',
    'dart:async',
    '<asynchronous suspension>',
  ];

  /// Resolve the first stack frame outside the logger + common plumbing.
  /// Returns `file.dart:42` or `null` on failure.
  String? _getCallerLocation() {
    try {
      final frames = StackTrace.current.toString().split('\n');
      for (final frame in frames) {
        if (frame.isEmpty) continue;
        var skip = false;
        for (final pat in _sourceSkipSubstrings) {
          if (frame.contains(pat)) {
            skip = true;
            break;
          }
        }
        if (skip) continue;
        final match = _stackFramePattern.firstMatch(frame);
        if (match == null) continue;
        final path = match.group(1)!;
        final lineNo = match.group(2)!;
        final file = path.split('/').last;
        return '$file:$lineNo';
      }
    } catch (_) {}
    return null;
  }

  /// Common log formatting logic used by all subclasses
  List<String> buildFormattedLog(
    LogLevel level,
    String message,
    StackTrace? stackTrace,
    String name, {
    Map<String, String>? contentTypeColors,
  }) {
    final lc = getColor(level);
    final ts = _getFormattedTimestamp();
    final lvl = _getLevelLabel(level);

    // Sequence + delta housekeeping — shared across all loggers.
    _sequenceCounter++;
    final seqN = _sequenceCounter;
    final now = DateTime.now();
    final deltaMs = _lastLogTime == null
        ? null
        : now.difference(_lastLogTime!).inMilliseconds;
    _lastLogTime = now;

    // Segments that apply to both compact and box renderings.
    final baseSegments = <String>[];
    if (environment != null) baseSegments.add('[$environment]');
    if (showSequence) baseSegments.add('[#$seqN]');
    baseSegments.add('[$ts]');
    if (showDelta && deltaMs != null) {
      baseSegments.add('[+${_formatDelta(deltaMs)}]');
    }

    // Compact single-line form for simple logs.
    if (_canBeCompact(message, stackTrace, contentTypeColors)) {
      final compactSegments = [...baseSegments];
      if (showSource) {
        final src = _getCallerLocation();
        if (src != null) compactSegments.add('[$src]');
      }
      final wall = showBorders ? '${colorize('┃', lc)} ' : '';
      return [
        '$wall${colorize(lvl.padRight(5), lc)}  ${colorize(compactSegments.join(' '), _dimColor)}  ${colorize(message, lc)}',
      ];
    }

    // For API logs, pull the HTTP method out of the first [>] line, the
    // status code out of the first [!] line, and the duration out of the
    // first [t] line; promote all three into the top bar.
    String? httpMethod;
    String? httpStatus;
    String? duration;
    if (contentTypeColors != null) {
      final hasUrl = contentTypeColors.containsKey('url');
      final hasError = contentTypeColors.containsKey('error');
      for (final line in message.split('\n')) {
        final trimmed = line.trim();
        if (hasUrl && httpMethod == null && trimmed.startsWith('[>]')) {
          final match = _httpMethodPattern.firstMatch(trimmed);
          if (match != null) httpMethod = match.group(1)!.toUpperCase();
        } else if (hasError &&
            httpStatus == null &&
            trimmed.startsWith('[!]')) {
          final match = _httpStatusPattern.firstMatch(trimmed);
          if (match != null) httpStatus = match.group(1);
        } else if (duration == null && trimmed.startsWith('[t]')) {
          final match = _durationPattern.firstMatch(trimmed);
          if (match != null) duration = match.group(1);
        }
        if (httpMethod != null && httpStatus != null && duration != null) break;
      }
    }

    // Source location is expensive — resolve only when enabled.
    final src = showSource ? _getCallerLocation() : null;

    // Top: ╭[INFO]─[DEV]─[#42]─[10:35:24.021]─[+12ms]─[main.dart:42]─[GET]─[500]─[312ms]─...─╮
    final tagParts = <String>['[$lvl]', ...baseSegments];
    if (src != null) tagParts.add('[$src]');
    if (httpMethod != null) tagParts.add('[$httpMethod]');
    if (httpStatus != null) tagParts.add('[$httpStatus]');
    if (duration != null) tagParts.add('[$duration]');
    final lines = <String>[];
    if (showBorders) {
      final tag = tagParts.join('─');
      final topFill = '─' * (lineLength - tag.length);
      lines.add(colorize('╭$tag$topFill╮', lc));
    } else {
      // Header info survives without the frame — just no rule fill.
      lines.add(colorize(tagParts.join(' '), lc));
    }

    lines.addAll(_formatMessageContent(message, level, contentTypeColors));

    if (level == LogLevel.error && stackTrace != null) {
      for (final line
          in stackTrace.toString().split('\n').take(errorMethodCount)) {
        lines.addAll(_row(line, colors ? '\x1B[33m' : '', lc));
      }
    } else if (stackTrace != null) {
      for (final line in stackTrace.toString().split('\n').take(methodCount)) {
        lines.addAll(_row(line, colors ? '\x1B[36m' : '', lc));
      }
    }

    if (showBorders) lines.add(_hr('╰', '─', '╯', lc));
    return lines;
  }

  /// Formats message content with optional content type detection
  List<String> _formatMessageContent(
    String message,
    LogLevel level,
    Map<String, String>? contentTypeColors,
  ) {
    final lines = <String>[];
    final lc = getColor(level);
    final dim = _dimColor;

    if (contentTypeColors != null && contentTypeColors.isNotEmpty) {
      final parts = message.split('\n');
      var isInJsonContent = false;

      for (final part in parts) {
        final trimmedPart = part.trim();
        // Timing lines are already promoted to the top bar — hide here.
        if (trimmedPart.startsWith('[t]')) continue;

        // Array-truncation marker — render dim, keep json-context flag so
        // subsequent JSON lines stay syntax-highlighted.
        if (isInJsonContent && _isTruncationMarker(trimmedPart)) {
          lines.addAll(_row(part, dim, lc));
          continue;
        }

        final contentType = _detectContentType(trimmedPart, contentTypeColors);

        if (contentType != null) {
          isInJsonContent =
              contentType == 'response' ||
              contentType == 'headers' ||
              contentType == 'data' ||
              contentType == 'query';

          // Headers / Query / Data / Response → dim labeled divider.
          // URL / Error → standard colored content row.
          if (isInJsonContent) {
            final label =
                contentType[0].toUpperCase() + contentType.substring(1);
            lines.add(_hrLabeled(label, lc, dim));
          } else {
            final color = contentTypeColors[contentType] ?? lc;
            // Strip bracket prefixes — method/status already promoted
            // into the top bar.
            final rendered = switch (contentType) {
              'url' =>
                '  ${part.replaceFirstMapped(_urlPrefixStrip, (m) => m.group(1) ?? '')}',
              'error' => part.replaceFirstMapped(
                _errorPrefixStrip,
                (m) => m.group(1) ?? '',
              ),
              _ => part,
            };
            // Symmetric section divider before URL lines.
            if (contentType == 'url') {
              lines.add(_hrLabeled('URL', lc, dim));
            }
            lines.addAll(_row(rendered, color, lc));
          }
        } else if (isInJsonContent && _isJsonLine(trimmedPart)) {
          final indented = '  $part';
          lines.addAll(_rowHighlighted(indented, lc));
        } else {
          if (isInJsonContent &&
              trimmedPart.isNotEmpty &&
              !_isJsonLine(trimmedPart)) {
            isInJsonContent = false;
          }
          lines.addAll(_row(part, colors ? '\x1B[36m' : '', lc));
        }
      }
    } else {
      for (final line in message.split('\n')) {
        lines.addAll(_row(line, colors ? '\x1B[36m' : '', lc));
      }
    }

    return lines;
  }

  /// Detects content type based on common patterns
  String? _detectContentType(
    String line,
    Map<String, String> contentTypeColors,
  ) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) return null;

    // Bracketed prefixes for URL and error lines
    if (trimmedLine.length >= 3 && trimmedLine.codeUnitAt(0) == 0x5B) {
      if (contentTypeColors.containsKey('url') &&
          trimmedLine.startsWith('[>]')) {
        return 'url';
      }
      if (contentTypeColors.containsKey('error') &&
          trimmedLine.startsWith('[!]')) {
        return 'error';
      }
    }

    // Plain label prefixes for sections
    if (contentTypeColors.containsKey('headers') &&
        trimmedLine.startsWith('Headers:')) {
      return 'headers';
    }
    if (contentTypeColors.containsKey('query') &&
        trimmedLine.startsWith('Query:')) {
      return 'query';
    }
    if (contentTypeColors.containsKey('data') &&
        trimmedLine.startsWith('Data:')) {
      return 'data';
    }
    if (contentTypeColors.containsKey('response') &&
        trimmedLine.startsWith('Response:')) {
      return 'response';
    }
    if (contentTypeColors.containsKey('error') &&
        trimmedLine.startsWith('Error:')) {
      return 'error';
    }
    if (contentTypeColors.containsKey('error') &&
        trimmedLine.startsWith('Message:')) {
      return 'error';
    }
    if (contentTypeColors.containsKey('error') &&
        trimmedLine.startsWith('Cause:')) {
      return 'error';
    }

    return null;
  }

  /// Checks if a line appears to be JSON content
  bool _isJsonLine(String trimmedLine) {
    if (trimmedLine.isEmpty) return false;

    final firstChar = trimmedLine.codeUnitAt(0);

    // JSON structural characters: { } [ ] ,
    if (firstChar == 0x7B ||
        firstChar == 0x7D ||
        firstChar == 0x5B ||
        firstChar == 0x5D ||
        firstChar == 0x2C) {
      return true;
    }

    // JSON key-value pairs (quoted strings)
    if (firstChar == 0x22) return true; // "

    // Numbers, booleans, null
    if (firstChar >= 0x30 && firstChar <= 0x39) return true; // 0-9
    if (trimmedLine == 'true' ||
        trimmedLine == 'false' ||
        trimmedLine == 'null') {
      return true;
    }

    return false;
  }

  /// Applies syntax highlighting to JSON content using code units for performance.
  ///
  /// When [state] is provided, the highlighter continues from wherever the
  /// previous chunk left off (e.g. mid-string after a word-wrap) and updates
  /// [state] in place so the next chunk can pick up coherently.
  String _highlightJsonSyntax(String line, {_JsonHighlightState? state}) {
    if (!colors) return line;

    final st = state ?? _JsonHighlightState();
    final buffer = StringBuffer();
    final units = line.codeUnits;
    final len = units.length;
    var inString = st.inString;
    var escapeNext = st.escapeNext;
    var isKey = st.isKey;

    // Continuation from a previous chunk that ended mid-string — re-open
    // the appropriate colour so the continued content stays coloured.
    if (inString) buffer.write(isKey ? '\x1B[34m' : '\x1B[32m');

    for (var i = 0; i < len; i++) {
      final code = units[i];

      if (escapeNext) {
        buffer.writeCharCode(code);
        escapeNext = false;
        continue;
      }

      if (code == 0x5C && inString) {
        // backslash
        buffer.writeCharCode(code);
        escapeNext = true;
        continue;
      }

      if (code == 0x22) {
        // "
        if (!inString) {
          isKey = _isJsonKeyAtCodeUnits(units, i);
          buffer.write(
            isKey ? '\x1B[34m"' : '\x1B[32m"',
          ); // Blue keys, green values
        } else {
          buffer.write('"\x1B[0m');
        }
        inString = !inString;
        continue;
      }

      if (inString) {
        // Intercept the in-string truncation marker (" ... +N chars ... ")
        // and render it dim, then restore the surrounding string colour.
        if (code == 0x20 &&
            i + 4 < len &&
            units[i + 1] == 0x2E &&
            units[i + 2] == 0x2E &&
            units[i + 3] == 0x2E &&
            units[i + 4] == 0x20) {
          final m = _stringMarkerRe.matchAsPrefix(line, i);
          if (m != null) {
            final restore = isKey ? '\x1B[34m' : '\x1B[32m';
            buffer.write('\x1B[0m\x1B[90m${m.group(0)}\x1B[0m$restore');
            i += m.group(0)!.length - 1;
            continue;
          }
        }
        buffer.writeCharCode(code);
        continue;
      }

      // Not in string — structural / number / keyword detection.
      if (code == 0x7B ||
          code == 0x7D ||
          code == 0x5B ||
          code == 0x5D ||
          code == 0x2C ||
          code == 0x3A) {
        buffer.write('\x1B[37m');
        buffer.writeCharCode(code);
        buffer.write('\x1B[0m');
      } else if ((code >= 0x30 && code <= 0x39) ||
          (code == 0x2D &&
              i + 1 < len &&
              units[i + 1] >= 0x30 &&
              units[i + 1] <= 0x39)) {
        buffer.write('\x1B[33m');
        buffer.writeCharCode(code);
        while (i + 1 < len) {
          final next = units[i + 1];
          if ((next >= 0x30 && next <= 0x39) ||
              next == 0x2E ||
              next == 0x65 ||
              next == 0x45 ||
              next == 0x2B ||
              next == 0x2D) {
            i++;
            buffer.writeCharCode(units[i]);
          } else {
            break;
          }
        }
        buffer.write('\x1B[0m');
      } else if (_matchKeywordAt(line, i, 'true') ||
          _matchKeywordAt(line, i, 'false') ||
          _matchKeywordAt(line, i, 'null')) {
        final keyword = _matchKeywordAt(line, i, 'true')
            ? 'true'
            : _matchKeywordAt(line, i, 'false')
            ? 'false'
            : 'null';
        buffer.write('\x1B[35m$keyword\x1B[0m');
        i += keyword.length - 1;
      } else {
        buffer.writeCharCode(code);
      }
    }

    // Close out mid-string state cleanly for this chunk — a continuation
    // chunk will re-open the colour next time.
    if (inString) buffer.write('\x1B[0m');

    st.inString = inString;
    st.escapeNext = escapeNext;
    st.isKey = isKey;

    return buffer.toString();
  }

  /// Determines if a string starting at the given position is a JSON key (code unit version)
  bool _isJsonKeyAtCodeUnits(List<int> units, int quoteStart) {
    var j = quoteStart + 1;
    while (j < units.length && units[j] != 0x22) {
      if (units[j] == 0x5C) j++; // skip escaped char
      j++;
    }
    if (j >= units.length) return false;

    // Skip whitespace after closing quote
    var colonPos = j + 1;
    while (colonPos < units.length &&
        (units[colonPos] == 0x20 || units[colonPos] == 0x09)) {
      colonPos++;
    }

    return colonPos < units.length && units[colonPos] == 0x3A; // :
  }

  /// Checks if a keyword matches at a given position with proper boundary
  bool _matchKeywordAt(String line, int position, String keyword) {
    if (!line.startsWith(keyword, position)) return false;
    final endPos = position + keyword.length;
    if (endPos >= line.length) return true;
    final nextChar = line.codeUnitAt(endPos);
    // Must be followed by whitespace, comma, }, or ]
    return nextChar == 0x20 ||
        nextChar == 0x09 ||
        nextChar == 0x2C ||
        nextChar == 0x7D ||
        nextChar == 0x5D ||
        nextChar == 0x0A;
  }
}

// ─── MainLogger ──────────────────────────────────────────────────────

/// Main application logger for general purpose logging.
class MainLogger extends BaseLogger {
  MainLogger({
    super.colors,
    super.errorMethodCount,
    super.methodCount,
    super.lineLength,
    super.minLevel,
    super.logName = 'APP',
    super.environment,
    super.showSequence,
    super.showDelta,
    super.showSource,
    super.showBorders,
  });

  @override
  List<String> formatLog(
    LogLevel level,
    String message,
    StackTrace? stackTrace,
    String name,
  ) => buildFormattedLog(level, message, stackTrace, name);
}

// ─── ApiLogger ───────────────────────────────────────────────────────

/// API-specific logger with content-type-aware formatting and JSON highlighting.
class ApiLogger extends BaseLogger {
  final Map<String, String> contentTypeColors;

  static const defaultContentTypeColors = {
    'url': '\x1B[96m', // Bright cyan
    'headers': '\x1B[36m',
    'query': '\x1B[36m',
    'response': '\x1B[32m',
    'data': '\x1B[33m',
    'error': '\x1B[31m',
  };

  ApiLogger({
    super.colors,
    super.errorMethodCount,
    super.methodCount,
    super.lineLength,
    super.minLevel,
    super.logName = 'API',
    super.environment,
    super.showSequence,
    super.showDelta,
    super.showSource,
    super.showBorders,
    Map<String, String>? contentTypeColors,
  }) : contentTypeColors = contentTypeColors ?? defaultContentTypeColors;

  /// Log with explicit level
  void l(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    required String name,
  }) => super.log(
    level,
    message,
    error: error,
    stackTrace: stackTrace,
    name: name,
  );

  @override
  List<String> formatLog(
    LogLevel level,
    String message,
    StackTrace? stackTrace,
    String name,
  ) => buildFormattedLog(
    level,
    message,
    stackTrace,
    name,
    contentTypeColors: contentTypeColors,
  );
}
