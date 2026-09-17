import 'package:battery_plus/battery_plus.dart';

import '../_ttl_cache.dart';
import '../device_services.dart';

/// Battery level and charge state.
///
/// **A simulator has no battery API.** Every call used to ask anyway
/// and print the same `PlatformException` — the level probe latched
/// after the first failure, the state probe never did.
class BatteryUtils {
  BatteryUtils._();

  static final Battery _battery = Battery();
  static final TtlCache<int?> _levelCache = TtlCache<int?>(
    () => DeviceServices.policy.valueTtl,
  );

  static DeviceCapability get _cap => DeviceServices.capability('battery');

  /// False once the platform has told us there is no battery API.
  static bool get isAvailable => _cap.isKnownAvailable;

  /// Battery percentage (0-100), or null where there is no battery
  /// API. Cached for [DevicePolicy.valueTtl].
  static Future<int?> getLevel({bool forceRefresh = false}) => _cap.guard(
    () => _levelCache.get(
      () async => _battery.batteryLevel,
      forceRefresh: forceRefresh,
    ),
    fallback: null,
  );

  /// Last known level without triggering a fetch.
  static int? get cachedLevel => _levelCache.peek;

  static void invalidateCache() => _levelCache.invalidate();

  /// Charging / discharging / full. [BatteryState.unknown] where
  /// there is no battery API.
  static Future<BatteryState> getState() => _cap.guard(
    () => _battery.batteryState,
    fallback: BatteryState.unknown,
  );

  static Future<bool> isCharging() async =>
      await getState() == BatteryState.charging;

  static Future<bool> isFull() async => await getState() == BatteryState.full;

  static Future<bool> isDischarging() async =>
      await getState() == BatteryState.discharging;

  static Future<bool> isConnectedNotCharging() async =>
      await getState() == BatteryState.connectedNotCharging;

  /// True when the level is under [DevicePolicy.batteryLowThreshold].
  /// False when there is no battery to be low — a device on mains
  /// power is not in a low-power situation.
  static Future<bool> isLow({bool forceRefresh = false}) async {
    final level = await getLevel(forceRefresh: forceRefresh);
    if (level == null) return false;
    return level < DeviceServices.policy.batteryLowThreshold;
  }

  static Future<bool> isInBatterySaveMode() =>
      _cap.guard(() => _battery.isInBatterySaveMode, fallback: false);

  /// Stream of charge-state changes. Empty where there is no battery
  /// API — the plugin's stream throws on subscribe there, and a
  /// listener wired at app start should not take the app down.
  static Stream<BatteryState> get onStateChanged => _battery
      .onBatteryStateChanged
      .handleError((Object e) => _cap.markUnavailable(e));
}
