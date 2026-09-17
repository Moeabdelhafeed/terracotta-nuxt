import 'package:flutter/material.dart';

import '../../../../core/utils/loggers/log_buffer.dart';
import '../debug_overlay_models.dart';

/// A rich renderer for a [LogEntry]'s message body.
///
/// Parses the raw message once, extracts the HTTP method/status so the tile
/// can show them as pills, strips `[>]` / `[!]` / `[t]` markers, turns
/// `Headers:` / `Query:` / `Data:` / `Response:` into labeled dividers and
/// colorizes JSON lines with the same palette as a debug console.
class LogMessageView extends StatelessWidget {
  const LogMessageView({
    super.key,
    required this.render,
    required this.expanded,
  });

  final LogRender render;

  /// When `false`, only the first [LogRender.collapsedLineCount] lines
  /// are shown.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final lines = expanded
        ? render._lines
        : render._lines.take(LogRender.collapsedLineCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _renderLine(line),
          ),
      ],
    );
  }

  Widget _renderLine(_Line line) {
    return switch (line) {
      _UrlLine(:final url) => Text(
        url,
        style: DebugOverlayTheme.mono.copyWith(
          color: const Color(0xFF4FC9FF),
          fontSize: 11.5,
        ),
        softWrap: true,
      ),
      _SectionLine(:final name) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: _SectionDivider(label: name),
      ),
      _ErrorLine(:final text) => Text(
        text,
        style: DebugOverlayTheme.mono.copyWith(
          color: const Color(0xFFEF5350),
          fontSize: 11.5,
        ),
      ),
      _MarkerLine(:final text) => Text(
        text,
        style: DebugOverlayTheme.mono.copyWith(
          color: DebugOverlayTheme.textDim,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
      _JsonLine(:final raw) => RichText(
        text: TextSpan(
          style: DebugOverlayTheme.mono.copyWith(fontSize: 11.5),
          children: _buildJsonSpans(raw),
        ),
      ),
      _PlainLine(:final text) => Text(
        text,
        style: DebugOverlayTheme.mono.copyWith(fontSize: 11.5),
        maxLines: expanded ? null : 3,
        overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    };
  }
}

/// Parsed representation of a log message — computed once per entry so
/// the tile can cheaply decide whether to show an expand affordance and
/// whether HTTP method/status pills are available.
class LogRender {
  LogRender._({
    required List<_Line> lines,
    required this.method,
    required this.status,
    required this.totalSourceLines,
  }) : _lines = lines;

  /// Number of source lines shown when the tile is collapsed.
  static const int collapsedLineCount = 2;

  /// Visual segments to render (internal — consumed by [LogMessageView]).
  final List<_Line> _lines;

  /// HTTP method extracted from a `[>] METHOD …` line, if any.
  final String? method;

  /// HTTP status code extracted from a `[!] NNN …` line, if any.
  final String? status;

  /// Original number of lines in the source message (before truncation).
  /// Used to decide whether the expand affordance is needed.
  final int totalSourceLines;

  bool get isExpandable => totalSourceLines > collapsedLineCount;

  static final _methodRe = RegExp(
    r'^\[>\]\s+(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\b',
    caseSensitive: false,
  );
  static final _statusRe = RegExp(r'^\[!\]\s+(\d{3})\b');
  static final _urlStripRe = RegExp(
    r'^(\s*)\[>\]\s+(?:GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)?\s*',
    caseSensitive: false,
  );
  static final _errorStripRe = RegExp(r'^(\s*)\[!\]\s*(?:\d{3}\s+)?');

  static LogRender parse(LogEntry entry) {
    final rawLines = entry.message.split('\n');
    String? method;
    String? status;
    final out = <_Line>[];
    var inJson = false;

    for (final line in rawLines) {
      final trimmed = line.trim();

      // Timing markers are surfaced in the tile's header — drop from body.
      if (trimmed.startsWith('[t]')) continue;

      // Request URL with optional method.
      if (trimmed.startsWith('[>]')) {
        final m = _methodRe.firstMatch(trimmed);
        method ??= m?.group(1)?.toUpperCase();
        final stripped = line.replaceFirst(_urlStripRe, '');
        out.add(_UrlLine(stripped.trim()));
        inJson = false;
        continue;
      }

      // Error URL with status.
      if (trimmed.startsWith('[!]')) {
        final m = _statusRe.firstMatch(trimmed);
        status ??= m?.group(1);
        final stripped = line.replaceFirst(_errorStripRe, '');
        out.add(_UrlLine(stripped.trim()));
        inJson = false;
        continue;
      }

      // Section markers — become labeled dividers, flip json context on.
      if (trimmed.startsWith('Headers:')) {
        out.add(const _SectionLine('Headers'));
        inJson = true;
        continue;
      }
      if (trimmed.startsWith('Query:')) {
        out.add(const _SectionLine('Query'));
        inJson = true;
        continue;
      }
      if (trimmed.startsWith('Data:')) {
        out.add(const _SectionLine('Data'));
        inJson = true;
        continue;
      }
      if (trimmed.startsWith('Response:')) {
        out.add(const _SectionLine('Response'));
        inJson = true;
        continue;
      }

      // Error detail lines.
      if (trimmed.startsWith('Error:') ||
          trimmed.startsWith('Message:') ||
          trimmed.startsWith('Cause:') ||
          trimmed.startsWith('Type:')) {
        out.add(_ErrorLine(line));
        inJson = false;
        continue;
      }

      // Array-truncation marker.
      if (trimmed.startsWith('...') && trimmed.contains('truncated')) {
        out.add(_MarkerLine(line));
        continue;
      }

      // JSON body line (only when we're in a json section).
      if (inJson && _isJsonLine(trimmed)) {
        out.add(_JsonLine(line));
        continue;
      }

      if (inJson && trimmed.isNotEmpty && !_isJsonLine(trimmed)) {
        inJson = false;
      }
      out.add(_PlainLine(line));
    }

    return LogRender._(
      lines: out,
      method: method,
      status: status,
      totalSourceLines: rawLines.length,
    );
  }
}

// ─── Line variants ─────────────────────────────────────────────

sealed class _Line {
  const _Line();
}

class _UrlLine extends _Line {
  const _UrlLine(this.url);
  final String url;
}

class _SectionLine extends _Line {
  const _SectionLine(this.name);
  final String name;
}

class _ErrorLine extends _Line {
  const _ErrorLine(this.text);
  final String text;
}

class _MarkerLine extends _Line {
  const _MarkerLine(this.text);
  final String text;
}

class _JsonLine extends _Line {
  const _JsonLine(this.raw);
  final String raw;
}

class _PlainLine extends _Line {
  const _PlainLine(this.text);
  final String text;
}

// ─── Section divider ───────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: DebugOverlayTheme.ui.copyWith(
            color: DebugOverlayTheme.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Divider(
            color: DebugOverlayTheme.border,
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ─── JSON syntax highlighting (Flutter-side) ───────────────────

// Colors tuned for dark-terminal-style highlighting, matching the pretty
// console output as closely as the UI layer allows.
const _jsonKey = TextStyle(color: Color(0xFF4FC3F7)); // blue
const _jsonString = TextStyle(color: Color(0xFF81C784)); // green
const _jsonNumber = TextStyle(color: Color(0xFFFFB74D)); // amber
const _jsonStruct = TextStyle(color: Color(0xFFCCCCCC)); // light gray
const _jsonKeyword = TextStyle(color: Color(0xFFBA68C8)); // purple
const _jsonDim = TextStyle(color: DebugOverlayTheme.textDim);
const _jsonPlain = TextStyle(color: DebugOverlayTheme.text);

List<TextSpan> _buildJsonSpans(String line) {
  final spans = <TextSpan>[];
  final units = line.codeUnits;
  final len = units.length;
  var inString = false;
  var escapeNext = false;
  var isKey = false;
  final buf = StringBuffer();
  var currentStyle = _jsonPlain;

  void flush() {
    if (buf.isEmpty) return;
    spans.add(TextSpan(text: buf.toString(), style: currentStyle));
    buf.clear();
  }

  void emit(String text, TextStyle style) {
    if (!identical(currentStyle, style)) {
      flush();
      currentStyle = style;
    }
    buf.write(text);
  }

  for (var i = 0; i < len; i++) {
    final code = units[i];

    if (escapeNext) {
      emit(String.fromCharCode(code), currentStyle);
      escapeNext = false;
      continue;
    }
    if (code == 0x5C && inString) {
      emit(r'\', currentStyle);
      escapeNext = true;
      continue;
    }

    if (code == 0x22) {
      if (!inString) {
        isKey = _isJsonKeyAt(units, i);
      }
      emit('"', isKey ? _jsonKey : _jsonString);
      inString = !inString;
      continue;
    }

    if (inString) {
      // In-string truncation marker  " ... +N chars ... "
      if (code == 0x20 &&
          i + 4 < len &&
          units[i + 1] == 0x2E &&
          units[i + 2] == 0x2E &&
          units[i + 3] == 0x2E &&
          units[i + 4] == 0x20) {
        final m = _stringMarkerRe.matchAsPrefix(line, i);
        if (m != null) {
          emit(m.group(0)!, _jsonDim);
          i += m.group(0)!.length - 1;
          continue;
        }
      }
      emit(String.fromCharCode(code), isKey ? _jsonKey : _jsonString);
      continue;
    }

    // Not in string — structural / number / keyword detection.
    if (code == 0x7B ||
        code == 0x7D ||
        code == 0x5B ||
        code == 0x5D ||
        code == 0x2C ||
        code == 0x3A) {
      emit(String.fromCharCode(code), _jsonStruct);
      continue;
    }
    if ((code >= 0x30 && code <= 0x39) ||
        (code == 0x2D &&
            i + 1 < len &&
            units[i + 1] >= 0x30 &&
            units[i + 1] <= 0x39)) {
      final start = i;
      while (i + 1 < len) {
        final next = units[i + 1];
        if ((next >= 0x30 && next <= 0x39) ||
            next == 0x2E ||
            next == 0x65 ||
            next == 0x45 ||
            next == 0x2B ||
            next == 0x2D) {
          i++;
        } else {
          break;
        }
      }
      emit(line.substring(start, i + 1), _jsonNumber);
      continue;
    }
    if (_matchKeywordAt(line, i, 'true') ||
        _matchKeywordAt(line, i, 'false') ||
        _matchKeywordAt(line, i, 'null')) {
      final kw = _matchKeywordAt(line, i, 'true')
          ? 'true'
          : _matchKeywordAt(line, i, 'false')
          ? 'false'
          : 'null';
      emit(kw, _jsonKeyword);
      i += kw.length - 1;
      continue;
    }
    emit(String.fromCharCode(code), _jsonPlain);
  }

  flush();
  return spans;
}

final _stringMarkerRe = RegExp(r' \.\.\. \+(\d+) chars \.\.\. ');

bool _isJsonLine(String trimmedLine) {
  if (trimmedLine.isEmpty) return false;
  final f = trimmedLine.codeUnitAt(0);
  if (f == 0x7B || f == 0x7D || f == 0x5B || f == 0x5D || f == 0x2C) {
    return true;
  }
  if (f == 0x22) return true;
  if (f >= 0x30 && f <= 0x39) return true;
  if (trimmedLine == 'true' ||
      trimmedLine == 'false' ||
      trimmedLine == 'null') {
    return true;
  }
  return false;
}

bool _isJsonKeyAt(List<int> units, int quoteStart) {
  var j = quoteStart + 1;
  while (j < units.length && units[j] != 0x22) {
    if (units[j] == 0x5C) j++;
    j++;
  }
  if (j >= units.length) return false;
  var cp = j + 1;
  while (cp < units.length && (units[cp] == 0x20 || units[cp] == 0x09)) {
    cp++;
  }
  return cp < units.length && units[cp] == 0x3A;
}

bool _matchKeywordAt(String line, int pos, String kw) {
  if (!line.startsWith(kw, pos)) return false;
  final end = pos + kw.length;
  if (end >= line.length) return true;
  final c = line.codeUnitAt(end);
  return c == 0x20 ||
      c == 0x09 ||
      c == 0x2C ||
      c == 0x7D ||
      c == 0x5D ||
      c == 0x0A;
}
