import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// WCAG contrast-ratio thresholds — the minimum foreground/background
/// ratio that passes the given level + text-size combination.
///
/// Reference: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html
enum WcagLevel { aa, aaa }

extension WcagLevelX on WcagLevel {
  /// Minimum ratio for normal body text (<18pt, or <14pt bold).
  double get normalText => switch (this) {
    WcagLevel.aa => 4.5,
    WcagLevel.aaa => 7.0,
  };

  /// Minimum ratio for large text (≥18pt, or ≥14pt bold).
  double get largeText => switch (this) {
    WcagLevel.aa => 3.0,
    WcagLevel.aaa => 4.5,
  };
}

/// One entry in a contrast audit report — either passes or explains
/// which threshold it missed.
@immutable
class ContrastReport {
  const ContrastReport({
    required this.label,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.level,
    required this.largeText,
    required this.passes,
  });

  /// Human-readable label for the pair (e.g. `'onPrimary on primary'`).
  final String label;
  final Color foreground;
  final Color background;

  /// Measured contrast ratio in the `[1, 21]` range.
  final double ratio;

  /// Target WCAG level for the audit.
  final WcagLevel level;

  /// Whether the pair was evaluated at the large-text threshold.
  final bool largeText;

  /// True when [ratio] meets the target threshold.
  final bool passes;

  double get required => largeText ? level.largeText : level.normalText;

  @override
  String toString() {
    final status = passes ? 'PASS' : 'FAIL';
    return '[$status] $label — ${ratio.toStringAsFixed(2)}:1 '
        '(need ${required.toStringAsFixed(1)}:1 at ${level.name.toUpperCase()} '
        '${largeText ? 'large' : 'normal'})';
  }
}

/// Static helpers for WCAG 2.1 contrast calculations.
///
/// ```dart
/// final r = ContrastChecker.ratio(Colors.white, Colors.black);  // 21.0
/// ContrastChecker.passesAA(fg, bg);            // body text
/// ContrastChecker.passesAA(fg, bg, largeText: true);
/// ```
class ContrastChecker {
  ContrastChecker._();

  /// Relative luminance per WCAG 2.1 — the value fed into the ratio
  /// formula. Ignores alpha; compose against the expected backdrop
  /// before calling if your colors are translucent.
  static double luminance(Color color) {
    double channel(double c) {
      return c <= 0.03928
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// Contrast ratio between two colors. Result is in `[1, 21]`; the
  /// argument order doesn't matter.
  static double ratio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool passesAA(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    return ratio(foreground, background) >=
        (largeText ? WcagLevel.aa.largeText : WcagLevel.aa.normalText);
  }

  static bool passesAAA(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    return ratio(foreground, background) >=
        (largeText ? WcagLevel.aaa.largeText : WcagLevel.aaa.normalText);
  }

  /// Evaluate a single pair against [level].
  static ContrastReport check({
    required String label,
    required Color foreground,
    required Color background,
    WcagLevel level = WcagLevel.aa,
    bool largeText = false,
  }) {
    final r = ratio(foreground, background);
    final threshold = largeText ? level.largeText : level.normalText;
    return ContrastReport(
      label: label,
      foreground: foreground,
      background: background,
      ratio: r,
      level: level,
      largeText: largeText,
      passes: r >= threshold,
    );
  }

  /// Audit the core color pairs in [scheme] — returns one [ContrastReport]
  /// per pair. In debug builds, prints a `⚠ a11y` warning for every
  /// failure via [debugPrint]; release builds are silent (reports are
  /// still returned so callers can integrate with their own reporting).
  ///
  /// Call from your app bootstrap after the theme resolves:
  ///
  /// ```dart
  /// if (kDebugMode) {
  ///   ContrastChecker.auditColorScheme(theme.colorScheme);
  /// }
  /// ```
  static List<ContrastReport> auditColorScheme(
    ColorScheme scheme, {
    WcagLevel level = WcagLevel.aa,
    bool printInDebug = true,
  }) {
    final pairs = <(String, Color, Color)>[
      ('onPrimary on primary', scheme.onPrimary, scheme.primary),
      (
        'onPrimaryContainer on primaryContainer',
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
      ),
      ('onSecondary on secondary', scheme.onSecondary, scheme.secondary),
      (
        'onSecondaryContainer on secondaryContainer',
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
      ),
      ('onTertiary on tertiary', scheme.onTertiary, scheme.tertiary),
      (
        'onTertiaryContainer on tertiaryContainer',
        scheme.onTertiaryContainer,
        scheme.tertiaryContainer,
      ),
      ('onSurface on surface', scheme.onSurface, scheme.surface),
      (
        'onSurfaceVariant on surfaceContainerHighest',
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      ('onError on error', scheme.onError, scheme.error),
      (
        'onErrorContainer on errorContainer',
        scheme.onErrorContainer,
        scheme.errorContainer,
      ),
      (
        'onInverseSurface on inverseSurface',
        scheme.onInverseSurface,
        scheme.inverseSurface,
      ),
    ];

    final reports = [
      for (final (label, fg, bg) in pairs)
        check(label: label, foreground: fg, background: bg, level: level),
    ];

    if (printInDebug && kDebugMode) {
      for (final r in reports.where((r) => !r.passes)) {
        debugPrint('⚠ a11y  $r');
      }
    }

    return reports;
  }

  /// Convenience: audit an entire [ThemeData] (both [ThemeData.colorScheme]
  /// and the most common text-on-surface pairs derived from the text
  /// theme). Use on startup when you want a one-shot pass.
  static List<ContrastReport> auditTheme(
    ThemeData theme, {
    WcagLevel level = WcagLevel.aa,
    bool printInDebug = true,
  }) {
    final reports = auditColorScheme(
      theme.colorScheme,
      level: level,
      printInDebug: false,
    );

    final bodyColor = theme.textTheme.bodyMedium?.color;
    if (bodyColor != null) {
      reports.add(
        check(
          label: 'bodyMedium on surface',
          foreground: bodyColor,
          background: theme.colorScheme.surface,
          level: level,
        ),
      );
    }
    final titleColor = theme.textTheme.titleLarge?.color;
    if (titleColor != null) {
      reports.add(
        check(
          label: 'titleLarge on surface',
          foreground: titleColor,
          background: theme.colorScheme.surface,
          level: level,
          largeText: true,
        ),
      );
    }

    if (printInDebug && kDebugMode) {
      for (final r in reports.where((r) => !r.passes)) {
        debugPrint('⚠ a11y  $r');
      }
    }

    return reports;
  }
}
