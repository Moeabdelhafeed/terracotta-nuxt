import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Visual density for row-heavy views (logs, kv tables, network).
/// Devs on small screens prefer [compact]; default is [comfy].
enum DebugDensity { comfy, compact }

/// Tiny JSON-on-disk store for the developer overlay. Persists pill +
/// window geometry, pinned tools, and density across sessions.
///
/// Lightweight by design — no shared_preferences dep, no Hive box,
/// just a single file under the app docs dir. Web skips disk and
/// keeps everything in memory (path_provider has no usable target).
///
/// Usage:
/// 1. `await DebugOverlayPrefs.ensureLoaded()` once at boot (or lazy
///    inside the overlay's [State.initState]).
/// 2. Read sync getters anywhere.
/// 3. Call save methods on user-driven changes — writes are
///    fire-and-forget, errors swallowed (debug tool, not critical).
class DebugOverlayPrefs {
  DebugOverlayPrefs._();

  static const _kFile = 'debug_overlay_prefs.json';

  static Offset? _pillPos;
  static bool _pillHidden = false;
  static Offset? _windowPos;
  static Size? _windowSize;
  static bool _loaded = false;
  static Future<void>? _loadFuture;

  /// Reactive — listens drive sidebar / pinned-strip rebuilds.
  static final ValueNotifier<List<String>> pinnedTools =
      ValueNotifier<List<String>>(const []);
  static final ValueNotifier<DebugDensity> density =
      ValueNotifier<DebugDensity>(DebugDensity.comfy);

  /// MRU list of deep-link URLs the dev has fired through the tester.
  /// Newest first. Capped to keep the list scannable.
  static const _kRecentLinksCap = 12;
  static final ValueNotifier<List<String>> recentDeepLinks =
      ValueNotifier<List<String>>(const []);

  /// MRU list of opened dev tools (enum names, newest first) — drives
  /// the recents chip row on the overlay home.
  static const _kRecentToolsCap = 5;
  static final ValueNotifier<List<String>> recentTools =
      ValueNotifier<List<String>>(const []);

  /// Collapsed category labels on the overlay home (persisted).
  static final ValueNotifier<Set<String>> collapsedCategories =
      ValueNotifier<Set<String>>(const {});

  /// Forces `ApiService.useMock`. Read by the mock-mode toggle tool;
  /// the API service mirrors this value into its static flag at boot
  /// + on every change.
  static final ValueNotifier<bool> mockMode = ValueNotifier<bool>(false);

  /// Live override for [DevicePreview]'s `enabled` flag. Default null
  /// = follow flavor's `useDevicePreview` decision; explicit value
  /// wins. `MyApp` wraps with a [ValueListenableBuilder] so toggling
  /// re-renders without hot-restart.
  static final ValueNotifier<bool?> devicePreviewOverride =
      ValueNotifier<bool?>(null);

  /// Whether the widget inspector selects a widget on tap.
  ///
  /// The framework resets this to `true` on every launch and again
  /// whenever select mode is exited, so a dev who turned it OFF got it
  /// back on the next full restart — while DevTools kept the inspector
  /// itself open, which made the app look frozen for no visible reason.
  /// Persisted so the restart mirrors the last state.
  static final ValueNotifier<bool> inspectorSelectOnTap = ValueNotifier<bool>(
    true,
  );

  /// Static debug bypass for the staging/uat password screen. Off by
  /// default — toggling on lets `BuildLockGuard` short-circuit while
  /// the dev iterates without entering the password every restart.
  static final ValueNotifier<bool> buildLockBypass = ValueNotifier<bool>(false);

  /// Network simulator — artificial latency in ms, fail-every-N
  /// counter, and HTTP status to inject. `0` disables the slot.
  static final ValueNotifier<int> netSimLatencyMs = ValueNotifier<int>(0);
  static final ValueNotifier<int> netSimFailEveryN = ValueNotifier<int>(0);
  static final ValueNotifier<int> netSimFailStatus = ValueNotifier<int>(503);

  /// Saved override scenarios ("offline QA", "demo mode", …) — each a
  /// JSON map captured by the Scenarios tool: RC overrides + sim
  /// toggles + perf flags. Newest first.
  static final ValueNotifier<List<Map<String, Object?>>> scenarios =
      ValueNotifier<List<Map<String, Object?>>>(const []);

  /// Persisted logger knobs from the settings tool (colors, top-bar
  /// segments, min level, env tag, buffer size). Null = never touched,
  /// logger keeps its compiled defaults. Applied once at boot by
  /// `initDi` — `Logger.configure` itself stays persistence-free.
  static Map<String, Object?>? _loggerConfig;
  static Map<String, Object?>? get loggerConfig =>
      _loggerConfig == null ? null : Map.unmodifiable(_loggerConfig!);

  static Offset? get pillPos => _pillPos;

