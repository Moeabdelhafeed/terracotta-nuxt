import 'package:flutter/widgets.dart';

import '../../../core/bootstrap/bootstrap_maintenance.dart';
import '../../../core/bootstrap/bootstrap_update.dart';
import '../../../core/connectivity/connectivity_cubit.dart';
import '../../../core/devtools/network_sim.dart';
import '../../../core/devtools/perf_flags.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/localization/tr.dart';
import '../../../data/services/remote_config_service.dart';
import '../../../data/stores/debug_overlay_prefs.dart';
import 'dev_tool_status.dart';

/// One-tap "back to reality": clears every simulator / override the
/// overlay can set, so a forgotten toggle can't masquerade as an app
/// bug. Complements [DevToolStatus] — anything that reports active
/// there must be cleared here.
abstract final class DevToolReset {
  /// Clears everything. Returns the number of tools that were active
  /// before the reset (for the confirmation toast).
  static Future<int> resetAll() async {
    final wasActive = DevToolStatus.active().length;

    // Network sim + one-shot.
    NetworkSim.oneShot = false;
    NetworkSim.resetCounter();
    DebugOverlayPrefs.setNetSim(latencyMs: 0, failEveryN: 0, failStatus: 503);

    // Prefs-backed toggles.
    DebugOverlayPrefs.setMockMode(false);
    DebugOverlayPrefs.setBuildLockBypass(false);
    DebugOverlayPrefs.setDevicePreviewOverride(null);

    // RC overrides (covers the maintenance sim too) → reseed the
    // cubits that snapshot RC values.
    RemoteConfigService.clearAllOverrides();
    seedMaintenanceFromRemoteConfig();
    await seedUpdateFromRemoteConfig();

    // Connectivity forced verdict / VPN flag.
    if (getIt.isRegistered<ConnectivityCubit>()) {
      getIt<ConnectivityCubit>().debugClearOverrides();
    }

    // Pseudo-localization (defers its own reassemble).
    Tr.setPseudo(false);

    // Perf paint flags — the paint-debug globals need a reassemble to
    // repaint clean, matching how the perf view toggles them.
    final needsReassemble =
        PerfFlags.repaintRainbow.value || PerfFlags.layoutBounds.value;
    PerfFlags.setSlowAnimations(false);
    PerfFlags.setRepaintRainbow(false);
    PerfFlags.setLayoutBounds(false);
    if (needsReassemble) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.reassembleApplication();
      });
    }

    return wasActive;
  }
}
