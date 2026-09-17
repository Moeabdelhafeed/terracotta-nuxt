import 'package:nfc_manager/nfc_manager.dart';

import '../device_services.dart';

/// NFC tag reading.
///
/// Requires the NFC entitlement on iOS and the `NFC` permission in
/// `AndroidManifest.xml`.
///
/// ```dart
/// NfcUtils.startReading(onTag: (tag) => Logger.m.i(NfcUtils.getTagId(tag)));
/// NfcUtils.stopReading();
/// ```
class NfcUtils {
  NfcUtils._();

  static DeviceCapability get _cap => DeviceServices.capability('nfc');

  /// True if the device has NFC hardware AND it is switched on.
  ///
  /// NOT latched on a `false` answer, unlike the torch: NFC is a
  /// radio the reader can turn off and on in system settings while
  /// the app is open, so a "no" here is about right now.
  static Future<bool> isAvailable() => _cap.guard(() async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
  }, fallback: false);

  /// Start scanning. [onTag] fires for each tag detected.
  static Future<bool> startReading({
    required void Function(NfcTag tag) onTag,
  }) => deviceGuard('nfc.startReading', () async {
    await NfcManager.instance.startSession(
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
      onDiscovered: (tag) async => onTag(tag),
    );
    return true;
  }, fallback: false);

  static Future<bool> stopReading() => deviceGuard(
    'nfc.stopReading',
    () async {
      await NfcManager.instance.stopSession();
      return true;
    },
    fallback: false,
  );
}
