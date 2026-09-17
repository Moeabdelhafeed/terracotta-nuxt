import 'package:flutter/painting.dart' show Color;

/// Session-scoped recently-picked colors (in-memory, NOT persisted across app
/// restarts). Newest first, de-duplicated, capped at [max]. Shared by the
/// color picker across every color field.
abstract final class RecentColors {
  static const int max = 12;
  static final List<Color> _list = [];

  static List<Color> get all => List.unmodifiable(_list);

  /// Record [color] as the most recent pick (moves an existing one to front).
  static void add(Color color) {
    final rgb = color.toARGB32();
    _list.removeWhere((c) => c.toARGB32() == rgb);
    _list.insert(0, color);
    if (_list.length > max) _list.removeRange(max, _list.length);
  }

  /// Clears the history (test hook / user action).
  static void clear() => _list.clear();
}
