import '../../data/services/remote_config_service.dart';
import '../connectivity/connectivity_config.dart';
import '../connectivity/connectivity_cubit.dart';
import '../di/service_locator.dart';

/// Build a [ConnectivityConfig] snapshot from the current Remote
/// Config values. Pure read — call after `RemoteConfigService.init`.
ConnectivityConfig _configFromRc() {
  return ConnectivityConfig(
    probeUrl: RemoteConfigService.connectivityProbeUrl,
    probeIntervalForeground: Duration(
      seconds: RemoteConfigService.connectivityProbeIntervalSeconds,
    ),
    maxProbeFailures: RemoteConfigService.connectivityMaxProbeFailures,
    vpnPolicy: VpnPolicy.fromString(
      RemoteConfigService.connectivityVpnPolicy,
    ),
  );
}

/// Push the latest RC-derived config into the running cubit. Used
/// both during boot (after `seedMaintenance...`) and as a subscriber
/// to the RemoteConfigWatcher.updates stream.
void seedConnectivityFromRemoteConfig() {
  if (!getIt.isRegistered<ConnectivityCubit>()) return;
  getIt<ConnectivityCubit>().updateConfig(_configFromRc());
}
