import '../../data/services/remote_config_service.dart';
import '../di/service_locator.dart';
import '../maintenance/maintenance_config.dart';
import '../maintenance/maintenance_cubit.dart';

/// Seed [MaintenanceCubit] from [RemoteConfigService] using whatever
/// values are currently active (no network fetch).
///
/// Must run AFTER both `initFirebase` (RC values fetched) and
/// `initDi` (cubit registered). Safe to call repeatedly; later
/// invocations refresh the snapshot.
///
/// In bootstrap, also subscribed to `RemoteConfigWatcher.updates` so
/// every live RC activate auto-reseeds the cubit.
void seedMaintenanceFromRemoteConfig() {
  if (!getIt.isRegistered<MaintenanceCubit>()) return;
  final cubit = getIt<MaintenanceCubit>();
  cubit.updateFromRemoteConfig(
    active: RemoteConfigService.maintenanceMode,
    config: MaintenanceConfig(
      title: RemoteConfigService.maintenanceTitle,
      message: RemoteConfigService.maintenanceMessage,
      eta: RemoteConfigService.maintenanceEta,
      supportUrl: RemoteConfigService.maintenanceSupportUrl.isEmpty
          ? null
          : RemoteConfigService.maintenanceSupportUrl,
      allowList: RemoteConfigService.maintenanceAllowList,
    ),
  );
}
