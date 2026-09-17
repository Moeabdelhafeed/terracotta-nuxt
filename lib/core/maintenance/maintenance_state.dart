import 'package:flutter/foundation.dart';

import 'maintenance_config.dart';

/// Cubit state.
///
/// `rcActive` and `apiActive` are independent boolean inputs from
/// Remote Config and API 503 interceptors. The OR-merge keeps the
/// gate up while either source still reports an outage.
@immutable
class MaintenanceState {
  const MaintenanceState({
    this.rcActive = false,
    this.apiActive = false,
    this.config = MaintenanceConfig.empty,
  });

  final bool rcActive;
  final bool apiActive;
  final MaintenanceConfig config;

  /// Effective gate state — any source true means show maintenance.
  bool get isActive => rcActive || apiActive;

  MaintenanceState copyWith({
    bool? rcActive,
    bool? apiActive,
    MaintenanceConfig? config,
  }) {
    return MaintenanceState(
      rcActive: rcActive ?? this.rcActive,
      apiActive: apiActive ?? this.apiActive,
      config: config ?? this.config,
    );
  }

  Map<String, dynamic> toJson() => {
    'rcActive': rcActive,
    'apiActive': apiActive,
    'config': config.toJson(),
  };

  factory MaintenanceState.fromJson(Map<String, dynamic> json) {
    return MaintenanceState(
      rcActive: (json['rcActive'] as bool?) ?? false,
      apiActive: (json['apiActive'] as bool?) ?? false,
      config: MaintenanceConfig.fromJson(
        (json['config'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceState &&
          other.rcActive == rcActive &&
          other.apiActive == apiActive &&
          other.config == config;

  @override
  int get hashCode => Object.hash(rcActive, apiActive, config);
}
