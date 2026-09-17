import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/loggers/logger.dart';

/// Folds repeated errors into a count instead of a flood.
///
/// ## Why this exists
///
/// A single bad widget throws from `build` / `layout` / `paint` on EVERY
/// frame. At 60fps that is 60 identical stack traces per second, which:
///
///  - buries the FIRST occurrence — the only one whose context is
///    useful — under thousands of copies,
///  - scrolls the terminal so fast that selecting text to copy is
///    impossible, so the only way out is killing the app,
///  - evicts the entire [LogBuffer] ring in under ten seconds, taking
///    the preceding history (the part that explains how you got there)
///    with it,
///  - and, in a release build, ships thousands of identical records to
///    the crash backend.
///
/// This has bitten this codebase repeatedly — a non-uniform `Border`
/// with a `borderRadius`, an unbounded `OverflowBox`, a `Positioned`
/// under a non-`Stack` parent. Each was a one-line fix behind an
/// unreadable wall of output.
///
/// ## What it does
///
/// Every error is fingerprinted (type + digit-normalized message + top
/// stack frames). The first [burst] occurrences of a fingerprint print
/// in full; the rest are counted and reported as a periodic one-line
/// summary. A fingerprint that goes quiet for [forget] is dropped, so a
/// recurrence after a pause prints in full again — a returning bug is
/// news, not noise.
///
/// Digits are normalized out of both message and frames on purpose:
/// "overflowed by 3.5 pixels" and "by 118 pixels" are one bug, and line
/// numbers shift under hot reload while the bug does not.
///
/// A second, global cap ([globalPerSecond]) covers the case dedup cannot:
/// errors whose fingerprints all DIFFER (a loop that throws with a fresh
/// message each time). Past the cap nothing prints until the next second,
/// and the drop count is reported.
///
/// ## What it does not do
///
/// It never silences the first sighting of anything, and it never
/// changes behaviour — errors still propagate, red screens still paint.
/// It only decides what reaches the console and the crash reporter.
class ErrorStorm {
  ErrorStorm._();

  /// Occurrences of one fingerprint printed in full before folding.
  /// More than one because a second copy often carries a different
  /// `informationCollector` context than the first.
  static int burst = 3;

  /// How often folded counts are flushed as a summary line.
  static Duration summaryEvery = const Duration(seconds: 5);

  /// Silence after which a fingerprint is forgotten and prints fully
  /// again.
  static Duration forget = const Duration(seconds: 30);

  /// Hard ceiling on full error prints per second across ALL
  /// fingerprints — the backstop for storms that defeat dedup.
  static int globalPerSecond = 30;

  /// Fingerprints tracked at once. Oldest is evicted past this, so a
  /// pathological storm cannot grow the map without bound.
  static int maxSignatures = 128;

  /// Where summary lines go. Overridable so tests can assert on them
  /// without a logger.
  @visibleForTesting
  static void Function(String message) sink = (m) => Logger.m.w(m);

  /// Clock, injectable so tests need no real elapsed time.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  static final Map<String, _Signature> _signatures = <String, _Signature>{};
  static Timer? _flushTimer;
  static DateTime? _windowStart;
  static int _windowPrinted = 0;
  static int _windowDropped = 0;

  /// Decides how one occurrence should be handled.
  ///
  /// Call once per error, BEFORE logging — the whole point is to keep
  /// the suppressed copies out of the logger and its ring buffer.
  static StormVerdict admit(Object exception, StackTrace? stack) {
    final at = now();
    _rollWindow(at);

    final key = _fingerprint(exception, stack);
    var sig = _signatures[key];
    if (sig != null && at.difference(sig.last) > forget) {
      _signatures.remove(key);
      sig = null;
    }
    if (sig == null) {
      sig = _Signature(first: at, label: _label(exception));
      _signatures[key] = sig;
      while (_signatures.length > maxSignatures) {
        _signatures.remove(_signatures.keys.first);
      }
    }

    sig
      ..count += 1
      ..last = at;

    var print = sig.printed < burst;
    if (print && _windowPrinted >= globalPerSecond) {
      // Distinct fingerprints arriving faster than anyone can read.
      print = false;
      _windowDropped += 1;
    }

    if (print) {
      sig.printed += 1;
      _windowPrinted += 1;
      return StormVerdict._(
        log: true,
        report: true,
        occurrence: sig.count,
        // Warn on the LAST verbose copy, so nobody concludes the
        // problem stopped when the output does.
        suffix: sig.printed == burst
            ? '\n[ErrorStorm] further identical errors will be counted, '
                  'not printed — summary every '
                  '${summaryEvery.inSeconds}s.'
            : '',
      );
    }

    sig.pending += 1;
    _arm();
    return StormVerdict._(
      log: false,
      report: false,
      occurrence: sig.count,
      suffix: '',
    );
  }

