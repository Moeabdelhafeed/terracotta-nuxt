import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/preferences/locale_service.dart';
import '../di/service_locator.dart';

// ---------------------------------------------------------------------------
// FontSource — wraps either a Google Font or a local asset font
// ---------------------------------------------------------------------------

/// Represents a font family from any source.
@immutable
class FontSource {
  /// Google Font — downloaded on demand.
  const FontSource.google(
    this.family,
    this.googleFont, {
    this.fallback = 'Roboto',
  });

  /// Asset font — bundled in assets/fonts/ and registered in pubspec.yaml.
  const FontSource.asset(
    this.family, {
    this.fallback = 'Roboto',
  }) : googleFont = null;

  /// The font family name (e.g. 'Inter', 'Cairo', 'MyCustomFont').
  final String family;

  /// Google Fonts factory. Null for asset fonts.
  final TextStyle Function()? googleFont;

  /// System font fallback if the primary fails to load.
  final String fallback;

  /// Skips the Google Fonts loader and answers from [family] alone.
  ///
  /// Resolving normally KICKS OFF A DOWNLOAD as a side effect, which in a
  /// test is an HTTP call that fails asynchronously and takes the test
  /// with it — even when the test only ever wanted the NAME. Set this in
  /// a test that inspects families rather than rendering them.
  @visibleForTesting
  static bool debugNamesOnly = false;

  /// Resolves the effective font family name.
  /// For Google Fonts, this triggers the download if not cached.
  String resolve() {
    if (debugNamesOnly) return family;
    if (googleFont != null) {
      try {
        return googleFont!().fontFamily ?? fallback;
      } catch (_) {
        return fallback;
      }
    }
    return family;
  }
}

// ---------------------------------------------------------------------------
// TextType — the typography categories
// ---------------------------------------------------------------------------

/// Typography categories matching Material 3.
enum TextType {
  display,
  headline,
  title,
  body,
  label,
  caption,
}

// ---------------------------------------------------------------------------
// FontSet — font mapping per text type for a language
// ---------------------------------------------------------------------------

/// Defines which font to use for each text type in a language.
///
/// Any type not explicitly set falls back to [defaultFont].
///
/// Example:
/// ```dart
/// FontSet(
///   defaultFont: FontSource.google('Inter', GoogleFonts.inter),
///   display: FontSource.google('Playfair Display', GoogleFonts.playfairDisplay),
/// )
/// ```
@immutable
class FontSet {
  const FontSet({
    required this.defaultFont,
    this.display,
    this.headline,
    this.title,
    this.body,
    this.label,
    this.caption,
  });

  /// Fallback font for any type not explicitly set.
  final FontSource defaultFont;

  /// Font for display text (largest, most decorative).
  final FontSource? display;

  /// Font for headlines.
  final FontSource? headline;

  /// Font for titles.
  final FontSource? title;

  /// Font for body text.
  final FontSource? body;

  /// Font for labels (buttons, chips, tabs).
  final FontSource? label;

  /// Font for captions (smallest text).
  final FontSource? caption;

  /// Get the font for a specific text type.
  FontSource forType(TextType type) => switch (type) {
    TextType.display => display ?? defaultFont,
    TextType.headline => headline ?? defaultFont,
    TextType.title => title ?? defaultFont,
    TextType.body => body ?? defaultFont,
    TextType.label => label ?? defaultFont,
    TextType.caption => caption ?? defaultFont,
  };

  /// Resolve the font family name for a specific text type.
  String resolveFamily(TextType type) => forType(type).resolve();

  /// Families consulted, in order, for glyphs the primary lacks.
  ///
  /// Flutter resolves fonts PER GLYPH, so this is what makes a single
  /// string containing both scripts render each run in its own face —
  /// no detection, and it works mid-sentence.
  ///
  /// The list is every OTHER language's font, so whichever set is
  /// active can still draw scripts it has no glyphs for.
  List<String> resolveFallbacks(TextType type, {String? exceptLanguage}) {
    final seen = <String>{resolveFamily(type)};
    final out = <String>[];
    for (final entry in AppFonts.all.entries) {
      if (entry.key == exceptLanguage) continue;
      final family = entry.value.resolveFamily(type);
      if (seen.add(family)) out.add(family);
    }
    return out;
  }

  /// Preload all fonts used in this set (sync — only resolves family names).
  void preload() {
    final sources = {
      defaultFont,
      display,
      headline,
      title,
      body,
      label,
      caption,
    };
    for (final source in sources) {
      source?.resolve();
    }
  }

  /// Collect all [TextStyle]s from Google Fonts in this set, for use with
  /// [GoogleFonts.pendingFonts] to await network downloads.
  List<TextStyle> googleFontStyles() {
    final sources = {
      defaultFont,
      display,
      headline,
      title,
      body,
      label,
      caption,
    };
    final styles = <TextStyle>[];
    for (final source in sources) {
      final factory = source?.googleFont;
      if (factory == null) continue;
      try {
        styles.add(factory());
      } catch (_) {
        // Skip — font factory failed.
      }
    }
    return styles;
  }
}

// ---------------------------------------------------------------------------
// AppFonts — language → FontSet mapping
// ---------------------------------------------------------------------------

