import '../../../core/di/service_locator.dart';
import '../../../data/services/app_config_service.dart';
import '../../../data/services/gift_package_service.dart';

/// Whether the studio is selling gift credit at all.
///
/// One answer, read from three places — the tile beside the wallet on
/// the shop and workshops pages, and the row in the profile. `false`
/// takes the whole surface away rather than leaving a control that
/// opens a sheet saying no.
///
/// ## The switch is `is_active`, and it is NOT on `/api/config`
///
/// `GET /api/gifts/package` answers `{amount, is_active}` and
/// `is_active` is the studio's own on/off — verified live 2026-09-16,
/// where it currently reads **false**. `/api/config` carries no gift
/// flag of any kind; `AppConfig.allowGift` is modelled for one that
/// may arrive and is true while absent, so it costs nothing and can
/// only ever turn gifting OFF.
///
/// ## It answers TRUE when it cannot tell
///
/// Three ways that happens — the package request has not landed, the
/// config has no flag, or nothing is registered (which is every widget
/// test that pumps one of these screens with only the cubit it is
/// about). A missing answer must not hide a live feature.
bool giftsAllowed() {
  final config = getIt.isRegistered<AppConfigService>()
      ? getIt<AppConfigService>().allowsGift
      : true;
  final package = getIt.isRegistered<GiftPackageService>()
      ? getIt<GiftPackageService>().isActive
      : true;

  return config && package;
}

/// The face value of one gift, as a decimal STRING — `"200.00"`.
///
/// Empty until `GET /api/gifts/package` answers. The amount is the
/// studio's, not the customer's, so the sheet STATES it; nothing
/// fetched it before, which is why the card had a blank where the
/// figure belongs.
String giftAmount() => getIt.isRegistered<GiftPackageService>()
    ? getIt<GiftPackageService>().amount
    : '';

/// Ask for the package if this run has not got it yet.
///
/// The boot call 422s on an empty `X-FCM-Token` whenever the radio is
/// cold — see `GiftPackageService` — so the sheet asks again on the
/// way in rather than showing a blank where the figure belongs.
/// Answers whether the amount changed, so the caller knows to rebuild.
Future<bool> ensureGiftPackage() async {
  if (!getIt.isRegistered<GiftPackageService>()) return false;

  final service = getIt<GiftPackageService>();
  final before = service.amount;
  await service.ensureLoaded();
  return service.amount != before;
}
