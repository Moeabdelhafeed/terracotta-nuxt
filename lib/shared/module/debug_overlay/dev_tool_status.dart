import 'package:flutter/foundation.dart';

import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../core/devtools/perf_flags.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/tr.dart';
import '../../../data/services/remote_config_service.dart';
import '../../../data/stores/debug_overlay_prefs.dart';
import 'debug_overlay_models.dart';

/// Live "is this tool actively mutating app behavior?" registry — powers
/// the active dots on home tiles and the forgotten-simulator strip.
///
/// Two kinds of sources:
///  * reactive — [DebugOverlayPrefs] notifiers, merged into [listenable]
///    so the home rebuilds the moment a toggle flips;
///  * polled — cubit/service state with no notifier (connectivity
///    override, RC overrides). Cheap sync reads, re-checked on every
///    home build; opening/closing a tool view triggers one anyway.
class DevToolStatus {
  DevToolStatus._();

  /// Rebuild trigger for the reactive sources.
  static final Listenable listenable = Listenable.merge([
    DebugOverlayPrefs.mockMode,
    DebugOverlayPrefs.netSimLatencyMs,
    DebugOverlayPrefs.netSimFailEveryN,
    DebugOverlayPrefs.buildLockBypass,
    DebugOverlayPrefs.devicePreviewOverride,
    Tr.pseudoNotifier,
    PerfFlags.listenable,
  ]);

  /// The RC-override keys the maintenance simulator writes — counted as
  /// "maintenance sim active", not generic RC overrides.
  static bool _isMaintenanceKey(String key) => key.startsWith('maintenance');

  static bool isActive(DevTool tool) => switch (tool) {
    DevTool.mockToggle => DebugOverlayPrefs.mockMode.value,
    DevTool.networkSim =>
      DebugOverlayPrefs.netSimLatencyMs.value > 0 ||
          DebugOverlayPrefs.netSimFailEveryN.value > 0,
    DevTool.buildLockBypass => DebugOverlayPrefs.buildLockBypass.value,
    DevTool.devicePreview =>
      DebugOverlayPrefs.devicePreviewOverride.value != null,
    DevTool.connectivitySim =>
      getIt.isRegistered<ConnectivityCubit>() &&
          getIt<ConnectivityCubit>().hasDebugOverride,
    DevTool.maintenanceSim => RemoteConfigService.overrides.keys.any(
      _isMaintenanceKey,
    ),
    DevTool.l10n => Tr.pseudoEnabled,
    DevTool.perf => PerfFlags.anyActive,
    DevTool.rcOverrides => RemoteConfigService.overrides.keys.any(
      (k) => !_isMaintenanceKey(k),
    ),
    _ => false,
  };

  /// All currently-active tools (order of the enum).
  static List<DevTool> active() =>
      DevTool.values.where(isActive).toList(growable: false);

  /// Any simulator/override live right now — drives the pill's badge.
  static bool get anyActive => DevTool.values.any(isActive);
}
