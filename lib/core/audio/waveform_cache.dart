import 'package:flutter/foundation.dart';

/// Decoded waveforms, kept so the same audio is decoded ONCE.
///
/// Decoding is expensive twice over: a URL is downloaded to a temp
/// file and then run through the plugin. It was happening per WIDGET —
/// a chat thread showing one voice note in a list and again in a
/// preview decoded it twice, and a list of ten messages over the same
/// clip decoded it ten times.
///
/// Two things are needed, and only one of them is a cache:
///
/// * **A finished decode is remembered**, so the second widget draws
///   its waveform on the first frame instead of a flat line.
/// * **An IN-FLIGHT decode is shared.** Ten players mount in the same
///   frame, so all ten miss the cache — a plain map would start ten
///   downloads and then store the same answer ten times.
///
/// A FAILURE is not remembered. Nearly every failure here is a URL
/// that timed out, and caching it would mean a retry could never
/// succeed for the rest of the session.
class WaveformCache {
  const WaveformCache._();

  /// Insertion-ordered, which is what makes the eviction below the
  /// OLDEST rather than an arbitrary one.
  static final _entries = <String, List<double>>{};
  static final _inFlight = <String, Future<List<double>?>>{};

  /// How many decodes are held. A waveform is a few hundred doubles,
  /// so this is small; the cap exists so a feed scrolled for an hour
  /// does not grow without end.
  static const maxEntries = 32;

  /// What is held right now.
  @visibleForTesting
  static int get size => _entries.length;

  /// How many decodes are running.
  @visibleForTesting
  static int get inFlight => _inFlight.length;

  /// The decode for [key], running [decode] only if nothing else
  /// already has.
  static Future<List<double>?> resolve(
    String key,
    Future<List<double>?> Function() decode,
  ) {
    final hit = _entries[key];
    if (hit != null) return Future.value(hit);

    final running = _inFlight[key];
    if (running != null) return running;

    final future = decode().then((out) {
      if (out != null && out.isNotEmpty) _put(key, out);
      return out;
    });
    // `whenComplete` rather than a `then` — a decode that THREW must
    // clear its slot too, or that source can never be tried again.
    //
    // The braces are load-bearing. `=> _inFlight.remove(key)` RETURNS
    // the removed future — which is this very future — and
    // `whenComplete` waits on whatever its callback returns, so it
    // waited on itself and every decode hung for ever.
    final tracked = future.whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = tracked;
    return tracked;
  }

  static void _put(String key, List<double> values) {
    _entries[key] = values;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Forgets everything. For tests, and for an app shedding memory.
  static void clear() {
    _entries.clear();
    _inFlight.clear();
  }
}
