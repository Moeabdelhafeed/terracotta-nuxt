import 'package:flutter/foundation.dart';

/// Snapshot of maintenance configuration. Built from Remote Config
/// (planned downtime) or API 503 responses (incidents); the cubit
/// merges both sources.
@immutable
class MaintenanceConfig {
  const MaintenanceConfig({
    this.title = '',
    this.message = '',
    this.eta,
    this.supportUrl,
    this.allowList = const [],
  });

  /// Empty config — used as defaults / "not in maintenance" payload.
  static const MaintenanceConfig empty = MaintenanceConfig();

  final String title;
  final String message;

  /// Optional absolute timestamp when service is expected back. Used
  /// to render a countdown.
  final DateTime? eta;

  /// Optional support / status-page URL surfaced as an action button.
  final String? supportUrl;

  /// Routes that bypass the gate even when active. Sourced from RC
  /// (`maintenance_allow_list`). Same matcher as `RouteGuard`: exact
  /// path or `/*` prefix wildcard. Empty = block every route.
  final List<String> allowList;

  MaintenanceConfig copyWith({
    String? title,
    String? message,
    DateTime? eta,
    String? supportUrl,
    List<String>? allowList,
  }) {
    return MaintenanceConfig(
      title: title ?? this.title,
      message: message ?? this.message,
      eta: eta ?? this.eta,
      supportUrl: supportUrl ?? this.supportUrl,
      allowList: allowList ?? this.allowList,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'eta': eta?.toIso8601String(),
    'supportUrl': supportUrl,
    'allowList': allowList,
  };

  factory MaintenanceConfig.fromJson(Map<String, dynamic> json) {
    final etaRaw = json['eta'] as String?;
    final allowRaw = json['allowList'];
    return MaintenanceConfig(
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      eta: etaRaw != null ? DateTime.tryParse(etaRaw) : null,
      supportUrl: json['supportUrl'] as String?,
      allowList: allowRaw is List
          ? allowRaw.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceConfig &&
          other.title == title &&
          other.message == message &&
          other.eta == eta &&
          other.supportUrl == supportUrl &&
          listEquals(other.allowList, allowList);

  @override
  int get hashCode => Object.hash(
    title,
    message,
    eta,
    supportUrl,
    Object.hashAll(allowList),
  );
}
