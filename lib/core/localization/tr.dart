import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_format.dart';

/// App-wide translation facade. Sits between feature code and the two
/// translation sources (ARB-generated `S` class + optional remote map).
///
/// Design in one sentence: **ARB is the source of truth; remote is an
/// optional overlay that, when present, wins on a per-key basis.**
///
/// ```dart
/// // Flat string
/// Tr.t('auth_sign_in', S.current.authSignIn)
///
/// // Pluralized string (auto-detect)
/// Tr.plural('cart_items', count, S.current.cartItems(count))
/// ```
///
/// Typical call-site usage goes through a per-feature namespace
/// (`AuthStrings.signIn`, `CartStrings.items(count)`) rather than
/// touching [Tr] directly — but [Tr.t] and [Tr.plural] are the primitives.
///
/// ## Remote override auto-detection
///
/// [Tr.plural] inspects the value that the remote map returns for the
/// given key and picks the right resolution strategy automatically.
/// Three shapes are supported:
///
/// 1. **ICU plural template** — e.g.
///    `"{count, plural, one{{count} item} other{{count} items}}"`.
///    Delegated to [MessageFormat] so the current locale's CLDR plural
///    category is honored. This is the format most translation
///    platforms (Crowdin, Lokalise, POEditor) serve once ICU support
///    is enabled.
/// 2. **Per-category entries** — `foo__one`, `foo__other`,
///    `foo__zero`, etc. Useful for simpler backends that can't store
///    ICU templates but do know per-category strings per locale.
///    [Tr] resolves the active category via [Intl.pluralLogic] and
///    looks up the matching `__<category>` key.
/// 3. **Plain string** — the remote returned the key as a flat string.
///    Treated as if every plural form collapses to that single string
///    (useful for languages with no plural distinction or as a stopgap
///    while translators fill in the forms).
///
/// If no shape matches, [Tr] falls back to the `local` argument (the
/// ARB-resolved value for the current locale).
class Tr {
  Tr._();

  static Map<String, String> _remote = const {};

  /// Pseudo-localization (debug QA): every string routed through [t] /
  /// [plural] comes back accented + ~30% longer + bracket-wrapped
  /// (`⟦Àççôûñţ ~~⟧`). Two bug classes pop instantly: layouts that
  /// clip under longer languages, and hardcoded strings that DON'T
  /// wobble (they bypassed Tr/ARB). Toggle via [setPseudo] (the L10n
  /// dev tool exposes a switch); no-op in release builds.
  static bool get pseudoEnabled => pseudoNotifier.value;

  /// Reactive form — the debug overlay's active-override badge and the
  /// app root's rebuild listener hang off this.
  static final ValueNotifier<bool> pseudoNotifier = ValueNotifier<bool>(false);

  static void setPseudo(bool value) {
    if (!kDebugMode) return;
    pseudoNotifier.value = value;
  }

  static const _pseudoMap = {
    'a': 'à',
    'e': 'é',
    'i': 'î',
    'o': 'ô',
    'u': 'û',
    'c': 'ç',
    'n': 'ñ',
    'y': 'ý',
    's': 'š',
    'z': 'ž',
    'g': 'ğ', //
    'A': 'À',
    'E': 'É',
    'I': 'Î',
    'O': 'Ô',
    'U': 'Û',
    'C': 'Ç',
    'N': 'Ñ',
    'Y': 'Ý',
    'S': 'Š',
    'Z': 'Ž',
    'G': 'Ğ',
  };

  static String _pseudo(String s) {
    if (s.isEmpty) return s;
    final b = StringBuffer('⟦');
    for (final ch in s.split('')) {
      b.write(_pseudoMap[ch] ?? ch);
    }
    // ~30% expansion approximates German/Finnish growth over English.
    b.write('~' * (s.length * 0.3).ceil().clamp(1, 12));
    b.write('⟧');
    return b.toString();
  }

  /// Session-scoped set of keys we've already reported as missing to
  /// [_onMissing], so a rebuilding widget that hits the same key 60×/s
  /// only enqueues it once.
  static final Set<String> _seenMissing = {};

  /// Debug-only callback fired when [t] falls back to the ARB default.
  /// Installed by [RemoteTranslations] to auto-populate the backend
  /// dictionary. Never set in release builds.
  static void Function(String key, String defaultValue)? _onMissing;

  /// Install a new remote override map. Pass an empty map (or call
  /// [clearRemote]) to disable remote overrides and fall back to ARB
  /// for every key.
  ///
  /// Call this on app startup once translations are fetched, and again
  /// whenever the locale changes if your backend returns per-locale
  /// maps.
  static void setRemote(Map<String, String> map) =>
      _remote = Map.unmodifiable(map);

  static void clearRemote() => _remote = const {};

  /// Whether a remote override currently exists for [key]. Rarely
  /// needed at call sites — feature code should just call [t] / [plural]
  /// and trust the fallback chain.
  static bool hasRemote(String key) => _remote.containsKey(key);

