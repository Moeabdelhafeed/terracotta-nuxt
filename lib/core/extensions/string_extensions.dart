/// String utility extensions.
///
/// Validation-heavy logic (phone, password, email with error messages) lives in
/// `core/utils/validators/validators.dart`. These extensions are lightweight
/// convenience methods for common string transforms.

extension StringExtensions on String {
  // ─── Casing ─────────────────────────────────────────────────

  /// Capitalize the first character: "hello" → "Hello".
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Capitalize the first letter of each word: "hello world" → "Hello World".
  String get capitalizedWords => split(' ').map((w) => w.capitalized).join(' ');

  /// Convert to URL-safe slug: "Hello World!" → "hello-world".
  String get toSlug => trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'[\s_]+'), '-')
      .replaceAll(RegExp(r'-{2,}'), '-');

  /// camelCase → snake_case: "createdAt" → "created_at".
  String get toSnakeCase => replaceAllMapped(
    RegExp('(?<=[a-z])[A-Z]'),
    (m) => '_${m[0]}',
  ).toLowerCase();

  /// snake_case → camelCase: "created_at" → "createdAt".
  String get toCamelCase {
    final parts = split('_');
    if (parts.length <= 1) return toLowerCase();
    return parts.first.toLowerCase() +
        parts.skip(1).map((p) => p.capitalized).join();
  }

  // ─── Truncation ─────────────────────────────────────────────

  /// Truncate to [maxLength] and append [ellipsis] if needed.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  // ─── Validation (lightweight — Unicode-aware checks live in `Validators`) ──

  static final _numericRegex = RegExp(r'^\d+$');
  static final _htmlTag = RegExp(r'<[^>]*>');

  bool get isNumeric => _numericRegex.hasMatch(this);
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => !isBlank;

  // ─── Transforms ─────────────────────────────────────────────

  /// Strip HTML tags: "<b>Hi</b>" → "Hi".
  String get removeHtml => replaceAll(_htmlTag, '');

  /// Extract initials (up to [count]) from words: "John Doe" → "JD".
  String initials({int count = 2}) {
    final words = trim().split(RegExp(r'\s+'));
    return words
        .take(count)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
  }

  /// Reverse the string.
  String get reversed => split('').reversed.join();

  /// Return null if blank, otherwise this.
  String? get nullIfBlank => isBlank ? null : this;
}

/// Nullable string helpers.
extension NullableStringExtensions on String? {
  /// True when null or blank.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// True when not null and not blank.
  bool get isNotNullOrBlank => !isNullOrBlank;

  /// Returns this if not blank, otherwise [fallback].
  String orDefault(String fallback) => isNullOrBlank ? fallback : this!;
}
