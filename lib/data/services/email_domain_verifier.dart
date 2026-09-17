import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/localization/strings/text_field_strings.dart';

/// Checks whether an email domain can actually receive mail — DNS-over-HTTPS
/// lookup (Google resolver) for MX records, falling back to A/AAAA (RFC 5321
/// allows address-record delivery when no MX exists).
///
/// This is deliverability of the DOMAIN, not existence of the mailbox — the
/// only real mailbox proof is a confirmation email. It catches dead domains
/// and typos (`gmali.com`) before submit, with no backend.
///
/// **Fail-open**: network errors / timeouts / non-200 responses count as
/// deliverable — an offline user must never be blocked from typing their
/// email. Results are cached per domain for the app session.
///
/// Plugs into the text-field async pipeline:
/// `EmailField(verifyDomain: true)` or
/// `asyncValidator: EmailDomainVerifier.instance.validateEmailDomain`.
class EmailDomainVerifier {
  EmailDomainVerifier({http.Client? client})
    : _client = client ?? http.Client();

  /// Shared default instance (utility singleton — kept out of `getIt` on
  /// purpose: no config, no state worth faking except [_client], which tests
  /// inject via the constructor).
  static final EmailDomainVerifier instance = EmailDomainVerifier();

  final http.Client _client;
  final Map<String, bool> _cache = {};

  static const _timeout = Duration(seconds: 4);

  /// True when [domain] has MX records, or (lacking MX) an A/AAAA record.
  Future<bool> isDeliverableDomain(String domain) async {
    final d = domain.trim().toLowerCase();
    if (d.isEmpty || !d.contains('.')) return false;
    final cached = _cache[d];
    if (cached != null) return cached;

    try {
      final hasMx = await _hasRecord(d, 'MX');
      final ok = hasMx || await _hasRecord(d, 'A');
      _cache[d] = ok;
      return ok;
    } catch (_) {
      return true; // fail-open — do not cache
    }
  }

  Future<bool> _hasRecord(String domain, String type) async {
    final res = await _client
        .get(
          Uri.https('dns.google', '/resolve', {'name': domain, 'type': type}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw http.ClientException('DoH ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['Status'] != 0) return false; // NXDOMAIN etc.
    final answers = body['Answer'];
    return answers is List && answers.isNotEmpty;
  }

  /// `asyncValidator`-shaped adapter: null when the domain is deliverable
  /// (or the email has no `@` — that's the sync format validator's job).
  Future<String?> validateEmailDomain(String email) async {
    final at = email.trim().lastIndexOf('@');
    if (at < 0 || at == email.trim().length - 1) return null;
    final domain = email.trim().substring(at + 1);
    if (await isDeliverableDomain(domain)) return null;
    return TextFieldStrings.emailDomainUnreachable;
  }
}
