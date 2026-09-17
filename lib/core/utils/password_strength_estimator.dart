import 'dart:math';

/// Lightweight, self-contained password-strength estimator inspired by
/// zxcvbn — entropy from the character pool, penalized for the patterns
/// real crackers try first (common passwords, repeats, sequences, keyboard
/// walks, years), with leet-speak normalization (`P@ssw0rd` ≈ `password`).
///
/// Returns 0.0–1.0, mapped from estimated entropy bits using zxcvbn-like
/// bands (≤25 bits → 0, ≥65 bits → 1). Plug into the text field:
///
/// ```dart
/// PasswordField(showStrengthBar: true) // used automatically when no
///                                      // requirements checklist is set
/// // or explicitly:
/// strengthEstimator: PasswordStrengthEstimator.estimate,
/// ```
///
/// **Limits (deliberate):** the real zxcvbn ships ~30k ranked dictionary
/// words + name/surname corpora; this embeds only the top common passwords
/// and structural patterns, trading recall for zero dependencies. Swap in a
/// full zxcvbn port via `strengthEstimator:` if your product needs it.
class PasswordStrengthEstimator {
  PasswordStrengthEstimator._();

  /// Top common passwords (case/leet-insensitive prefix matches also
  /// penalize `password123!`-style decorations).
  static const List<String> _common = [
    'password',
    'qwerty',
    'letmein',
    'welcome',
    'monkey',
    'dragon',
    'master',
    'shadow',
    'superman',
    'batman',
    'trustno1',
    'iloveyou',
    'sunshine',
    'princess',
    'football',
    'baseball',
    'soccer',
    'charlie',
    'jordan',
    'freedom',
    'whatever',
    'secret',
    'ninja',
    'mustang',
    'access',
    'flower',
    'passw0rd',
    'starwars',
    'login',
    'admin',
    'abc123',
    'hello',
    'zaq1zaq1',
    'password1',
    '123456',
    '12345678',
    '123456789',
    '1234567890',
    '111111',
    '000000',
    '696969',
    '121212',
  ];

  static const List<String> _keyboardRows = [
    'qwertyuiop',
    'asdfghjkl',
    'zxcvbnm',
    '1234567890',
    'qazwsxedc',
    'plokmijn',
  ];

  static const Map<String, String> _leet = {
    '@': 'a',
    '4': 'a',
    '8': 'b',
    '3': 'e',
    '1': 'l',
    '!': 'i',
    '0': 'o',
    '5': 's',
    r'$': 's',
    '7': 't',
    '+': 't',
    '9': 'g',
  };

  /// 0.0 (trivially guessable) → 1.0 (strong). Suitable for
  /// `TextFieldValidation.strengthEstimator`.
  static double estimate(String password) {
    if (password.isEmpty) return 0;
    final bits = entropyBits(password);
    // zxcvbn-ish bands: ≤25 bits ~instant crack, ≥65 bits ~offline-safe.
    return ((bits - 25) / 40).clamp(0.0, 1.0);
  }

  /// Estimated entropy in bits after pattern penalties (exposed for tests).
  static double entropyBits(String password) {
    final normalized = _normalize(password);

    // Common-password hit (exact or decorated prefix): the base word is
    // ~free for a cracker — only the decoration length counts.
    for (final c in _common) {
      if (normalized == c) return 4;
      if (normalized.startsWith(c)) {
        return 4 + (password.length - c.length) * 2.0;
      }
    }

    // Base: brute-force entropy over the used character pool.
    var pool = 0;
    if (password.contains(RegExp('[a-z]'))) pool += 26;
    if (password.contains(RegExp('[A-Z]'))) pool += 26;
    if (password.contains(RegExp('[0-9]'))) pool += 10;
    if (password.contains(RegExp(r'[^a-zA-Z0-9]'))) pool += 33;
    var bits = password.length * (log(pool) / ln2);

    // Repetition: entropy scales with distinct material, not raw length.
    final uniqueRatio = password.split('').toSet().length / password.length;
    bits *= (0.4 + 0.6 * uniqueRatio);

    // Sequential runs (abc / 321) and keyboard walks (qwer / asdf): each
    // matched run is ~one "move" for a cracker, not N free characters.
    bits -= _sequencePenalty(normalized);
    bits -= _keyboardPenalty(normalized);

    // Years (1900–2099) are ~7 bits, not 10^4.
    if (RegExp('(19|20)[0-9]{2}').hasMatch(password)) bits -= 6;

    return max(bits, 1);
  }

  static String _normalize(String password) {
    final buffer = StringBuffer();
    for (final ch in password.toLowerCase().split('')) {
      buffer.write(_leet[ch] ?? ch);
    }
    return buffer.toString();
  }

  static double _sequencePenalty(String s) {
    var penalty = 0.0;
    var run = 1;
    for (var i = 1; i < s.length; i++) {
      final delta = s.codeUnitAt(i) - s.codeUnitAt(i - 1);
      if (delta == 1 || delta == -1) {
        run++;
      } else {
        if (run >= 3) penalty += (run - 1) * 3.5;
        run = 1;
      }
    }
    if (run >= 3) penalty += (run - 1) * 3.5;
    return penalty;
  }

  static double _keyboardPenalty(String s) {
    var penalty = 0.0;
    for (final row in _keyboardRows) {
      for (var len = 4; len <= row.length; len++) {
        for (var start = 0; start + len <= row.length; start++) {
          final walk = row.substring(start, start + len);
          if (s.contains(walk) || s.contains(walk.split('').reversed.join())) {
            penalty = max(penalty, (len - 1) * 3.5);
          }
        }
      }
    }
    return penalty;
  }
}
