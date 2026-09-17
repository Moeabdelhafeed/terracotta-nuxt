import '../../data/services/remote_config_service.dart';
import '../di/service_locator.dart';
import '../update_gate/update_cubit.dart';

/// Re-evaluate the update gate from the latest Remote Config snapshot.
/// Called once after `seedMaintenance...` during boot, and again on
/// every `RemoteConfigWatcher.updates` event so live RC changes
/// propagate without cold restart.
Future<void> seedUpdateFromRemoteConfig() async {
  if (!getIt.isRegistered<UpdateCubit>()) return;
  await getIt<UpdateCubit>().seedFromPackageInfo(
    minVersion: RemoteConfigService.minAppVersion,
    latestVersion: RemoteConfigService.latestAppVersion,
    storeUrl: RemoteConfigService.currentStoreUrl,
  );
}
