import 'package:flutter/material.dart';

import '../constants/fonts.dart';

/// One line box for every language.
///
/// ## The problem this exists for
///
/// Flutter positions text from the font's OWN declared ascent/descent.
/// Measured in this app at `fontSize: 14`:
///
/// ```
/// Inter    height 17.00   baseline 13.56   ratio 0.7978
/// Tajawal  height 17.00   baseline 10.40   ratio 0.6119
/// ```
///
/// Identical boxes, baselines **3.16px apart**. Centre the box and the
/// ink lands high in one font and low in the other — which is why the
/// same button looks correct in English and wrong in Arabic, and why the
/// symptom follows text everywhere: labels, fields, list rows.
///
/// `TextStyle.height` sizes the BOX and `leadingDistribution` splits the
/// LEADING. Neither moves the baseline inside ascent+descent, so neither
/// can fix this. `StrutStyle(forceStrutHeight: true)` takes the box AND
/// the baseline from the strut and ignores the font's metrics, which
/// makes it the only declarative lever that targets the right quantity.
/// With it applied, both fonts above report height 20.00 / baseline
/// 15.64 — identical.
///
/// ## What it does and does not give you
///
/// It guarantees CONSISTENCY: a `bodyLarge` occupies the same line box
/// and sits on the same baseline in every language, so layouts stop
/// shifting when the locale changes. It does NOT optically centre each
/// script — Latin and Arabic have genuinely different ink distributions
/// around the baseline, and no single box can centre both. Tune
/// [referenceFamily] to decide which script the shared metrics favour.
class AppTextStrut {
  const AppTextStrut._();

  /// Family whose metrics define the shared line box.
  ///
  /// English by default: its descent is shallow, so the resulting box is
  /// compact. The trade-off is that a deeper script (Arabic) paints its
  /// descenders slightly BELOW the box — fine on a single line, but it
  /// can overlap in tight multi-line text. Point this at the Arabic
  /// family instead to buy descender room at the cost of a taller box.
  ///
  /// Resolved ONCE and cached: `AppFonts.familyFor` goes through
  /// google_fonts, which builds a TextStyle (and can kick off a font
  /// load) on every call — and this is now consulted on every text
  /// build, so an uncached lookup would be per-frame work.
  static String? _referenceFamily;
  static String get referenceFamily =>
      _referenceFamily ??= AppFonts.familyFor('en');

  /// Overrides or clears the cached reference family.
  ///
  /// Pass a value in tests to avoid resolving through google_fonts,
  /// which needs the font asset or the network; pass null after a
  /// locale/font change that swaps the English set.
  static void debugSetReference(String? family) => _referenceFamily = family;

  /// Per-family optical nudge, as a FRACTION OF FONT SIZE so it scales.
  ///
  /// The strut standardizes the baseline, which is a metric fact. What
  /// it cannot do is centre the INK: Latin and Arabic distribute their
  /// glyph mass differently around a shared baseline, so a box centred
  /// on that baseline still looks slightly off for one of them. Flutter
  /// exposes no ink bounds, so this cannot be computed — it is dialled
  /// in by eye, once per family, and applied at the choke points.
  ///
  /// Negative moves text UP. Keep these small: a value large enough to
  /// be obviously wrong will also clip against tight parents.
  static const Map<String, double> _opticalOffsetEm = {
    // Tajawal sits LOW once its baseline is forced to the Latin ratio
    // (its natural baseline is 0.6119 of the box against Inter's
    // 0.7978), so it is lifted back. Dialled by eye on
    // /playground → "Optical nudge" against a correct English button;
    // -0.10em is 1.6px at the 16pt body size.
    'Tajawal_regular': -0.10,
    'Tajawal': -0.10,
  };

  /// Live overrides, keyed by family — used by the playground tuner to
  /// drive the REAL code path while a value is being dialled in, so the
  /// number is chosen against the same rendering production uses.
  ///
  /// Dev-only by convention: nothing in the app writes to it, and the
  /// playground is stripped when the template is forked.
  static final Map<String, double> debugOverrideEm = {};

  /// The baked offset for [family], ignoring any live override — so a
  /// tuner can start from the value actually in effect instead of
  /// duplicating the constant.
  static double bakedOffsetEm(String family) => _opticalOffsetEm[family] ?? 0;

  /// Vertical correction in logical pixels for [family] at [fontSize].
  static double opticalOffset(String? family, double? fontSize) {
    if (family == null || fontSize == null) return 0;
    final em = debugOverrideEm[family] ?? _opticalOffsetEm[family] ?? 0;
    return em * fontSize;
  }

  /// Wraps [child] in the family's optical nudge.
  ///
  /// `Transform.translate` paints the shift without touching layout, so
  /// nothing reflows — the box stays exactly where the strut put it and
  /// only the ink moves.
  static Widget nudge({required Widget child, required TextStyle? style}) {
    final dy = opticalOffset(style?.fontFamily, style?.fontSize);
    if (dy == 0) return child;
    return Transform.translate(offset: Offset(0, dy), child: child);
  }

  /// Strut matching [style], so the caller's size and line height are
  /// preserved and only the METRICS are standardized.
  ///
  /// Returns null when the style carries no font size — there is nothing
  /// to anchor a strut to, and a strut with a guessed size would be
  /// worse than none.
  static StrutStyle? forStyle(TextStyle? style) {
    final size = style?.fontSize;
    if (size == null) return null;
    return StrutStyle(
      fontFamily: referenceFamily,
      fontSize: size,
      height: style?.height,
      // The whole point: ignore the rendered font's ascent/descent.
      forceStrutHeight: true,
    );
  }
}