  /// Register (or clear) the missing-key callback. Pass `null` to
  /// disable. Pure hook — [Tr] has no opinion on what the handler does
  /// (batch, log, POST to backend, whatever).
  ///
  /// The callback only fires for flat [t] calls, and only once per key
  /// per session. [plural] keys are intentionally excluded — see
  /// [plural] dartdoc.
  static void onMissingKey(
    void Function(String key, String defaultValue)? cb,
  ) => _onMissing = cb;

  /// Clear the dedupe set — the next missing-key hit will re-report
  /// even if we've seen it before. Useful for tests.
  static void resetSeenMissing() => _seenMissing.clear();

  /// Resolve a **flat** (non-pluralized) key. Returns the remote value
  /// if present, otherwise [local] (the ARB-resolved value for the
  /// current locale).
  ///
  /// Use [plural] instead when the key depends on a number.
  static String t(String key, String local) {
    final v = _remote[key];
    if (v != null) return pseudoEnabled ? _pseudo(v) : v;
    // Report missing key exactly once per session. The callback
    // decides whether release builds participate — [RemoteTranslations]
    // only installs it behind `kDebugMode`.
    if (_onMissing != null && _seenMissing.add(key)) {
      _onMissing!(key, local);
    }
    return pseudoEnabled ? _pseudo(local) : local;
  }

  /// Resolve a **pluralized** key with auto-detect across the three
  /// supported remote shapes.
  ///
  /// - [key]: the base ARB key (e.g. `'cart_items'`).
  /// - [count]: the count driving plural category selection.
  /// - [local]: the ARB-resolved value for the current locale *already
  ///   evaluated with [count]* — e.g. `S.current.cartItems(count)`.
  ///   Used as the ultimate fallback.
  /// - [args]: optional additional named placeholders consumed by ICU
  ///   templates. `{count}` is always injected automatically.
  /// - [locale]: override the locale used for category resolution. Rare
  ///   — defaults to [Intl.getCurrentLocale].
  ///
  /// ## Why plurals skip the missing-key reporter
  /// [t]'s reporter enqueues `(key, defaultValue)` for later POSTing.
  /// For plurals, `local` is already evaluated for a specific [count]
  /// (e.g. `"5 items"`) — POSTing that as the canonical default throws
  /// away every other plural form. Add plural keys manually, or extend
  /// the backend to accept ICU templates and push the raw template.
  static String plural(
    String key,
    int count,
    String local, {
    Map<String, Object> args = const {},
    String? locale,
  }) {
    final resolved = _pluralResolved(
      key,
      count,
      local,
      args: args,
      locale: locale,
    );
    return pseudoEnabled ? _pseudo(resolved) : resolved;
  }

  static String _pluralResolved(
    String key,
    int count,
    String local, {
    required Map<String, Object> args,
    String? locale,
  }) {
    final effectiveLocale = locale ?? Intl.getCurrentLocale();

    // Shape 1: ICU template under the base key.
    final template = _remote[key];
    if (template != null && _looksLikeIcuPlural(template)) {
      try {
        return MessageFormat(template, locale: effectiveLocale).format({
          'count': count,
          ...args,
        });
      } catch (_) {
        // Malformed template — fall through to per-category / local.
      }
    }

    // Shape 2: per-category entries (foo__one, foo__other, …).
    final category = Intl.pluralLogic<String>(
      count,
      locale: effectiveLocale,
      zero: 'zero',
      one: 'one',
      two: 'two',
      few: 'few',
      many: 'many',
      other: 'other',
    );
    final categoryValue =
        _remote['${key}__$category'] ?? _remote['${key}__other'];
    if (categoryValue != null) {
      return _interpolate(categoryValue, {'count': count, ...args});
    }

    // Shape 3: plain flat string under the base key — use as-is.
    if (template != null) {
      return _interpolate(template, {'count': count, ...args});
    }

    // Fallback: ARB value already resolved for this locale + count.
    return local;
  }

  /// Heuristic for "is this string an ICU plural template?". Tight
  /// enough that flat strings starting with `{` won't mis-route, loose
  /// enough that hand-written templates with whitespace variance still
  /// match.
  static bool _looksLikeIcuPlural(String s) {
    final trimmed = s.trimLeft();
    if (!trimmed.startsWith('{')) return false;
    // `{ name , plural , ... }` or `{name,plural,...}` — look for the
    // plural keyword within the first ~40 chars to avoid scanning long
    // strings.
    final head = trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
    return RegExp(r'\{\s*\w+\s*,\s*plural\s*,').hasMatch(head);
  }

  /// Lightweight `{name}` placeholder interpolation for shape 2/3 —
  /// not a full ICU parser (that's what [MessageFormat] is for).
  /// Missing keys are left as-is so template bugs are visible.
  static String _interpolate(String template, Map<String, Object> args) {
    if (args.isEmpty || !template.contains('{')) return template;
    return template.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (m) => args[m.group(1)]?.toString() ?? m.group(0)!,
    );
  }
}