  /// Emits a summary for every fingerprint with folded occurrences and
  /// clears the counts. Called automatically; public so a debug tool can
  /// force a flush.
  static void flush() {
    for (final sig in _signatures.values) {
      if (sig.pending == 0) continue;
      sink(
        '[ErrorStorm] ${sig.pending} more (${sig.count} total since '
        '${_hms(sig.first)}): ${sig.label}',
      );
      sig.pending = 0;
    }
    if (_windowDropped > 0) {
      sink(
        '[ErrorStorm] $_windowDropped distinct errors dropped by the '
        '$globalPerSecond/s cap',
      );
      _windowDropped = 0;
    }
  }

  /// Drops all state — every fingerprint prints in full again.
  ///
  /// Wired to hot reload: after an edit you want to know immediately
  /// whether the fix took, not wait out a [forget] window.
  static void reset() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _signatures.clear();
    _windowStart = null;
    _windowPrinted = 0;
    _windowDropped = 0;
  }

  /// Live counts per fingerprint, most-recent first — for a debug view.
  static List<StormEntry> snapshot() {
    final list =
        _signatures.values
            .map(
              (s) => StormEntry(
                label: s.label,
                count: s.count,
                first: s.first,
                last: s.last,
              ),
            )
            .toList()
          ..sort((a, b) => b.last.compareTo(a.last));
    return List.unmodifiable(list);
  }

  static void _rollWindow(DateTime at) {
    final start = _windowStart;
    if (start != null && at.difference(start) < const Duration(seconds: 1)) {
      return;
    }
    _windowStart = at;
    _windowPrinted = 0;
  }

  static void _arm() {
    if (_flushTimer != null) return;
    _flushTimer = Timer(summaryEvery, () {
      _flushTimer = null;
      flush();
    });
  }

  /// Matches a whole number OR a decimal — `3.5` and `118` must collapse
  /// to the SAME token, or "overflowed by 3.5 pixels" and "by 118
  /// pixels" fingerprint as two different bugs.
  static final RegExp _digits = RegExp(r'\d+(?:\.\d+)?');

  static String _fingerprint(Object exception, StackTrace? stack) {
    final message = _clip(exception.toString(), 160).replaceAll(_digits, '#');
    return '${exception.runtimeType}|$message|${_topFrames(stack, 3)}';
  }

  static String _topFrames(StackTrace? stack, int count) {
    if (stack == null) return '';
    final out = <String>[];
    for (final line in stack.toString().split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      out.add(trimmed.replaceAll(_digits, '#'));
      if (out.length == count) break;
    }
    return out.join(';');
  }

  static String _label(Object exception) =>
      _clip(exception.toString().split('\n').first, 120);

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';

  static String _hms(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}

/// What to do with one error occurrence.
@immutable
class StormVerdict {
  const StormVerdict._({
    required this.log,
    required this.report,
    required this.occurrence,
    required this.suffix,
  });

  /// Write this one to the console / log buffer.
  final bool log;

  /// Forward this one to the crash reporter.
  final bool report;

  /// 1-based count for this fingerprint since it was first seen.
  final int occurrence;

  /// Text to append to the logged message — empty except on the last
  /// verbose copy, where it explains that folding starts now.
  final String suffix;
}

/// One fingerprint's tally, for debug UIs.
@immutable
class StormEntry {
  const StormEntry({
    required this.label,
    required this.count,
    required this.first,
    required this.last,
  });

  final String label;
  final int count;
  final DateTime first;
  final DateTime last;
}

class _Signature {
  _Signature({required this.first, required this.label}) : last = first;

  final DateTime first;
  final String label;
  DateTime last;
  int count = 0;
  int printed = 0;
  int pending = 0;
}
