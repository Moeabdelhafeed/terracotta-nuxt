import 'package:clock/clock.dart';

/// A value that is expensive to read and stays true for a while.
///
/// The TTL is read through [ttl] on every check rather than captured
/// at construction, because the policy is set in `bootstrap()` and
/// these caches are `static final` — they are built when the class is
/// first touched, which can be either side of that call.
class TtlCache<T> {
  TtlCache(this.ttl);

  /// Read fresh each time — see the class doc.
  final Duration Function() ttl;

  T? _value;
  DateTime? _fetchedAt;
  Future<T>? _inFlight;
  int _generation = 0;

  bool get _isFresh {
    final fetched = _fetchedAt;
    if (fetched == null) return false;
    final window = ttl();
    if (window <= Duration.zero) return false;
    return clock.now().difference(fetched) < window;
  }

  /// The cached value if fresh, otherwise [fetch] — and only ONE
  /// [fetch] at a time.
  ///
  /// Concurrent callers used to each miss and each start their own
  /// platform call: bootstrap and the first page both asking for the
  /// device id is two round-trips for one answer, and on a cold start
  /// they are microseconds apart. They share the in-flight future now.
  ///
  /// A THROW is not cached and not swallowed. The previous version
  /// wrapped fetches that caught internally and returned a fallback,
  /// so one failed connectivity probe answered "offline" for the next
  /// thirty seconds — a cached lie, indistinguishable from the truth.
  Future<T> get(Future<T> Function() fetch, {bool forceRefresh = false}) {
    if (!forceRefresh && _isFresh) return Future<T>.value(_value as T);
    final pending = _inFlight;
    if (!forceRefresh && pending != null) return pending;
    return _inFlight = _run(fetch, ++_generation);
  }

  /// [generation] is what makes a superseded fetch harmless: an
  /// `invalidate()` or a `forceRefresh` during a slow platform call
  /// moves it on, and the old call then lands with nothing to write
  /// to.
  Future<T> _run(Future<T> Function() fetch, int generation) async {
    try {
      final value = await fetch();
      if (generation == _generation) {
        _value = value;
        _fetchedAt = clock.now();
      }
      return value;
    } finally {
      if (generation == _generation) _inFlight = null;
    }
  }

  /// The last value, fresh or stale, without triggering a fetch.
  T? get peek => _value;

  /// Whether [peek] would answer with something still inside the TTL.
  bool get isFresh => _isFresh;

  void invalidate() {
    _value = null;
    _fetchedAt = null;
    _inFlight = null;
    _generation++;
  }
}
