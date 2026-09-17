import 'package:flutter/foundation.dart';

/// Outcome of a single replay attempt.
enum ReplayResult {
  /// Action succeeded — drop from the queue.
  success,

  /// Transient failure (server unreachable, 5xx, timeout) — keep in
  /// queue, will retry next reconnect / next manual flush.
  retry,

  /// Permanent failure (validation, conflict, deleted resource) —
  /// drop from the queue, surface to caller via [OfflineAction.onDrop].
  drop,
}

/// A user mutation that the app wants to replay when connectivity
/// returns. Created by feature code, handed to [OfflineActionQueue].
@immutable
class OfflineAction {
  const OfflineAction({
    required this.id,
    required this.kind,
    required this.payload,
    this.label,
    this.attempts = 0,
    this.maxAttempts = 5,
    this.createdAt,
  });

  /// Unique id (uuid / nano-id) — used for de-dupe and persistence.
  final String id;

  /// Bucket key dispatching to a registered replayer. Common values:
  /// `'http.post'`, `'http.put'`, `'analytics.event'`. Any string the
  /// caller agrees on with [OfflineActionQueue.registerReplayer].
  final String kind;

  /// JSON-serializable payload for the replayer to consume. Must round-trip
  /// through `jsonEncode` / `jsonDecode` cleanly — no closures, no objects.
  final Map<String, dynamic> payload;

  /// User-facing description ("Send message", "Update profile"). Surfaced
  /// in the banner / debug screens.
  final String? label;

  final int attempts;
  final int maxAttempts;
  final DateTime? createdAt;

  OfflineAction copyWith({
    int? attempts,
    int? maxAttempts,
  }) {
    return OfflineAction(
      id: id,
      kind: kind,
      payload: payload,
      label: label,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'payload': payload,
    'label': label,
    'attempts': attempts,
    'maxAttempts': maxAttempts,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'] as String?;
    return OfflineAction(
      id: json['id'] as String,
      kind: json['kind'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      label: json['label'] as String?,
      attempts: (json['attempts'] as int?) ?? 0,
      maxAttempts: (json['maxAttempts'] as int?) ?? 5,
      createdAt: created != null ? DateTime.tryParse(created) : null,
    );
  }
}

/// Replayer signature — looks up the action's registered handler, runs
/// it, returns a [ReplayResult]. Handlers are registered once during
/// boot (e.g. `'http.post'` → wrap your Dio post call).
typedef OfflineActionReplayer =
    Future<ReplayResult> Function(
      OfflineAction action,
    );
