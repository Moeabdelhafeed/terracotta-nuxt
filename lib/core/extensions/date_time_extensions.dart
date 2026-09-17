import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../data/services/preferences/locale_service.dart';
import '../di/service_locator.dart';

/// Active language code — resolved from [LocaleService]; falls back
/// to Intl's default, then `'en'`. Never throws.
String _locale() {
  if (getIt.isRegistered<LocaleService>()) {
    return getIt<LocaleService>().languageCode;
  }
  return Intl.defaultLocale ?? 'en';
}

/// Locale-aware formatting on [DateTime].
///
/// ```dart
/// post.createdAt.ago;        // "3 hours ago"  / "منذ 3 ساعات"
/// event.startsAt.fromNow;    // "in 2 days"    / "في غضون يومين"
/// post.createdAt.formatDate; // "Apr 18, 2026"
/// ```
extension DateTimeExtensions on DateTime {
  /// Time only, short form (e.g. `"3:45 PM"`).
  String get formatTime => DateFormat.jm(_locale()).format(this);

  /// Time with seconds (e.g. `"3:45:21 PM"`).
  String get formatTimeWithSeconds => DateFormat.jms(_locale()).format(this);

  /// Short date (e.g. `"Apr 18, 2026"`).
  String get formatDate => DateFormat.yMMMd(_locale()).format(this);

  /// Short date + time (e.g. `"Apr 18, 2026 3:45 PM"`).
  String get formatDateTime =>
      DateFormat.yMMMd(_locale()).add_jm().format(this);

  /// Format with an arbitrary [DateFormat] pattern in the current locale.
  /// Prefer the named getters above when possible — they stay correct
  /// across locales automatically.
  String formatWith(String pattern) =>
      DateFormat(pattern, _locale()).format(this);

  // ─── Relative time (localized via `timeago`) ────────────────────

  /// Relative-past label for a date in the past, e.g. `"3 hours ago"`.
  /// Localized — make sure `main.dart` registers the language's
  /// `timeago` messages at boot.
  String get ago => timeago.format(this, locale: _locale());

  /// Relative-future label for a date in the future, e.g. `"in 2 days"`.
  String get fromNow =>
      timeago.format(this, locale: _locale(), allowFromNow: true);
}

/// Locale-aware helpers on [TimeOfDay].
extension TimeOfDayExtensions on TimeOfDay {
  /// Build a [DateTime] from this time (using a dummy date), so it can be
  /// passed to [DateFormat].
  DateTime get asDateTime => DateTime(2000, 1, 1, hour, minute);
}
