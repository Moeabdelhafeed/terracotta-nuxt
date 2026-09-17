import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Parses incoming deep-link / universal-link URIs into in-app route
/// paths, with a pluggable rewrite pipeline for legacy URLs, short
/// links, and scheme normalization.
///
/// ## Responsibilities
///  - Strip scheme + host so `myapp://users/42`, `https://yourapp.com/users/42`,
///    and in-app `/users/42` resolve identically. A custom scheme puts
///    its first segment in the HOST rather than the path, so that half
///    is folded back on first — see [normalize].
///  - Apply a list of registered [DeepLinkRewrite]s in order. First match
///    wins. Use these for alias short links (`/u/ada` → `/users/42`) or
///    legacy URLs kept alive for shared external references.
///  - Dispatch the resolved path through GoRouter via [handle].
///
/// ## Platform wiring
/// GoRouter already receives OS-level link events from iOS universal
/// links and Android app links automatically. This handler sits on top
/// of that for custom schemes and rewrites. For runtime deep-link events
/// (e.g. links tapped while the app is already open), plug in one of:
///  - `app_links` package — recommended for iOS + Android custom schemes.
///  - `uni_links` package — older, still maintained.
/// Then in `main.dart`:
/// ```dart
/// final stream = AppLinks().uriLinkStream;
/// stream.listen((uri) => DeepLinkHandler.handle(uri, GoRouterConfig.router));
/// ```
class DeepLinkHandler {
  DeepLinkHandler._();

  static final List<DeepLinkRewrite> _rewrites = [];

  /// Register a rewrite. Called on every incoming link via [resolve].
  static void register(DeepLinkRewrite rewrite) => _rewrites.add(rewrite);

  /// Register multiple rewrites at once. Typically called at app start.
  static void registerAll(Iterable<DeepLinkRewrite> rewrites) =>
      _rewrites.addAll(rewrites);

  /// Remove every registered rewrite. Useful in tests.
  static void clear() => _rewrites.clear();

  /// Resolve [uri] into an in-app path (e.g. `/users/42?tab=posts`).
  ///
  /// - Scheme + host are ignored (a universal link and a custom-scheme
  ///   link to the same resource resolve to the same path).
  /// - Rewrites run in registration order; the first to return non-null
  ///   wins.
  /// - Returns `/` for a bare scheme with no path.
  static String resolve(Uri uri) {
    final normal = normalize(uri);

    for (final rw in _rewrites) {
      final rewritten = rw.apply(normal);
      if (rewritten != null) {
        if (kDebugMode) debugPrint('[DeepLink] rewrite: $uri → $rewritten');
        return rewritten;
      }
    }
    final path = normal.path.isEmpty ? '/' : normal.path;
    if (normal.hasQuery) return '$path?${normal.query}';
    return path;
  }

  /// A CUSTOM-SCHEME URI, read the way a web one is.
  ///
  /// `Uri` puts the first segment after `//` in the HOST, whatever the
  /// scheme — so the two links to one resource do not agree:
  ///
  /// ```text
  /// https://terracotta-ksa.com/gift/abc  host: terracotta-ksa.com  path: /gift/abc
  /// terracotta://gift/abc                host: gift               path: /abc
  /// ```
  ///
  /// Dropping the host, which is right for the web form, leaves the
  /// custom-scheme form resolving to `/abc` — a path no route claims,
  /// on the one link the scheme exists to carry. The class promises
  /// these two resolve identically; this is what makes that true.
  ///
  /// So for a non-web scheme the host is folded back onto the FRONT of
  /// the path, where it was always meant to be read. A URI written
  /// with three slashes (`terracotta:///gift/abc`) has no host and is
  /// already right, and passes through untouched.
  static Uri normalize(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https' || scheme.isEmpty) return uri;
    if (uri.host.isEmpty) return uri;

    return uri.replace(
      path: '/${uri.host}${uri.path}',
      // The host has moved into the path; leaving it in place would
      // have `Uri.toString` print it twice.
      host: '',
    );
  }

  /// Resolve [uri] and push the result onto [router]. Safe to call at
  /// any time; no-op if [uri] resolves to an empty path.
  static void handle(Uri uri, GoRouter router) {
    final path = resolve(uri);
    if (path.isEmpty) return;
    router.go(path);
  }
}

/// A URL rewrite rule — maps an incoming URL shape to an in-app path.
///
/// Two forms:
///
/// **Regex-based** — for pattern matches with captures:
/// ```dart
/// DeepLinkHandler.register(DeepLinkRewrite.regex(
///   RegExp(r'^/u/(\w+)$'),
///   (match) => '/users/${match.group(1)}',
/// ));
/// ```
///
/// **Exact-path** — for simple aliases:
/// ```dart
/// DeepLinkHandler.register(
///   const DeepLinkRewrite.exact('/legacy-home', '/'),
/// );
/// ```
class DeepLinkRewrite {
  /// Regex-based rewrite. [pattern] is matched against `uri.path`;
  /// [rewrite] builds the target path from the [Match].
  const DeepLinkRewrite.regex(RegExp this.pattern, this.rewrite)
    : _exactFrom = null,
      _exactTo = null;

  /// Exact-path rewrite.
  const DeepLinkRewrite.exact(String from, String to)
    : pattern = null,
      rewrite = null,
      _exactFrom = from,
      _exactTo = to;

  final RegExp? pattern;
  final String Function(Match match)? rewrite;
  final String? _exactFrom;
  final String? _exactTo;

  /// Apply this rewrite to [uri]. Returns the rewritten path or `null`
  /// if the rule doesn't match.
  String? apply(Uri uri) {
    if (_exactFrom != null) {
      if (uri.path != _exactFrom) return null;
      var out = _exactTo!;
      if (uri.hasQuery) out = '$out?${uri.query}';
      return out;
    }
    final match = pattern!.firstMatch(uri.path);
    if (match == null) return null;
    var out = rewrite!(match);
    if (uri.hasQuery && !out.contains('?')) out = '$out?${uri.query}';
    return out;
  }
}
