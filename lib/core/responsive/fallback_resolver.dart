/// Walk-down-then-up fallback resolver shared by [ResponsiveLayout],
/// [ResponsiveValue], and [BoxResponsive]. Given a list of buckets
/// (small → large) and the [current] bucket, returns the first
/// non-`null` slot found by:
///
///   1. Walking *down* from [current] toward index 0.
///   2. If no smaller slot is filled, walking *up* from [current] + 1
///      to the end of the list.
///
/// "Down-first" matches the user-facing rule "auto-fallback from a
/// smaller design" — a layout written for `compact` is the safest
/// default when an `expanded`-only layout was forgotten.
///
/// Returns `null` when every slot in [slots] is `null`.
T? resolveFallback<B, T>({
  required List<B> buckets,
  required B current,
  required List<T?> slots,
  bool walkUpAsFallback = true,
}) {
  assert(
    buckets.length == slots.length,
    'buckets and slots must be the same length',
  );
  final currentIndex = buckets.indexOf(current);
  if (currentIndex < 0) return null;

  for (var i = currentIndex; i >= 0; i--) {
    final slot = slots[i];
    if (slot != null) return slot;
  }
  if (!walkUpAsFallback) return null;
  for (var i = currentIndex + 1; i < slots.length; i++) {
    final slot = slots[i];
    if (slot != null) return slot;
  }
  return null;
}

/// Same as [resolveFallback] but throws a descriptive [StateError] when
/// every slot is `null`. Use this for required widgets/values.
T resolveFallbackOrThrow<B, T>({
  required List<B> buckets,
  required B current,
  required List<T?> slots,
  String label = 'responsive slot',
  bool walkUpAsFallback = true,
}) {
  final value = resolveFallback<B, T>(
    buckets: buckets,
    current: current,
    slots: slots,
    walkUpAsFallback: walkUpAsFallback,
  );
  if (value == null) {
    throw StateError(
      '$label requires at least one non-null entry across $buckets.',
    );
  }
  return value;
}
