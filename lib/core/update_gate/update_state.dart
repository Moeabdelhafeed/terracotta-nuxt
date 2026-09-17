import 'package:flutter/foundation.dart';

/// What the gate decided about the running version.
enum UpdateRequirement {
  /// Cubit just started; RC not yet seeded. Gate stays hidden.
  unknown,

  /// `current >= latest` (or `latest` empty) — nothing to do.
  upToDate,

  /// `min ≤ current < latest` — soft prompt may surface depending
  /// on [UpdateOptions.softMode] + dismissal state.
  available,

  /// `current < min` — hard fullscreen block.
  required,
}

@immutable
class UpdateState {
  const UpdateState({
    this.requirement = UpdateRequirement.unknown,
    this.currentVersion = '',
    this.minVersion = '',
    this.latestVersion = '',
    this.storeUrl = '',
    this.skippedVersions = const <String>{},
    this.remindLaterUntil,
    this.lastEvaluatedAt,
  });

  final UpdateRequirement requirement;

  final String currentVersion;
  final String minVersion;
  final String latestVersion;
  final String storeUrl;

  /// Versions the user explicitly skipped on the soft prompt. Soft
  /// surface is suppressed when `skippedVersions.contains(latestVersion)`.
  final Set<String> skippedVersions;

  /// "Remind me later" cooldown — soft prompt suppressed until this
  /// timestamp. Null = no active cooldown.
  final DateTime? remindLaterUntil;

  /// Wall-clock when the gate last evaluated. Used by the boot grace
  /// period and the showcase live state panel.
  final DateTime? lastEvaluatedAt;

  bool get isHardRequired => requirement == UpdateRequirement.required;
  bool get isSoftAvailable => requirement == UpdateRequirement.available;

  /// True when the soft prompt should hide because the user already
  /// dismissed this version or the cooldown is still active.
  bool get isSoftSuppressed {
    if (skippedVersions.contains(latestVersion)) return true;
    final until = remindLaterUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  UpdateState copyWith({
    UpdateRequirement? requirement,
    String? currentVersion,
    String? minVersion,
    String? latestVersion,
    String? storeUrl,
    Set<String>? skippedVersions,
    DateTime? remindLaterUntil,
    bool clearRemindLater = false,
    DateTime? lastEvaluatedAt,
  }) {
    return UpdateState(
      requirement: requirement ?? this.requirement,
      currentVersion: currentVersion ?? this.currentVersion,
      minVersion: minVersion ?? this.minVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      storeUrl: storeUrl ?? this.storeUrl,
      skippedVersions: skippedVersions ?? this.skippedVersions,
      remindLaterUntil: clearRemindLater
          ? null
          : (remindLaterUntil ?? this.remindLaterUntil),
      lastEvaluatedAt: lastEvaluatedAt ?? this.lastEvaluatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'skippedVersions': skippedVersions.toList(),
    'remindLaterUntil': remindLaterUntil?.toIso8601String(),
  };

  factory UpdateState.fromJson(Map<String, dynamic> json) {
    final raw = json['remindLaterUntil'] as String?;
    return UpdateState(
      skippedVersions: ((json['skippedVersions'] as List?) ?? const [])
          .whereType<String>()
          .toSet(),
      remindLaterUntil: raw != null ? DateTime.tryParse(raw) : null,
    );
  }
}
