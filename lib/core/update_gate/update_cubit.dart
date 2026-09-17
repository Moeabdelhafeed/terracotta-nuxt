import 'package:flutter/widgets.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/loggers/logger.dart';
import 'semver.dart';
import 'update_options.dart';
import 'update_state.dart';

/// Owns the version-comparison verdict + dismissal persistence.
///
/// Dismissal state (skipped versions, remind-later cooldown) is
/// persisted via `HydratedCubit` so users aren't re-nagged on every
/// cold start.
///
/// Version evaluation is *not* persisted — `currentVersion`,
/// `minVersion`, `latestVersion`, and `storeUrl` are re-seeded from
/// `RemoteConfigService` + `PackageInfo` on every boot via
/// [seedFromSources].
class UpdateCubit extends HydratedCubit<UpdateState> {
  UpdateCubit({UpdateOptions options = const UpdateOptions()})
    : _options = options,
      super(const UpdateState());

  UpdateOptions _options;
  UpdateOptions get options => _options;

  bool _withinBootGrace = true;
  bool get withinBootGrace => _withinBootGrace;

  void updateOptions(UpdateOptions next) {
    _options = next;
  }

  /// Re-evaluate the gate with fresh inputs. Bootstrap calls this
  /// after RC seed; the watcher subscription calls it again whenever
  /// RC publishes new values.
  Future<void> seedFromSources({
    required String currentVersion,
    required String minVersion,
    required String latestVersion,
    required String storeUrl,
  }) async {
    if (!_options.enabled) {
      emit(
        state.copyWith(
          requirement: UpdateRequirement.upToDate,
          currentVersion: currentVersion,
          minVersion: minVersion,
          latestVersion: latestVersion,
          storeUrl: storeUrl,
          lastEvaluatedAt: DateTime.now(),
        ),
      );
      return;
    }
    final verdict = _evaluate(
      current: currentVersion,
      min: minVersion,
      latest: latestVersion,
    );
    final changed =
        verdict != state.requirement ||
        currentVersion != state.currentVersion ||
        minVersion != state.minVersion ||
        latestVersion != state.latestVersion;
    emit(
      state.copyWith(
        requirement: verdict,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,
        storeUrl: storeUrl,
        lastEvaluatedAt: DateTime.now(),
      ),
    );
    // Log only on actual change — periodic re-seeds during web poll
    // / resume hit this code path with identical inputs.
    if (changed) {
      Logger.m.d(
        '[Update] verdict=$verdict current=$currentVersion '
        'min=$minVersion latest=$latestVersion',
      );
    }

    if (_withinBootGrace) {
      Future.delayed(_options.bootGracePeriod, () {
        if (isClosed) return;
        _withinBootGrace = false;
        // Re-emit to wake any builders gated on the grace flag.
        emit(state.copyWith());
      });
    }
  }

  /// Convenience that pulls current version from `package_info_plus`
  /// and delegates to [seedFromSources]. Most callers use this.
  Future<void> seedFromPackageInfo({
    required String minVersion,
    required String latestVersion,
    required String storeUrl,
  }) async {
    final info = await PackageInfo.fromPlatform();
    final current = info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
    await seedFromSources(
      currentVersion: current,
      minVersion: minVersion,
      latestVersion: latestVersion,
      storeUrl: storeUrl,
    );
  }

  UpdateRequirement _evaluate({
    required String current,
    required String min,
    required String latest,
  }) {
    // No min set on this platform = gate disabled.
    if (min.trim().isEmpty && latest.trim().isEmpty) {
      return UpdateRequirement.upToDate;
    }
    if (min.trim().isNotEmpty && Semver.lessThan(current, min)) {
      return UpdateRequirement.required;
    }
    if (latest.trim().isNotEmpty && Semver.lessThan(current, latest)) {
      return UpdateRequirement.available;
    }
    return UpdateRequirement.upToDate;
  }

  /// "Skip this version" — store the latest version so the soft
  /// prompt stays hidden until a newer version is published.
  void skipCurrentLatest() {
    final v = state.latestVersion;
    if (v.isEmpty) return;
    emit(
      state.copyWith(
        skippedVersions: {...state.skippedVersions, v},
      ),
    );
  }

  /// "Maybe later" — suppress the soft prompt for the configured
  /// cooldown duration.
  void remindLater() {
    emit(
      state.copyWith(
        remindLaterUntil: DateTime.now().add(_options.remindLaterCooldown),
      ),
    );
  }

  /// Wipe dismissal state. Used by logout flows or by the showcase
  /// "reset" button.
  void clearDismissals() {
    emit(
      state.copyWith(
        skippedVersions: const <String>{},
        clearRemindLater: true,
      ),
    );
  }

  /// Trigger the store-open flow. Honors [UpdateOptions.openStore]
  /// when set, otherwise falls back to `url_launcher` on
  /// [UpdateState.storeUrl].
  Future<void> openStore(BuildContext context) async {
    final url = state.storeUrl;
    final override = _options.openStore;
    if (override != null) {
      await override(context, url);
      return;
    }
    if (url.isEmpty) {
      Logger.m.w('[Update] store URL empty; nothing to open');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      Logger.m.w('[Update] unparseable store URL: $url');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Logger.m.w('[Update] cannot launch store URL: $url');
    }
  }

  // ─── Hydration ────────────────────────────────────────────

  @override
  UpdateState? fromJson(Map<String, dynamic> json) {
    try {
      return UpdateState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(UpdateState state) => state.toJson();
}
