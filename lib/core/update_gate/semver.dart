/// Inline semver helpers — purpose-built for app version comparison.
///
/// Accepts:
/// - `1.2.3`        — major.minor.patch
/// - `1.2.3+45`     — with build number suffix
/// - `1.2`          — missing patch defaults to 0
/// - `1`            — missing minor + patch default to 0
///
/// Pre-release tags (`1.2.3-beta`) are not interpreted; the tag is
/// stripped and the numeric part compared. If you need full Pub
/// semver semantics, swap in `pub_semver`.
class Semver {
  const Semver._();

  /// Parse a version string into `[major, minor, patch, build?]`.
  /// Returns `null` for unparseable input — callers treat null as
  /// "no version available, skip the gate".
  static List<int>? parse(String raw) {
    if (raw.trim().isEmpty) return null;
    var s = raw.trim();
    // Strip prerelease tags like `1.2.3-beta`.
    final dashIdx = s.indexOf('-');
    if (dashIdx >= 0) s = s.substring(0, dashIdx);

    int? build;
    final plusIdx = s.indexOf('+');
    if (plusIdx >= 0) {
      build = int.tryParse(s.substring(plusIdx + 1));
      s = s.substring(0, plusIdx);
    }

    final parts = s.split('.');
    if (parts.isEmpty) return null;
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null) return null;
      nums.add(n);
    }
    while (nums.length < 3) {
      nums.add(0);
    }
    if (build != null) nums.add(build);
    return nums;
  }

  /// Compare two version strings. Returns:
  /// - negative when `a < b`
  /// - 0 when equal
  /// - positive when `a > b`
  ///
  /// Unparseable input on either side returns `0` (treated as equal —
  /// the gate falls through, matching "no version configured" intent).
  static int compare(String a, String b) {
    final av = parse(a);
    final bv = parse(b);
    if (av == null || bv == null) return 0;
    final len = av.length > bv.length ? av.length : bv.length;
    for (var i = 0; i < len; i++) {
      final l = i < av.length ? av[i] : 0;
      final r = i < bv.length ? bv[i] : 0;
      if (l != r) return l - r;
    }
    return 0;
  }

  static bool lessThan(String a, String b) => compare(a, b) < 0;
  static bool greaterThan(String a, String b) => compare(a, b) > 0;
  static bool equal(String a, String b) => compare(a, b) == 0;
}
