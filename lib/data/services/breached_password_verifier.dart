import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../core/localization/strings/text_field_strings.dart';

/// Checks a password against the Have-I-Been-Pwned corpus using the
/// **k-anonymity range API** — the password NEVER leaves the device: only
/// the first 5 characters of its SHA-1 are sent, and the API returns all
/// matching hash suffixes to compare locally.
///
/// Free, no API key. **Fail-open**: network errors / timeouts count as
/// not-breached — an offline user must never be blocked from setting a
/// password. Results are cached per password hash for the app session.
///
/// Plugs into the text-field async pipeline:
/// `PasswordField(checkBreached: true)` or
/// `asyncValidator: BreachedPasswordVerifier.instance.validateNotBreached`.
class BreachedPasswordVerifier {
  BreachedPasswordVerifier({http.Client? client})
    : _client = client ?? http.Client();

  /// Utility singleton (kept out of `getIt` on purpose — no config; tests
  /// inject an [http.Client]).
  static final BreachedPasswordVerifier instance = BreachedPasswordVerifier();

  final http.Client _client;
  final Map<String, int> _cache = {};

  static const _timeout = Duration(seconds: 4);

  /// How many breaches the password appears in (0 = none known).
  Future<int> breachCount(String password) async {
    if (password.isEmpty) return 0;
    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final cached = _cache[hash];
    if (cached != null) return cached;

    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5);
    try {
      final res = await _client
          .get(
            Uri.https('api.pwnedpasswords.com', '/range/$prefix'),
            // Pads responses so even the range size leaks nothing.
            headers: const {'Add-Padding': 'true'},
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return 0; // fail-open, don't cache
      var count = 0;
      for (final line in const LineSplitter().convert(res.body)) {
        final sep = line.indexOf(':');
        if (sep <= 0) continue;
        if (line.substring(0, sep).toUpperCase() == suffix) {
          count = int.tryParse(line.substring(sep + 1).trim()) ?? 0;
          break;
        }
      }
      _cache[hash] = count;
      return count;
    } catch (_) {
      return 0; // fail-open — offline must not block
    }
  }

  /// `asyncValidator`-shaped adapter: null when the password isn't in any
  /// known breach.
  Future<String?> validateNotBreached(String password) async {
    final count = await breachCount(password);
    if (count <= 0) return null;
    return TextFieldStrings.passwordBreached(count);
  }
}
