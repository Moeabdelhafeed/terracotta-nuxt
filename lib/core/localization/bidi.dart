import 'package:flutter/widgets.dart';
// `intl` ships its own `TextDirection` type that collides with the one
// from `dart:ui` / `flutter/widgets.dart`; hide it so `TextDirection`
// resolves to the Flutter enum with `.ltr` / `.rtl`.
import 'package:intl/intl.dart' hide TextDirection;

/// Unicode bidirectional text helpers — for embedding LTR fragments
/// (numbers, dates, phone numbers, URLs, email addresses) inside RTL
/// text without visual re-ordering.
///
/// ## The problem
/// When you stitch together `'${count} items'` where the surrounding
/// paragraph is Arabic, the Unicode Bidi Algorithm can visually flip
/// multi-part fragments. Dates (`2026-04-20`) flip to `20-04-2026`,
/// phone numbers get mangled, URLs shuffle.
///
/// ## The fix
/// Wrap the LTR fragment in **isolate** or **embedding** control
/// characters so the renderer treats it as a single unit. Modern
/// Flutter / ICU prefer isolates (`FSI … PDI`).
///
/// ```dart
/// // Simple wrap — safe in any paragraph direction.
/// Text('${AppBidi.isolate(phone)} — $AppBidi.isolate(email)')
///
/// // Context-aware (detects current Directionality):
/// Text(AppBidi.embed(context, '2026-04-20'))
///
/// // Format a number + unit for mixed paragraphs:
/// Text(AppBidi.wrapLtr('$weight kg'))
/// ```
///
/// For body text where you don't control the pieces (user-generated
/// content, backend strings), just set the widget's
/// [TextDirection] from [Directionality.of] and let Flutter's bidi
/// algorithm resolve — these helpers are for fragments you build
/// yourself.
class AppBidi {
  AppBidi._();

  /// Unicode first-strong isolate — start. The renderer picks the
  /// isolate's direction from the first strong character inside.
  static const String fsi = '\u2068';

  /// Left-to-right isolate — forces the enclosed text to render LTR
  /// regardless of surrounding direction.
  static const String lri = '\u2066';

  /// Right-to-left isolate — forces RTL.
  static const String rli = '\u2067';

  /// Pop directional isolate — closes an FSI/LRI/RLI.
  static const String pdi = '\u2069';

  /// Left-to-right mark — zero-width hint that nudges neutral
  /// characters (digits, punctuation) to resolve LTR. Cheaper than a
  /// full isolate when you just need to prevent a flip at a boundary.
  static const String lrm = '\u200E';

  /// Right-to-left mark — dual of [lrm].
  static const String rlm = '\u200F';

  /// Wrap [text] in a first-strong isolate (`FSI … PDI`). Safe default
  /// — the fragment picks its own direction. Use for arbitrary
  /// embedded content when you're not sure which way it should go.
  static String isolate(String text) => '$fsi$text$pdi';

  /// Force [text] to render LTR regardless of surrounding direction.
  /// Use for dates, phone numbers, URLs, email addresses — anything
  /// that's canonically written left-to-right.
  static String wrapLtr(String text) => '$lri$text$pdi';

  /// Force [text] to render RTL.
  static String wrapRtl(String text) => '$rli$text$pdi';

  /// Embed [text] with direction inferred from the current
  /// [Directionality] — wraps in LTR when the ambient is RTL (to
  /// prevent fragment re-ordering), passes through when ambient is
  /// already LTR.
  ///
  /// Useful shortcut for "show this LTR-native fragment in a widget
  /// that may be in either direction."
  static String embed(BuildContext context, String text) {
    return Directionality.of(context) == TextDirection.rtl
        ? wrapLtr(text)
        : text;
  }

  /// Best-effort direction inference for arbitrary text using
  /// `intl`'s bidi utilities. Returns [TextDirection.rtl] when the
  /// first strong character is RTL, otherwise [TextDirection.ltr].
  ///
  /// ```dart
  /// Text(userInput, textDirection: AppBidi.detect(userInput))
  /// ```
  static TextDirection detect(String text) {
    return Bidi.detectRtlDirectionality(text)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  /// Strip all Unicode bidi control characters from [text]. Useful
  /// before logging, persisting to storage, or comparing strings —
  /// control chars are invisible but affect equality.
  static String strip(String text) {
    return text.replaceAll(
      RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069]'),
      '',
    );
  }
}
