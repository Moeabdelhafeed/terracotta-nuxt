import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/blocs/preferences/preferences_cubit.dart';
import '../connectivity/connectivity_cubit.dart';
import '../di/service_locator.dart';
import '../flavor/flavor_config.dart';
import '../utils/loggers/log_buffer.dart';
import '../utils/loggers/logger.dart';

/// Builds the diagnostics map auto-attached to a feedback submission.
/// All fields are best-effort — a single fail bubbles to a debug log
/// and the rest of the snapshot continues collecting.
class FeedbackDiagnostics {
  const FeedbackDiagnostics._();

  static Future<Map<String, dynamic>> collect({
    BuildContext? context,
    bool includeLogs = true,
    int logTailLines = 40,
  }) async {
    final out = <String, dynamic>{};

    // App ----------------------------------------------------
    try {
      final info = await PackageInfo.fromPlatform();
      out['app'] = {
        'name': info.appName,
        'version': info.version,
        'build': info.buildNumber,
        'package': info.packageName,
      };
    } catch (e) {
      Logger.m.d('[Feedback] PackageInfo failed: $e');
    }

    // Platform / device --------------------------------------
    out['platform'] = defaultTargetPlatform.name;
    if (kIsWeb) {
      out['runtime'] = 'web';
    } else {
      try {
        final plugin = DeviceInfoPlugin();
        if (defaultTargetPlatform == TargetPlatform.android) {
          final d = await plugin.androidInfo;
          out['device'] = {
            'manufacturer': d.manufacturer,
            'model': d.model,
            'androidVersion': d.version.release,
            'sdkInt': d.version.sdkInt,
          };
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final d = await plugin.iosInfo;
          out['device'] = {
            'model': d.model,
            'name': d.name,
            'systemName': d.systemName,
            'systemVersion': d.systemVersion,
          };
        }
      } catch (e) {
        Logger.m.d('[Feedback] DeviceInfo failed: $e');
      }
    }

    // Flavor -------------------------------------------------
    try {
      out['flavor'] = FlavorConfig.instance.flavor.name;
    } catch (_) {
      // FlavorConfig not initialised — skip.
    }

    // Preferences --------------------------------------------
    if (getIt.isRegistered<PreferencesCubit>()) {
      final prefs = getIt<PreferencesCubit>().state;
      out['prefs'] = {
        'language': prefs.language.locale,
        'themeMode': prefs.themeMode.name,
        'fontScale': prefs.fontScale,
        'dynamicColor': prefs.dynamicColor,
      };
    }

    // Connectivity -------------------------------------------
    if (getIt.isRegistered<ConnectivityCubit>()) {
      final c = getIt<ConnectivityCubit>().state;
      out['connectivity'] = {
        'verdict': c.verdict.name,
        'source': c.source.name,
        'vpn': c.vpnDetected,
        'queued': c.queuedActions,
      };
    }

    // Route --------------------------------------------------
    if (context != null && context.mounted) {
      try {
        out['route'] = ModalRoute.of(context)?.settings.name ?? '<unknown>';
      } catch (_) {}
    }

    // Logs ---------------------------------------------------
    if (includeLogs) {
      final lines = LogBuffer.recent(
        count: logTailLines,
      ).reversed.map((e) => e.toPlain()).toList();
      if (lines.isNotEmpty) out['logs'] = lines;
    }

    out['collectedAt'] = DateTime.now().toIso8601String();
    return out;
  }
}
