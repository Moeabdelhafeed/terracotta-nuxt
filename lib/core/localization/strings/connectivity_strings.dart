import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `connectivity_` key prefix family — connectivity
/// banner labels.
class ConnectivityStrings {
  ConnectivityStrings._();

  static String get offline =>
      Tr.t('connectivity.offline', S.current.connectivity_offline);

  static String offlineQueued(int count) => Tr.t(
    'connectivity.offline_queued',
    S.current.connectivity_offline_queued(count),
  );

  static String get backOnline =>
      Tr.t('connectivity.back_online', S.current.connectivity_back_online);

  static String get vpnWarning =>
      Tr.t('connectivity.vpn_warning', S.current.connectivity_vpn_warning);

  static String get vpnBlocked =>
      Tr.t('connectivity.vpn_blocked', S.current.connectivity_vpn_blocked);

  // ─── Network quality ──────────────────────────────────────
  //
  // `NetworkQuality.label` and `getConnectionType()` used to answer
  // with hard-coded English — 'Excellent', 'wifi' — from inside
  // `core/utils/device/`, which put display copy in a service layer
  // and put it in one language.

  static String get qualityOffline => Tr.t(
    'connectivity.quality_offline',
    S.current.connectivity_quality_offline,
  );

  static String get qualityPoor =>
      Tr.t('connectivity.quality_poor', S.current.connectivity_quality_poor);

  static String get qualityFair =>
      Tr.t('connectivity.quality_fair', S.current.connectivity_quality_fair);

  static String get qualityGood =>
      Tr.t('connectivity.quality_good', S.current.connectivity_quality_good);

  static String get qualityExcellent => Tr.t(
    'connectivity.quality_excellent',
    S.current.connectivity_quality_excellent,
  );

  static String get qualityUnknown => Tr.t(
    'connectivity.quality_unknown',
    S.current.connectivity_quality_unknown,
  );

  static String get typeOffline =>
      Tr.t('connectivity.type_offline', S.current.connectivity_type_offline);

  static String get typeWifi =>
      Tr.t('connectivity.type_wifi', S.current.connectivity_type_wifi);

  static String get typeEthernet =>
      Tr.t('connectivity.type_ethernet', S.current.connectivity_type_ethernet);

  static String get typeMobile =>
      Tr.t('connectivity.type_mobile', S.current.connectivity_type_mobile);

  static String get typeVpn =>
      Tr.t('connectivity.type_vpn', S.current.connectivity_type_vpn);

  static String get typeOther =>
      Tr.t('connectivity.type_other', S.current.connectivity_type_other);
}
