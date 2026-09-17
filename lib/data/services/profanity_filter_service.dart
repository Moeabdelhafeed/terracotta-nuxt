import 'package:flutter/foundation.dart';
import 'package:safe_text/safe_text.dart';

import '../../core/localization/strings/validator_strings.dart';

/// How a field reacts to profanity in its text.
enum ProfanityCheck {
  /// No check (default).
  off,

  /// Orange warning row — the user can proceed (right for real NAMES:
  /// word lists collide with legitimate names, so never hard-block).
  warn,

  /// Error row — validation fails (right for usernames / display names /
  /// public content).
  block,
}

/// Profanity + contact-info detection — wraps `safe_text` (local
/// Aho-Corasick word lists, word-boundary aware, no network).
///
/// Utility singleton (not in getIt — same pattern as the verifiers).
/// Initialization is lazy and happens once on first use; set [languages]
/// BEFORE the first check to change the loaded lists (default English +
/// Arabic). FAIL-OPEN: any internal error reads as "clean" — a filter
/// hiccup must never block sign-up.
class ProfanityFilterService {
  ProfanityFilterService._();

  static final ProfanityFilterService instance = ProfanityFilterService._();

  /// Word lists to load. Changing this after the first check has no
  /// effect (the trie is built once per session).
  List<Language> languages = [Language.english, Language.arabic];

  Future<void>? _init;

  /// Test/demo hook — non-null short-circuits the real filter.
  @visibleForTesting
  bool? debugOverride;

  Future<void> _ensureInit() =>
      _init ??= SafeTextFilter.init(languages: languages);

  /// True when [text] contains a flagged word (whole-word match on the
  /// normalized text).
  Future<bool> containsProfanity(String text) async {
    final override = debugOverride;
    if (override != null) return override;
    if (text.trim().isEmpty) return false;
    try {
      await _ensureInit();
      return await SafeTextFilter.containsBadWord(text: text);
    } catch (_) {
      return false; // fail-open
    }
  }

  /// Validator-shaped check — localized error when flagged, null when
  /// clean. Chain it into any field's `asyncValidator`.
  Future<String?> validateClean(String? text) async {
    if (text == null || text.isEmpty) return null;
    return await containsProfanity(text)
        ? ValidatorStrings.containsInappropriateLanguage
        : null;
  }

  /// Flagged words replaced with `****`.
  Future<String> mask(String text) async {
    if (text.trim().isEmpty) return text;
    try {
      await _ensureInit();
      return SafeTextFilter.filterText(text: text);
    } catch (_) {
      return text; // fail-open
    }
  }

  /// True when [text] hides a phone number (digits, number-words or a
  /// mix — "zero seven nine…"). For marketplace bios / chat where
  /// contact exchange is banned. Number-words are English-only; plain
  /// digits detect in any language.
  Future<bool> containsPhoneNumber(
    String text, {
    int minLength = 7,
    int maxLength = 15,
  }) async {
    if (text.trim().isEmpty) return false;
    try {
      return await PhoneNumberChecker.containsPhoneNumber(
        text: text,
        minLength: minLength,
        maxLength: maxLength,
      );
    } catch (_) {
      return false; // fail-open
    }
  }

  @visibleForTesting
  void resetForTest() {
    _init = null;
    debugOverride = null;
  }
}