class AppFonts {
  const AppFonts._();

  // ─── Font sets per language ────────────────────────────────

  /// Terracotta is Kufam in BOTH languages.
  ///
  /// Kufam is an Arabic + Latin superfamily, so one family covers the
  /// whole app: no metric jump when the customer flips language
  /// mid-session, one download instead of two, and mixed-script strings
  /// ("٦٥ SAR") render in one face rather than two.
  ///
  /// Google Fonts ships it at 400/500/600/700/800/900 — the design uses
  /// w900 for every price, so the full ramp is needed.
  static const FontSet english = FontSet(
    defaultFont: FontSource.google('Kufam', GoogleFonts.kufam),
  );

  static const FontSet arabic = FontSet(
    defaultFont: FontSource.google(
      'Kufam',
      GoogleFonts.kufam,
      fallback: 'Noto Sans Arabic',
    ),
  );

  static const FontSet chinese = FontSet(
    defaultFont: FontSource.google(
      'Noto Sans SC',
      GoogleFonts.notoSansSc,
      fallback: 'sans-serif',
    ),
  );

  /// Fallback font set for unsupported languages.
  static const FontSet fallback = english;

  // ─── Language → FontSet mapping ────────────────────────────

  static const Map<String, FontSet> _fontSets = {
    'en': english,
    'ar': arabic,
    'zh': chinese,
  };

  // Mutable overlay for runtime registration
  static final Map<String, FontSet> _mutableFontSets = {};

  // ─── Public API ────────────────────────────────────────────

  /// Get the [FontSet] for the current locale. Reads from
  /// [LocaleService] when registered; falls back to `'en'` before
  /// service init.
  static FontSet get current {
    final code = getIt.isRegistered<LocaleService>()
        ? getIt<LocaleService>().languageCode
        : 'en';
    return _resolve(code);
  }

  /// There is deliberately NO `family()` returning the ACTIVE LOCALE's
  /// family.
  ///
  /// That is the API that caused the bug: every widget theme called it,
  /// so in an Arabic locale English text was drawn by the Arabic face —
  /// which has Latin glyphs, so it never fell through to Inter. Fonts
  /// are chosen by SCRIPT, per glyph, via
  /// [scriptPrimaryFamily] + [scriptFallbackFamilies]; the active locale
  /// does not enter into it. [familyFor] stays for the cases that
  /// genuinely mean one language (side-by-side comparisons, the strut
  /// reference).
  ///
  /// Get the [FontSet] for a specific language code.
  static FontSet forLanguage(String languageCode) => _resolve(languageCode);

  /// Get the resolved font family for a specific type and language.
  static String familyFor(
    String languageCode, [
    TextType type = TextType.body,
  ]) => forLanguage(languageCode).resolveFamily(type);

  /// Preload fonts for the given language codes — awaits the Google Fonts
  /// network downloads so the binaries are in cache before any text paints.
  /// Without this, the first frame after a language switch can render with
  /// the fallback font for ~1 frame.
  static Future<void> preload(List<String> languageCodes) async {
    final styles = <TextStyle>[];
    for (final code in languageCodes) {
      final fontSet = _resolve(code);
      try {
        fontSet.preload();
        styles.addAll(fontSet.googleFontStyles());
      } catch (e) {
        debugPrint('Failed to preload fonts for $code: $e');
      }
    }
    if (styles.isEmpty) return;
    try {
      await GoogleFonts.pendingFonts(styles);
    } catch (e) {
      debugPrint('Google Fonts pendingFonts failed: $e');
    }
  }

  /// Preload fonts for a single language. Useful right before a language
  /// switch — call and `await` before the locale change so the new font is
  /// already cached when the tree rebuilds.
  static Future<void> preloadLanguage(String languageCode) =>
      preload([languageCode]);

  /// Register a custom [FontSet] for a language code at runtime.
  /// Useful for dynamic language support without modifying this file.
  static void register(String languageCode, FontSet fontSet) {
    _mutableFontSets[languageCode] = fontSet;
  }

  /// Resolves the font set: checks runtime-registered first, then const, then fallback.
  /// Every known set, runtime registrations included. Used to build the
  /// per-glyph fallback chain.
  static Map<String, FontSet> get all => {..._fontSets, ..._mutableFontSets};

  /// Family that should OWN the primary slot for [type].
  ///
  /// Deliberately the LATIN set rather than the active locale's. Font
  /// fallback only engages for glyphs the primary lacks — and the Arabic
  /// faces ship Latin glyphs, so making one primary means English text
  /// renders in it and never falls back. Latin-first inverts that: Latin
  /// runs stay in the Latin face and Arabic runs, which Inter cannot
  /// draw, fall through to the Arabic face.
  static String scriptPrimaryFamily([TextType type = TextType.body]) =>
      forLanguage('en').resolveFamily(type);

  /// Families for every other script, in registry order.
  static List<String> scriptFallbackFamilies([
    TextType type = TextType.body,
  ]) => forLanguage('en').resolveFallbacks(type, exceptLanguage: 'en');

  static FontSet _resolve(String languageCode) =>
      _mutableFontSets[languageCode] ?? _fontSets[languageCode] ?? fallback;
}
