import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'maintenance_config.dart';
import 'maintenance_state.dart';

/// Two-source maintenance gate.
///
/// Inputs:
/// - **Remote Config** flag for planned downtime — fed by bootstrap
///   after `RemoteConfigService.init()`.
/// - **API 503 / Retry-After** for unplanned incidents — fed by the
///   maintenance API interceptor.
///
/// State persists via `HydratedCubit` so the gate survives cold start
/// even when offline (avoids flashing the app shell during outages).
class MaintenanceCubit extends HydratedCubit<MaintenanceState> {
  MaintenanceCubit() : super(const MaintenanceState());

  /// Update the Remote Config side. Pass full config so the screen
  /// can render the latest title / message / ETA / supportUrl.
  void updateFromRemoteConfig({
    required bool active,
    MaintenanceConfig? config,
  }) {
    emit(
      state.copyWith(
        rcActive: active,
        config: config ?? state.config,
      ),
    );
  }

  /// Mark API 503 — interceptor calls this when a request returns
  /// 503 Service Unavailable. Optionally include `retryAfter` from
  /// the header to populate ETA.
  void markApiUnavailable({
    String? message,
    Duration? retryAfter,
  }) {
    emit(
      state.copyWith(
        apiActive: true,
        config: state.config.copyWith(
          message: message?.isNotEmpty ?? false
              ? message
              : state.config.message,
          eta: retryAfter != null
              ? DateTime.now().add(retryAfter)
              : state.config.eta,
        ),
      ),
    );
  }

  /// Clear the API-side flag. Called when retry succeeds.
  void clearApiUnavailable() {
    emit(state.copyWith(apiActive: false));
  }

  /// User-triggered retry. Resets API flag so the gate dismisses
  /// once the next request succeeds; RC flag is unaffected (only the
  /// next RC fetch can clear that).
  void retry() {
    clearApiUnavailable();
  }

  @override
  MaintenanceState? fromJson(Map<String, dynamic> json) {
    try {
      return MaintenanceState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(MaintenanceState state) => state.toJson();
}