  /// Pill flung off-screen — only the edge tab shows.
  static bool get pillHidden => _pillHidden;
  static Offset? get windowPos => _windowPos;
  static Size? get windowSize => _windowSize;
  static bool get loaded => _loaded;

  /// Load cached prefs from disk. Idempotent; safe to call from
  /// multiple init paths concurrently — second caller awaits the
  /// first's future.
  static Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loadFuture ??= _load();
  }

  static Future<void> _load() async {
    try {
      if (kIsWeb) return;
      final file = await _resolveFile();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _pillPos = _parseOffset(map['pillPos']);
      _pillHidden = map['pillHidden'] == true;
      _windowPos = _parseOffset(map['windowPos']);
      _windowSize = _parseSize(map['windowSize']);
      final pinned = map['pinnedTools'];
      if (pinned is List) {
        pinnedTools.value = pinned.whereType<String>().toList(growable: false);
      }
      final dens = map['density'];
      if (dens is String) {
        density.value = DebugDensity.values.firstWhere(
          (e) => e.name == dens,
          orElse: () => DebugDensity.comfy,
        );
      }
      final links = map['recentDeepLinks'];
      if (links is List) {
        recentDeepLinks.value = links.whereType<String>().toList(
          growable: false,
        );
      }
      final recents = map['recentTools'];
      if (recents is List) {
        recentTools.value = recents.whereType<String>().toList(growable: false);
      }
      final collapsed = map['collapsedCategories'];
      if (collapsed is List) {
        collapsedCategories.value = collapsed.whereType<String>().toSet();
      }
      final mock = map['mockMode'];
      if (mock is bool) mockMode.value = mock;
      final dpo = map['devicePreviewOverride'];
      if (dpo is bool) devicePreviewOverride.value = dpo;
      final blb = map['buildLockBypass'];
      if (blb is bool) buildLockBypass.value = blb;
      final sot = map['inspectorSelectOnTap'];
      if (sot is bool) inspectorSelectOnTap.value = sot;
      final nl = map['netSimLatencyMs'];
      if (nl is int) netSimLatencyMs.value = nl;
      final nf = map['netSimFailEveryN'];
      if (nf is int) netSimFailEveryN.value = nf;
      final ns = map['netSimFailStatus'];
      if (ns is int) netSimFailStatus.value = ns;
      final lc = map['loggerConfig'];
      if (lc is Map) _loggerConfig = Map<String, Object?>.from(lc);
      final sc = map['scenarios'];
      if (sc is List) {
        scenarios.value = List.unmodifiable([
          for (final s in sc)
            if (s is Map) Map<String, Object?>.from(s),
        ]);
      }
    } catch (_) {
      // Disk-corruption / permission errors are not actionable for a
      // debug tool. Fall through with empty cache.
    } finally {
      _loaded = true;
    }
  }

  static void savePillHidden(bool value) {
    _pillHidden = value;
    _persist();
  }

  static void savePillPos(Offset value) {
    _pillPos = value;
    _persist();
  }

  static void saveWindowPos(Offset value) {
    _windowPos = value;
    _persist();
  }

  static void saveWindowSize(Size value) {
    _windowSize = value;
    _persist();
  }

  static void togglePin(String toolName) {
    final current = List<String>.from(pinnedTools.value);
    if (current.contains(toolName)) {
      current.remove(toolName);
    } else {
      current.add(toolName);
    }
    pinnedTools.value = List.unmodifiable(current);
    _persist();
  }

  static void setDensity(DebugDensity next) {
    if (density.value == next) return;
    density.value = next;
    _persist();
  }

  /// Push [url] to the MRU list. Dedupes (existing entries hop to the
  /// front) and truncates to [_kRecentLinksCap].
  static void pushRecentDeepLink(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final next = [trimmed, ...recentDeepLinks.value.where((e) => e != trimmed)];
    if (next.length > _kRecentLinksCap) {
      next.removeRange(_kRecentLinksCap, next.length);
    }
    recentDeepLinks.value = List.unmodifiable(next);
    _persist();
  }

  static void clearRecentDeepLinks() {
    if (recentDeepLinks.value.isEmpty) return;
    recentDeepLinks.value = const [];
    _persist();
  }

  static void removeRecentDeepLink(String url) {
    final next = recentDeepLinks.value
        .where((e) => e != url)
        .toList(growable: false);
    if (next.length == recentDeepLinks.value.length) return;
    recentDeepLinks.value = List.unmodifiable(next);
    _persist();
  }

  /// Push an opened tool to the MRU list (dedupes to front, capped).
  static void pushRecentTool(String toolName) {
    final next = [toolName, ...recentTools.value.where((e) => e != toolName)];
    if (next.length > _kRecentToolsCap) {
      next.removeRange(_kRecentToolsCap, next.length);
    }
    recentTools.value = List.unmodifiable(next);
    _persist();
  }

  static void toggleCategoryCollapsed(String label) {
    final next = Set<String>.from(collapsedCategories.value);
    if (!next.remove(label)) next.add(label);
    collapsedCategories.value = Set.unmodifiable(next);
    _persist();
  }

  static void setMockMode(bool value) {
    if (mockMode.value == value) return;
    mockMode.value = value;
    _persist();
  }

  static void setDevicePreviewOverride(bool? value) {
    if (devicePreviewOverride.value == value) return;
    devicePreviewOverride.value = value;
    _persist();
  }

  static void setInspectorSelectOnTap(bool value) {
    if (inspectorSelectOnTap.value == value) return;
    inspectorSelectOnTap.value = value;
    _persist();
  }

  static void setBuildLockBypass(bool value) {
    if (buildLockBypass.value == value) return;
    buildLockBypass.value = value;
    _persist();
  }

  static void setNetSim({int? latencyMs, int? failEveryN, int? failStatus}) {
    if (latencyMs != null) netSimLatencyMs.value = latencyMs;
    if (failEveryN != null) netSimFailEveryN.value = failEveryN;
    if (failStatus != null) netSimFailStatus.value = failStatus;
    _persist();
  }

  /// Add (or replace, matching on `name`) a scenario snapshot.
  static void saveScenario(Map<String, Object?> scenario) {
    final name = scenario['name'];
    scenarios.value = List.unmodifiable([
      scenario,
      ...scenarios.value.where((s) => s['name'] != name),
    ]);
    _persist();
  }

  static void deleteScenario(String name) {
    final next = scenarios.value
        .where((s) => s['name'] != name)
        .toList(growable: false);
    if (next.length == scenarios.value.length) return;
    scenarios.value = List.unmodifiable(next);
    _persist();
  }

  static void saveLoggerConfig(Map<String, Object?> config) {
    _loggerConfig = Map<String, Object?>.from(config);
    _persist();
  }

  static void clearLoggerConfig() {
    if (_loggerConfig == null) return;
    _loggerConfig = null;
    _persist();
  }

  /// Reset EVERYTHING this store owns back to defaults (pill/window
  /// geometry, pins, recents, density, sim toggles) and persist the
  /// clean slate. The debug cache tool exposes this.
  static void reset() {
    _pillPos = null;
    _windowPos = null;
    _windowSize = null;
    pinnedTools.value = const [];
    density.value = DebugDensity.comfy;
    recentDeepLinks.value = const [];
    recentTools.value = const [];
    collapsedCategories.value = const {};
    mockMode.value = false;
    devicePreviewOverride.value = null;
    buildLockBypass.value = false;
    netSimLatencyMs.value = 0;
    netSimFailEveryN.value = 0;
    netSimFailStatus.value = 503;
    _loggerConfig = null;
    scenarios.value = const [];
    _persist();
  }

  static void _persist() {
    if (kIsWeb) return;
    () async {
      try {
        final file = await _resolveFile();
        await file.writeAsString(
          jsonEncode({
            if (_pillPos != null)
              'pillPos': {'x': _pillPos!.dx, 'y': _pillPos!.dy},
            'pillHidden': _pillHidden,
            if (_windowPos != null)
              'windowPos': {'x': _windowPos!.dx, 'y': _windowPos!.dy},
            if (_windowSize != null)
              'windowSize': {
                'w': _windowSize!.width,
                'h': _windowSize!.height,
              },
            'pinnedTools': pinnedTools.value,
            'density': density.value.name,
            'recentDeepLinks': recentDeepLinks.value,
            'recentTools': recentTools.value,
            'collapsedCategories': collapsedCategories.value.toList(),
            'mockMode': mockMode.value,
            if (devicePreviewOverride.value != null)
              'devicePreviewOverride': devicePreviewOverride.value,
            'buildLockBypass': buildLockBypass.value,
            'inspectorSelectOnTap': inspectorSelectOnTap.value,
            'netSimLatencyMs': netSimLatencyMs.value,
            'netSimFailEveryN': netSimFailEveryN.value,
            'netSimFailStatus': netSimFailStatus.value,
            if (_loggerConfig != null) 'loggerConfig': _loggerConfig,
            if (scenarios.value.isNotEmpty) 'scenarios': scenarios.value,
          }),
        );
      } catch (_) {
        // Swallow — debug-only persistence, no value in surfacing.
      }
    }();
  }

  static Future<io.File> _resolveFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return io.File('${dir.path}/$_kFile');
  }

  static Offset? _parseOffset(Object? raw) {
    if (raw is! Map) return null;
    final x = (raw['x'] as num?)?.toDouble();
    final y = (raw['y'] as num?)?.toDouble();
    if (x == null || y == null) return null;
    return Offset(x, y);
  }

  static Size? _parseSize(Object? raw) {
    if (raw is! Map) return null;
    final w = (raw['w'] as num?)?.toDouble();
    final h = (raw['h'] as num?)?.toDouble();
    if (w == null || h == null) return null;
    return Size(w, h);
  }
}
