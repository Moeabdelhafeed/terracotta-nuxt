import 'dart:io';

import 'package:flutter/foundation.dart';

import '../device_services.dart';

/// Memory usage queries (limited cross-platform support).
///
/// Note: Dart's [ProcessInfo] only reports the current process's RSS
/// (resident set size). System-wide memory queries require platform channels
/// or a dedicated package — not provided here.
class MemoryUtils {
  MemoryUtils._();

  /// Current process RSS (resident memory) in bytes.
  /// Returns 0 on web or if unavailable.
  static int getCurrentRssBytes() {
    try {
      if (kIsWeb) return 0;
      return ProcessInfo.currentRss;
    } catch (e, st) {
      deviceWarn('memory.currentRss', e, st);
      return 0;
    }
  }

  /// Current process RSS in megabytes.
  static double getCurrentRssMB() => getCurrentRssBytes() / (1024 * 1024);

  /// Maximum RSS the process has ever used, in bytes.
  static int getMaxRssBytes() {
    try {
      if (kIsWeb) return 0;
      return ProcessInfo.maxRss;
    } catch (e, st) {
      deviceWarn('memory.maxRss', e, st);
      return 0;
    }
  }

  /// Maximum RSS in megabytes.
  static double getMaxRssMB() => getMaxRssBytes() / (1024 * 1024);

  /// Both current and max RSS in MB.
  static ({double currentMB, double maxMB}) getInfo() {
    return (currentMB: getCurrentRssMB(), maxMB: getMaxRssMB());
  }
}
