import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/constants/enums/app/log_level.dart';
import '../../../core/utils/loggers/log_buffer.dart';
import '../../../data/stores/debug_overlay_prefs.dart';
import 'debug_overlay_models.dart';
import 'views/debug_assets_view.dart';
import 'views/debug_auth_view.dart';
import 'views/debug_blocs_view.dart';
import 'views/debug_build_info_view.dart';
import 'views/debug_build_lock_bypass_view.dart';
import 'views/debug_cache_nuker_view.dart';
import 'views/debug_clipboard_view.dart';
import 'views/debug_connectivity_sim_view.dart';
import 'views/debug_crash_injector_view.dart';
import 'views/debug_deep_links_view.dart';
import 'views/debug_device_preview_view.dart';
import 'views/debug_env_view.dart';
import 'views/debug_frame_timeline_view.dart';
import 'views/debug_l10n_view.dart';
import 'views/debug_logs_view.dart';
import 'views/debug_maintenance_sim_view.dart';
import 'views/debug_mock_toggle_view.dart';
import 'views/debug_network_sim_view.dart';
import 'views/debug_network_view.dart';
import 'views/debug_onboarding_reset_view.dart';
import 'views/debug_perf_view.dart';
import 'views/debug_permissions_view.dart';
import 'views/debug_rc_overrides_view.dart';
import 'views/debug_route_history_view.dart';
import 'views/debug_route_jumper_view.dart';
import 'views/debug_scenarios_view.dart';
import 'views/debug_service_locator_view.dart';
import 'views/debug_settings_view.dart';
import 'views/debug_splash_view.dart';
import 'views/debug_storage_view.dart';
import 'views/debug_theme_quick_view.dart';
import 'views/debug_theme_tokens_view.dart';
import 'views/debug_timeline_view.dart';
import 'views/debug_ui_lab_view.dart';
import 'views/debug_update_gate_sim_view.dart';
import 'views/dev_tools_home_view.dart';
import 'widgets/debug_pill.dart';
import 'widgets/floating_window_frame.dart';

export 'debug_overlay_models.dart'
    show DevTool, DevToolCategory, DebugOverlayTheme;

/// Programmatic entry point for opening the debug overlay's window
/// from outside the [GlobalDebugOverlay] subtree (e.g. a glance pill
/// in the app frame). The mounted overlay registers itself in
/// [State.initState]; callers invoke [openTool] without needing a
/// BuildContext anchored to the overlay.
class DebugOverlayController {
  DebugOverlayController._();

  static _OpenHandler? _handler;

  /// Open the overlay window and route directly to [tool]. No-op when
  /// the overlay is disabled (e.g. release builds without [enabled]
  /// override) or hasn't mounted yet.
  static void openTool(DevTool tool) => _handler?.call(tool);

  /// Close the floating window (back to the pill). Tools that navigate
  /// the APP underneath call this so the result is visible.
  static void closeWindow() => _closeHandler?.call();

  static VoidCallback? _closeHandler;

  /// Enum name of the tool view currently on top of the window's inner
  /// Navigator; `null` on home (or window closed). Maintained by the
  /// Navigator observer — the pinned strip hides the chip of the tool
  /// you're already looking at.
  static final ValueNotifier<String?> currentToolName = ValueNotifier<String?>(
    null,
  );

  /// Internal — registered by [GlobalDebugOverlay.initState].
  static void _register(_OpenHandler h) => _handler = h;

  /// Internal — called from [GlobalDebugOverlay.dispose].
  static void _unregister(_OpenHandler h) {
    if (identical(_handler, h)) _handler = null;
  }
}

typedef _OpenHandler = void Function(DevTool);

