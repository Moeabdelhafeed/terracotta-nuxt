import 'package:intl/intl.dart';

/// Inline plural selection — for cases where you need plural-aware
/// output **without** going through an ARB key + [S.current]. Wraps
/// [Intl.plural] / [Intl.pluralLogic] with locale auto-resolution.
///
/// For ARB-keyed plurals, prefer `Tr.plural('cart_items', count, ...)`
/// — it honors remote overrides and is what feature namespaces use.
/// [AppPlural] is the escape hatch for ad-hoc strings that don't
/// deserve an ARB entry.
///
/// ```dart
/// // String plural
/// final msg = AppPlural.string(items.length,
///   zero: 'Your cart is empty',
///   one: '1 item in cart',
///   other: '${items.length} items in cart',
/// );
///
/// // Typed plural — choose any object per category
/// final icon = AppPlural.select<IconData>(count,
///   zero: Icons.inbox,
///   one: Icons.mail,
///   other: Icons.mail_outline,
/// );
///
/// // Category-only (returns 'zero'/'one'/'two'/'few'/'many'/'other')
/// final category = AppPlural.category(count);
/// ```
///
/// All methods default the locale to [Intl.getCurrentLocale] so they
/// pick up `Get.updateLocale()` changes automatically.
class AppPlural {
  AppPlural._();

  /// Typed plural selection. Returns the value for the CLDR category
  /// that [count] maps to in the current (or given) locale.
  ///
  /// [other] is required — it's the CLDR fallback for any language.
  /// Omit the rest to fall through to [other]. English only ever
  /// needs `one` and `other`; Arabic can use all six.
  static T select<T>(
    num count, {
    T? zero,
    T? one,
    T? two,
    T? few,
    T? many,
    required T other,
    String? locale,
  }) {
    return Intl.pluralLogic<T>(
      count,
      locale: locale ?? Intl.getCurrentLocale(),
      zero: zero,
      one: one,
      two: two,
      few: few,
      many: many,
      other: other,
    );
  }

  /// String specialization of [select] — the common case. Interpolate
  /// [count] yourself into the form strings (see example above).
  static String string(
    num count, {
    String? zero,
    String? one,
    String? two,
    String? few,
    String? many,
    required String other,
    String? locale,
  }) {
    return select<String>(
      count,
      zero: zero,
      one: one,
      two: two,
      few: few,
      many: many,
      other: other,
      locale: locale,
    );
  }

  /// Resolve [count] to a CLDR plural category string — one of
  /// `'zero'`, `'one'`, `'two'`, `'few'`, `'many'`, `'other'`.
  ///
  /// Used internally by [Tr.plural] for per-category remote lookups;
  /// exposed here in case feature code needs to drive its own
  /// category-keyed resource map.
  static String category(num count, {String? locale}) {
    return select<String>(
      count,
      locale: locale,
      zero: 'zero',
      one: 'one',
      two: 'two',
      few: 'few',
      many: 'many',
      other: 'other',
    );
  }
}
