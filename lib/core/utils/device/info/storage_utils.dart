import 'package:disk_space_plus/disk_space_plus.dart';

import '../device_services.dart';

/// Disk space.
///
/// Every reading is NULLABLE, where these used to answer `0.0` on
/// failure. Zero free megabytes is a full disk — a real state, and one
/// an app is supposed to react to — so a failed query answering zero
/// meant "the disk is full" to every caller that believed it.
class StorageUtils {
  StorageUtils._();

  static final DiskSpacePlus _diskSpace = DiskSpacePlus();

  static DeviceCapability get _cap => DeviceServices.capability('diskSpace');

  /// Free disk space in megabytes, or null if it cannot be read.
  static Future<double?> getFreeSpaceMB() => _cap.guard(() async {
    final kb = await _diskSpace.getFreeDiskSpace;
    return kb == null ? null : kb / 1024;
  }, fallback: null);

  /// Total disk space in megabytes, or null if it cannot be read.
  static Future<double?> getTotalSpaceMB() => _cap.guard(() async {
    final kb = await _diskSpace.getTotalDiskSpace;
    return kb == null ? null : kb / 1024;
  }, fallback: null);

  /// Both figures. Either may be null.
  static Future<({double? freeMB, double? totalMB})> getInfo() async {
    final free = await getFreeSpaceMB();
    final total = await getTotalSpaceMB();
    return (freeMB: free, totalMB: total);
  }

  /// Fraction of storage in use (0.0 - 1.0), or null when either
  /// figure is missing — or when the total is zero, which is not a
  /// disk that is 0% used but a disk that was not measured.
  static Future<double?> getUsedPercentage() async {
    final info = await getInfo();
    final total = info.totalMB;
    final free = info.freeMB;
    if (total == null || free == null || total <= 0) return null;
    return (total - free) / total;
  }
}