/// Mirrors the top route's name (tool enum name, null for home) into
/// [DebugOverlayController.currentToolName].
class _CurrentToolObserver extends NavigatorObserver {
  void _set(Route<dynamic>? route) {
    // Home route carries no name; tool routes are named tool.name.
    // didPush fires for the initial route DURING the Navigator's first
    // build — mutating the notifier synchronously there marks listeners
    // (pinned strip, density toggle) dirty mid-build. Defer to the end
    // of the frame; consumers are pure UI, one-frame lag is invisible.
    final name = route?.settings.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugOverlayController.currentToolName.value = name;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _set(newRoute);
}

/// Wraps [child] with a developer overlay accessible from anywhere via a
/// draggable floating bug button. Tapping the button opens a **floating,
/// resizable, draggable window** (not a full-width sheet) with a
/// semi-transparent background so the underlying UI remains visible.
///
/// The window hosts a single-pane Navigator — home lists the available
/// [DevTool]s, and tapping one drills into that tool's dedicated view.
/// Add a tool by appending to [DevTool] and wiring its view in [_ToolPage].
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => GlobalDebugOverlay(child: child!),
/// )
/// ```
///
/// By default the overlay renders only in debug builds (`kDebugMode`).
/// Pass [enabled] to override (e.g. enable in internal/staging flavors).
class GlobalDebugOverlay extends StatefulWidget {
  const GlobalDebugOverlay({
    super.key,
    required this.child,
    this.enabled,
  });

  final Widget child;

  /// Override the default visibility. When `null`, the overlay is shown
  /// only in debug builds.
  final bool? enabled;

  @override
  State<GlobalDebugOverlay> createState() => _GlobalDebugOverlayState();
}

class _GlobalDebugOverlayState extends State<GlobalDebugOverlay>
    with SingleTickerProviderStateMixin {
  /// Drives the pill → window morph. The window scales out of wherever
  /// the pill was sitting while the pill fades, so opening reads as the
  /// pill unfolding rather than a panel appearing from nowhere.
  late final AnimationController _openAnim = AnimationController(
    vsync: this,
    duration: AppDurations.normal,
  );

  /// Bounds the window grows OUT of — the pill's own, so the panel
  /// physically expands from it rather than scaling in place.
  Rect? _growFrom() => DebugPill.lastRect;

  bool _windowOpen = false;
  LogLevel? _latestLevel;
  StreamSubscription<LogEntry>? _sub;
  StreamSubscription<UserAccelerometerEvent>? _shakeSub;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Breadcrumb segments + canPop, derived from the inner Navigator's
  // top route (via [DebugOverlayController.currentToolName]) and read
  // by the frame's title bar. First entry is the always-rooted home
  // title. Derivation replaced the old per-page push/reset dance: a
  // push rebuilds the still-mounted home page during the transition
  // (secondaryAnimation), and home's every-build reset raced the tool
  // page's append — the title kept snapping back to 'Developer Tools'.
  final _titleNotifier = ValueNotifier<List<String>>(['Developer Tools']);
  final _canPopNotifier = ValueNotifier<bool>(false);
  NavigatorState? _navigator;

  /// Tool to auto-route to once the Navigator mounts. Cleared after the
  /// post-frame push so reopening goes back to the home hub.
  DevTool? _pendingTool;

  late final _OpenHandler _openHandler;

  bool get _active => widget.enabled ?? kDebugMode;

  @override
  void initState() {
    super.initState();
    if (_active) {
      _sub = LogBuffer.onAdd.listen((e) {
        if (!mounted) return;
        if (e.level.index < LogLevel.warning.index) return;
        setState(() => _latestLevel = e.level);
      });
      // Hydrate cached pill / window geometry. Pill + frame each
      // ensure-load on their own initState too, but kicking off the
      // read here means the cache is already warm by the time the
      // user expands the window.
      DebugOverlayPrefs.ensureLoaded();

      // Shake-to-open (mobile): gravity-filtered accelerometer spike
      // above ~2.2g opens the window. Debounced so one shake doesn't
      // fire twice; only opens, never closes (a shake mid-inspection
      // shouldn't dismiss the panel). Desktop/web have no
      // accelerometer — the stream errors, swallow it.
      _shakeSub = userAccelerometerEventStream().listen(
        (e) {
          if (_windowOpen) return;
          final gForce = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.81;
          if (gForce < 2.2) return;
          final now = DateTime.now();
          if (now.difference(_lastShakeAt).inMilliseconds < 1200) return;
          _lastShakeAt = now;
          _openWindow();
        },
        onError: (Object _) {},
      );

      // Desktop/web: F12 toggles the window — works even when the
      // pill is buried under app UI.
      HardwareKeyboard.instance.addHandler(_onKey);
    }
    _openHandler = _openWithTool;
    DebugOverlayController._register(_openHandler);
    DebugOverlayController._closeHandler = _closeWindow;
    DebugOverlayController.currentToolName.addListener(_syncTitleFromRoute);
  }

  @override
  void dispose() {
    DebugOverlayController.currentToolName.removeListener(_syncTitleFromRoute);
    if (identical(DebugOverlayController._closeHandler, _closeWindow)) {
      DebugOverlayController._closeHandler = null;
    }
    DebugOverlayController._unregister(_openHandler);
    _sub?.cancel();
    _shakeSub?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _titleNotifier.dispose();
    _canPopNotifier.dispose();
    _openAnim.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.f12) return false;
    _windowOpen ? _closeWindow() : _openWindow();
    return true;
  }

