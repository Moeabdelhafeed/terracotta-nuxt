import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/api_service.dart';
import '../../data/services/navigation_service.dart';
import '../../data/services/preferences/locale_service.dart';
import '../../data/services/preferences/role_service.dart';
import '../../data/services/preferences/theme_service.dart';
import '../../data/stores/debug_overlay_prefs.dart';
import '../../shared/module/dialog/global_dialog.dart';
import '../../shared/module/sheet/global_sheet.dart';
import '../../shared/module/toast/global_toast.dart';
import '../auth/session_expiry.dart';
import '../constants/enums/app/log_level.dart';
import '../devtools/debug_bloc_observer.dart';
import '../devtools/persistent_widget_inspector.dart';
import '../di/service_locator.dart';
import '../navigation/go_router_config.dart';
import '../utils/device/info/screen_radius.dart';
import '../utils/loggers/log_buffer.dart';
import '../utils/loggers/logger.dart';

/// Build the DI graph and bind globals that depend on it.
///
/// 1. Construct service locator + populate registrations.
/// 2. Register `NavigationService` (depends on the GoRouter instance).
/// 3. Bind navigator-key statics on dialog / sheet / toast helpers.
/// 4. Touch eager services (`ThemeService` installs a platform-brightness
///    listener in its constructor — bind before first paint).
///
/// The languages catalog is deliberately NOT refreshed here. That is a
/// network call, and the Terracotta API rejects a request whose
/// `X-Device-Id` or `X-FCM-Token` is empty with a 422 — both of which
/// are still unset this early. `bootstrap` refreshes it once those
/// exist, and before `setupInitialState` needs it.
Future<void> initDi() async {
  // Wire the debug-overlay's bloc observer FIRST so every cubit/bloc
  // constructed below shows up in the inspector. Cheap (<1µs per
  // transition) but gated to debug builds anyway.
  if (kDebugMode) {
    Bloc.observer = DebugBlocObserver();
  }

  await initServiceLocator();

  // Mirror the dev-overlay mock-mode toggle into the static
  // `ApiService.useMock` flag. Read once for the cached value, then
  // listen for live flips.
  if (kDebugMode) {
    ApiService.useMock = DebugOverlayPrefs.mockMode.value;
    DebugOverlayPrefs.mockMode.addListener(() {
      ApiService.useMock = DebugOverlayPrefs.mockMode.value;
    });
    // Re-apply logger knobs persisted by the settings tool —
    // setupLogging ran earlier with compiled defaults, so a couple of
    // pre-frame boot lines may still use those.
    unawaited(
      DebugOverlayPrefs.ensureLoaded().then((_) {
        _applyPersistedLoggerConfig();
        _wireInspectorTapMode();
      }),
    );
  }

  getIt.registerLazySingleton<NavigationService>(
    () => NavigationService(
      router: GoRouterConfig.router,
      navigatorKey: GoRouterConfig.navigatorKey,
    ),
  );

  // A 401 on this API means the caller is not signed in — there is no
  // refresh token to try. `SessionExpiry` ends a dead session and asks.
  // Wired AFTER the navigator key, since the prompt needs it.
  ApiService.onTokenExpired = SessionExpiry.onUnauthorized;

  GlobalDialog.navigatorKey = GoRouterConfig.navigatorKey;
  GlobalBottomSheet.navigatorKey = GoRouterConfig.navigatorKey;
  GlobalTopSheet.navigatorKey = GoRouterConfig.navigatorKey;

  await DeviceRadius.init();
  GlobalToast.navigatorKey = getIt<NavigationService>().navigatorKey;

  getIt<LocaleService>();
  getIt<ThemeService>();
  getIt<RoleService>();
}

/// Apply logger knobs the settings tool persisted in a previous
/// session. Absent map (or absent keys) = keep compiled defaults.
/// The environment tag is only set when saved non-empty — the default
/// is null either way.
/// Makes the widget inspector's tap mode survive a restart.
///
/// The framework treats "select on tap" as a per-launch default: true at
/// startup, and reset to true again whenever select mode is exited. So a
/// dev who deliberately turned it OFF got it back on the next full
/// restart — with DevTools keeping the inspector itself open, which
/// meant the app silently intercepted taps again with nothing on screen
/// to explain it.
void _wireInspectorTapMode() {
  PersistentWidgetInspector.selectOnTap =
      DebugOverlayPrefs.inspectorSelectOnTap.value;

  // Re-apply on every ENTRY into select mode, not just at boot —
  // otherwise the preference survives only until the first exit resets
  // it.
  PersistentWidgetInspector.selectModeNotifier.addListener(() {
    if (!PersistentWidgetInspector.selectMode) return;
    PersistentWidgetInspector.selectOnTap =
        DebugOverlayPrefs.inspectorSelectOnTap.value;
  });

  // Record ONLY changes made while select mode is on. That is the only
  // window in which the toggle (and its shortcut) is reachable, so
  // anything arriving outside it is the framework's own reset — storing
  // that would overwrite the preference with the default every time the
  // dev pressed the exit button.
  PersistentWidgetInspector.selectOnTapNotifier.addListener(() {
    if (!PersistentWidgetInspector.selectMode) return;
    DebugOverlayPrefs.setInspectorSelectOnTap(
      PersistentWidgetInspector.selectOnTap,
    );
  });
}

void _applyPersistedLoggerConfig() {
  final m = DebugOverlayPrefs.loggerConfig;
  if (m == null) return;
  Logger.configure(
    colors: m['colors'] as bool?,
    showSequence: m['showSequence'] as bool?,
    showDelta: m['showDelta'] as bool?,
    showSource: m['showSource'] as bool?,
    showBorders: m['showBorders'] as bool?,
    minLevel: switch (m['minLevel']) {
      final String name => LogLevel.values.asNameMap()[name],
      _ => null,
    },
    environment: m['environment'] as String?,
    lineLength: m['lineLength'] as int?,
  );
  final buffer = m['bufferSize'];
  if (buffer is int) LogBuffer.maxSize = buffer;
}
