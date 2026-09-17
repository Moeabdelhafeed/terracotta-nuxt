import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/remote_config_watcher.dart';
import '../../shared/module/maintenance/maintenance_screen.dart';
import '../di/service_locator.dart';
import '../navigation/go_router_config.dart';
import 'maintenance_cubit.dart';
import 'maintenance_state.dart';

/// Wraps the app and shows [MaintenanceScreen] whenever
/// [MaintenanceCubit] reports an active outage from any source
/// (Remote Config flag or API 503 interceptor).
///
/// The allow-list of bypass routes lives in [MaintenanceConfig.allowList],
/// driven by Remote Config key `maintenance_allow_list` (JSON string
/// array). Path patterns follow the same matcher as `RouteGuard`:
/// exact path or `/*` prefix wildcard. Empty list = block all routes.
///
/// Mount once near the root inside `MaterialApp.builder`, around the
/// existing `BuildLockGuard`. Falls through to [child] when no
/// outage is active OR the current route is allow-listed.
class MaintenanceGate extends StatelessWidget {
  const MaintenanceGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintenanceCubit, MaintenanceState>(
      builder: (context, state) {
        if (!state.isActive) return child;
        final allowList = state.config.allowList;
        if (allowList.isEmpty) return _screen(context, state);
        // Re-evaluate whenever GoRouter's current location changes.
        return AnimatedBuilder(
          animation: GoRouterConfig.router.routeInformationProvider,
          builder: (context, _) {
            final path =
                GoRouterConfig.router.routeInformationProvider.value.uri.path;
            if (_matchesAllow(path, allowList)) return child;
            return _screen(context, state);
          },
        );
      },
    );
  }

  Widget _screen(BuildContext context, MaintenanceState state) {
    return MaintenanceScreen(
      config: state.config,
      onRetry: () {
        // Clear API-side flag (the next 2xx confirms recovery), then
        // pull the latest RC values so a freshly-cleared
        // `maintenance_mode` flag reflects in the UI. Watcher's
        // updates stream re-fires the maintenance reseed.
        context.read<MaintenanceCubit>().retry();
        getIt<RemoteConfigWatcher>().refresh();
      },
    );
  }

  static bool _matchesAllow(String path, List<String> patterns) {
    for (final p in patterns) {
      if (_matchesPattern(path, p)) return true;
    }
    return false;
  }

  static bool _matchesPattern(String path, String pattern) {
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return path == prefix || path.startsWith('$prefix/');
    }
    return path == pattern;
  }
}