  /// Title bar follows the inner Navigator's top route: home →
  /// `['Developer Tools']`, a tool view → `[home, toolLabel]`.
  void _syncTitleFromRoute() {
    final name = DebugOverlayController.currentToolName.value;
    DevTool? tool;
    for (final t in DevTool.values) {
      if (t.name == name) {
        tool = t;
        break;
      }
    }
    _titleNotifier.value = tool == null
        ? ['Developer Tools']
        : ['Developer Tools', tool.label];
    _canPopNotifier.value = tool != null;
  }

  void _openWindow() {
    setState(() {
      _windowOpen = true;
      _latestLevel = null;
    });
    _runOpenAnim();
  }

  void _runOpenAnim() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _openAnim.value = 1;
    } else {
      _openAnim.forward();
    }
  }

  /// Open + auto-route. Pops the existing Navigator to home before
  /// pushing so the back-stack stays bounded at 1 even if the dev taps
  /// the sidebar / pinned strip / pill repeatedly.
  void _openWithTool(DevTool tool) {
    if (_windowOpen) {
      _navigator?.popUntil((r) => r.isFirst);
      _navigator?.push(_toolRoute(tool));
      return;
    }
    setState(() {
      _windowOpen = true;
      _latestLevel = null;
      _pendingTool = tool;
    });
    _runOpenAnim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingTool == null) return;
      final tool = _pendingTool!;
      _pendingTool = null;
      _navigator?.push(_toolRoute(tool));
    });
  }

  void _closeWindow() {
    // The inner Navigator is disposed with the window — the observer
    // never sees a pop, so clear the current-tool marker here.
    DebugOverlayController.currentToolName.value = null;
    setState(() => _windowOpen = false);
    // Reverse rather than snap: the window shrinks back toward the
    // pill it came from.
    if (MediaQuery.disableAnimationsOf(context)) {
      _openAnim.value = 0;
    } else {
      _openAnim.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return widget.child;

    return Stack(
      // The pill carries a drop shadow and parks flush against the
      // screen edge — the default hardEdge clip lops that shadow off.
      clipBehavior: Clip.none,
      children: [
        widget.child,
        // The whole overlay is a DEVELOPER tool, authored in English:
        // its labels, log lines, stack traces and JSON dumps are all
        // LTR content. Letting it mirror under an Arabic app locale
        // reverses the chrome around text that never flips, which reads
        // as broken rather than localized. Pinned here so the window,
        // the pill and every tool view agree.
        Directionality(
          textDirection: TextDirection.ltr,
          child: AnimatedBuilder(
            animation: _openAnim,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_openAnim.value);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Both children are Positioned, so the entrance effects
                  // are passed INTO them rather than wrapped around them.
                  if (_openAnim.value > 0)
                    _buildWindow(entrance: t, entranceFrom: _growFrom()),
                  // The pill fades as the window takes over, so the two
                  // are never both fully drawn.
                  if (_openAnim.value < 1)
                    DebugPill(
                      opacity: 1 - t,
                      onTap: _openWindow,
                      badgeColor: _latestLevel == null
                          ? null
                          : DebugOverlayTheme.levelColor(_latestLevel!),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWindow({double entrance = 1, Rect? entranceFrom}) {
    return DefaultTextStyle(
      style: DebugOverlayTheme.ui,
      child: ValueListenableBuilder<bool>(
        valueListenable: _canPopNotifier,
        builder: (_, canPop, _) {
          return ValueListenableBuilder<List<String>>(
            valueListenable: _titleNotifier,
            builder: (_, breadcrumb, _) {
              return FloatingWindowFrame(
                entrance: entrance,
                entranceFrom: entranceFrom,
                breadcrumb: breadcrumb,
                onClose: _closeWindow,
                canGoBack: canPop,
                onBack: () => _navigator?.maybePop(),
                child: _buildNavigator(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNavigator() {
    return HeroControllerScope.none(
      child: Navigator(
        observers: [_CurrentToolObserver()],
        onGenerateRoute: (settings) => PageRouteBuilder(
          settings: settings,
          pageBuilder: (ctx, _, _) {
            _navigator = Navigator.of(ctx);
            return _HomePage(
              onOpenTool: (tool) {
                Navigator.of(ctx).push(_toolRoute(tool));
              },
            );
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      ),
    );
  }

  Route _toolRoute(DevTool tool) {
    // Every open path funnels through here — record for the home's
    // recents row.
    DebugOverlayPrefs.pushRecentTool(tool.name);
    return _buildToolRoute(tool);
  }

  Route _buildToolRoute(DevTool tool) => PageRouteBuilder(
    settings: RouteSettings(name: tool.name),
    pageBuilder: (_, _, _) => _ToolPage(tool: tool),
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

// ─── Pages ─────────────────────────────────────────────────────
// Title-bar breadcrumb + canPop are DERIVED from the Navigator's top
// route by [_GlobalDebugOverlayState._syncTitleFromRoute] — pages don't
// write them. (A per-page write raced the push transition: the still-
// mounted home rebuilt underneath and reset the trail.)

class _HomePage extends StatelessWidget {
  const _HomePage({required this.onOpenTool});
  final ValueChanged<DevTool> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return DevToolsHomeView(onOpenTool: onOpenTool);
  }
}

class _ToolPage extends StatefulWidget {
  const _ToolPage({required this.tool});
  final DevTool tool;

  @override
  State<_ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<_ToolPage> {
  @override
  Widget build(BuildContext context) {
    return switch (widget.tool) {
      DevTool.logs => const DebugLogsView(),
      DevTool.network => const DebugNetworkView(),
      DevTool.env => const DebugEnvView(),
      DevTool.buildInfo => const DebugBuildInfoView(),
      DevTool.storage => const DebugStorageView(),
      DevTool.routeHistory => const DebugRouteHistoryView(),
      DevTool.routeJumper => const DebugRouteJumperView(),
      DevTool.splash => const DebugSplashView(),
      DevTool.connectivitySim => const DebugConnectivitySimView(),
      DevTool.crashInjector => const DebugCrashInjectorView(),
      DevTool.rcOverrides => const DebugRcOverridesView(),
      DevTool.updateGateSim => const DebugUpdateGateSimView(),
      DevTool.themeQuick => const DebugThemeQuickView(),
      DevTool.perf => const DebugPerfView(),
      DevTool.uiLab => const DebugUiLabView(),
      DevTool.deepLinks => const DebugDeepLinksView(),
      DevTool.auth => const DebugAuthView(),
      DevTool.blocs => const DebugBlocsView(),
      DevTool.permissions => const DebugPermissionsView(),
      DevTool.themeTokens => const DebugThemeTokensView(),
      DevTool.l10n => const DebugL10nView(),
      DevTool.serviceLocator => const DebugServiceLocatorView(),
      DevTool.frameTimeline => const DebugFrameTimelineView(),
      DevTool.timeline => const DebugTimelineView(),
      DevTool.scenarios => const DebugScenariosView(),
      DevTool.clipboard => const DebugClipboardView(),
      DevTool.assets => const DebugAssetsView(),
      DevTool.mockToggle => const DebugMockToggleView(),
      DevTool.networkSim => const DebugNetworkSimView(),
      DevTool.maintenanceSim => const DebugMaintenanceSimView(),
      DevTool.buildLockBypass => const DebugBuildLockBypassView(),
      DevTool.cacheNuker => const DebugCacheNukerView(),
      DevTool.onboardingReset => const DebugOnboardingResetView(),
      DevTool.devicePreview => const DebugDevicePreviewView(),
      DevTool.settings => const DebugSettingsView(),
    };
  }
}
