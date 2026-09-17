import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/localization/tr.dart';
import '../../core/utils/web_link.dart';

/// Checks whether a URL's HOST actually resolves — DNS-over-HTTPS lookup
/// (Google resolver) for A/AAAA records. Catches dead domains and typos
/// (`exampl.com`) before submit, with no backend and no CORS issues (unlike a
/// HEAD request to the site itself, which the browser would block on web).
///
/// This proves the DOMAIN exists, not that the exact page does — the only
/// real page proof is fetching it.
///
/// **Fail-open**: network errors / timeouts / non-200 responses count as
/// reachable — an offline user must never be blocked from typing a link.
/// Results are cached per host for the app session.
///
/// Plugs into the text-field async pipeline:
/// `UrlField(verifyHost: true)` or
/// `asyncValidator: UrlHostVerifier.instance.validateUrlHost`.
class UrlHostVerifier {
  UrlHostVerifier({http.Client? client}) : _client = client ?? http.Client();

  /// Shared default instance (utility singleton — kept out of `getIt` on
  /// purpose: no config, no state worth faking except [_client], which tests
  /// inject via the constructor).
  static final UrlHostVerifier instance = UrlHostVerifier();

  final http.Client _client;
  final Map<String, bool> _cache = {};

  static const _timeout = Duration(seconds: 4);

  /// True when [host] has an A or AAAA record.
  Future<bool> isResolvableHost(String host) async {
    final h = host.trim().toLowerCase();
    if (h.isEmpty || !h.contains('.')) return false;
    final cached = _cache[h];
    if (cached != null) return cached;

    try {
      final ok = await _hasRecord(h, 'A') || await _hasRecord(h, 'AAAA');
      _cache[h] = ok;
      return ok;
    } catch (_) {
      return true; // fail-open — do not cache
    }
  }

  Future<bool> _hasRecord(String host, String type) async {
    final res = await _client
        .get(Uri.https('dns.google', '/resolve', {'name': host, 'type': type}))
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw http.ClientException('DoH ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['Status'] != 0) return false; // NXDOMAIN etc.
    final answers = body['Answer'];
    return answers is List && answers.isNotEmpty;
  }

  /// `asyncValidator`-shaped adapter: null when the URL's host resolves (or
  /// there's no parseable host — that's the sync validator's job).
  Future<String?> validateUrlHost(String url) async {
    final uri = Uri.tryParse(UrlNormalizer.normalize(url));
    final host = uri?.host ?? '';
    if (host.isEmpty) return null;
    if (await isResolvableHost(host)) return null;
    // ARB-key TODO: add `text_field_url_host_unreachable` when running
    // intl codegen next.
    return Tr.t('text_field.url_host_unreachable', 'Site can’t be found');
  }
}
