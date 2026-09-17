import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/api/calls/general_apis.dart';
import '../utils/loggers/logger.dart';
import 'tr.dart';

/// Fetches a remote translation map (key → value) and installs it into
/// the [Tr] facade, which then overlays it on top of the ARB-generated
/// `S` class at read time.
///
/// Call [load] on app boot and again after every language change. Safe
/// to call even when no remote is configured — failure degrades
/// silently to ARB-only behavior.
///
/// Registered as a plain singleton in `service_locator.dart`; boot
/// sequence awaits `getIt<RemoteTranslations>().init()`.
///
/// ## Missing-key reporter (debug only)
///
/// While developing, every flat key that [Tr.t] falls back on is
/// batched and POSTed to the backend via [GeneralApis.addTranslation],
/// so the dictionary auto-populates as you navigate. Deduped per
/// session, debounced 2s, gated behind [kDebugMode], and disabled
/// until the first successful [load] (to avoid spamming the backend
/// with every app string before translations have even been fetched).
///
/// Release builds never install the callback — the reporter simply
/// doesn't exist in production binaries.
///
/// ## Locale handling
/// The backend endpoint ([GeneralApis.getTranslations]) currently
/// doesn't take a locale — it returns a flat map for the app's
/// active group. If your backend supports per-locale payloads, pass
/// the locale through and branch on the response shape here.
class RemoteTranslations {
  /// True once [load] has completed at least once (successfully or not).
  /// Useful for splash screens that want to block until translations
  /// are resolved.
  bool get isLoaded => _isLoaded;
  bool _isLoaded = false;

  /// Keys discovered as missing since the last flush. Flushes on a 2s
  /// debounce or when [flushMissingKeys] is called explicitly (e.g.
  /// from an app-backgrounded lifecycle hook).
  final Map<String, String> _pending = {};
  Timer? _flushTimer;

  /// Every missing key seen THIS SESSION (never cleared by flushes) —
  /// the local sink for adopters without a translations backend. The
  /// L10n dev tool's "copy missing as ARB" button reads this.
  final Map<String, String> _sessionMissing = {};

  /// Session-collected missing keys as a ready-to-paste ARB fragment
  /// (sorted, pretty-printed). Empty-map JSON when nothing was missed.
  String missingAsArbJson() {
    final sorted = Map.fromEntries(
      _sessionMissing.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return const JsonEncoder.withIndent('  ').convert(sorted);
  }

  /// Count for badges/buttons.
  int get missingCount => _sessionMissing.length;

  /// Per-key retry counter — if the backend rejects a specific key
  /// repeatedly we stop trying rather than loop forever.
  static const int _maxRetries = 3;
  final Map<String, int> _retries = {};

  /// Debounce window before flushing pending missing keys.
  static const Duration _flushDebounce = Duration(seconds: 2);

  /// Pull the latest remote translations and install them into [Tr].
  /// Errors are logged (debug only) and swallowed — ARB is always a
  /// valid fallback, so translation failures should never take the app
  /// down.
  Future<void> load({String? group}) async {
    final result = await GeneralApis.getTranslations(group: group ?? 'app');
    result
        .onSuccess((data) {
          Tr.setRemote(data.map((k, v) => MapEntry(k, v.toString())));
        })
        .onFailure((e) {
          if (kDebugMode) {
            Logger.m.w('[RemoteTranslations] load failed: ${e.message}');
          }
        });
    // Only arm the missing-key reporter after the first load attempt,
    // otherwise every key in the app gets reported during the cold-start
    // window before translations arrive.
    if (kDebugMode && !_isLoaded) _installMissingKeyReporter();
    _isLoaded = true;
  }

  /// Drop all remote overrides — subsequent [Tr.t] / [Tr.plural] calls
  /// will return ARB values. Use in logout flows or tests.
  void clear() {
    Tr.clearRemote();
    Tr.onMissingKey(null);
    Tr.resetSeenMissing();
    _flushTimer?.cancel();
    _pending.clear();
    _retries.clear();
    _isLoaded = false;
  }

  Future<RemoteTranslations> init() async {
    await load();
    return this;
  }

  void dispose() {
    _flushTimer?.cancel();
  }

  // ─── Missing-key reporter (debug only) ──────────────────────────────

  void _installMissingKeyReporter() {
    Tr.onMissingKey((key, defaultValue) {
      _pending[key] = defaultValue;
      _sessionMissing[key] = defaultValue;
      Logger.m.d(
        '[Tr] missing key "$key" → queued (pending: ${_pending.length})',
      );
      _flushTimer?.cancel();
      _flushTimer = Timer(_flushDebounce, flushMissingKeys);
    });
  }

  /// Flush the accumulated missing-key queue to the backend. Safe to
  /// call manually (e.g. when the app backgrounds) to force an
  /// immediate push without waiting for the debounce.
  Future<void> flushMissingKeys() async {
    if (_pending.isEmpty) return;
    final batch = Map<String, String>.from(_pending);
    _pending.clear();

    // ─── Current path: one request per key ────────────────────────
    // Sequential awaits keep the backend from getting hammered when
    // a screen discovers many keys at once. Typical batch size is
    // small (1-10 keys) so the latency cost is acceptable for a
    // debug-only flow.
    for (final entry in batch.entries) {
      final result = await GeneralApis.addTranslation(
        key: entry.key,
        defaultValue: entry.value,
      );
      result
          .onSuccess((data) {
            // Merge the server's fresh map back into Tr so later reads
            // of the same key in this session pick up any canonicalized
            // value without waiting for the next cold start.
            Tr.setRemote(data.map((k, v) => MapEntry(k, v.toString())));
            _retries.remove(entry.key);
          })
          .onFailure((e) {
            final n = (_retries[entry.key] ?? 0) + 1;
            if (n < _maxRetries) {
              _retries[entry.key] = n;
              _pending[entry.key] = entry.value; // re-queue
              Logger.m.w(
                '[Tr] add "${entry.key}" failed (retry $n/$_maxRetries): ${e.message}',
              );
            } else {
              _retries.remove(entry.key);
              Logger.m.e(
                '[Tr] add "${entry.key}" exhausted retries, giving up',
              );
            }
          });
    }

    // ─── Future path: bulk add (flip to this once backend supports it) ─
    //
    // When the backend ships `POST /translations/bulk-add` accepting a
    // body like:
    //   { "translations": { "key1": "default1", "key2": "default2" } }
    // …uncomment the block below (and the matching stub in
    // `GeneralApis`), delete the sequential loop above, and you get
    // one round trip for N keys:
    //
    // final result = await GeneralApis.addTranslationsBulk(batch);
    // result
    //     .onSuccess((data) {
    //       Tr.setRemote(data.map((k, v) => MapEntry(k, v.toString())));
    //       for (final k in batch.keys) _retries.remove(k);
    //     })
    //     .onFailure((e) {
    //       // Requeue the whole batch under retry bookkeeping.
    //       for (final entry in batch.entries) {
    //         final n = (_retries[entry.key] ?? 0) + 1;
    //         if (n < _maxRetries) {
    //           _retries[entry.key] = n;
    //           _pending[entry.key] = entry.value;
    //         }
    //       }
    //       Logger.m.w('[Tr] bulk-add failed: ${e.message}');
    //     });

    if (_pending.isNotEmpty) {
      // Something re-queued — schedule another flush.
      _flushTimer?.cancel();
      _flushTimer = Timer(_flushDebounce, flushMissingKeys);
    } else {
      Logger.m.d('[Tr] flushed ${batch.length} keys to backend');
    }
  }
}
