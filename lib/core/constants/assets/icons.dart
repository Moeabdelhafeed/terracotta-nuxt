part of 'assets.dart';

class _Icons {
  const _Icons();

  AssetRef get airplane => const AssetRef('assets/icons/airplane.png');
  AssetRef get bag => const AssetRef('assets/icons/bag.png');
  AssetRef get google => const AssetRef('assets/icons/ri_google-fill.png');
  AssetRef get apple => const AssetRef('assets/icons/ic_baseline-apple.png');
  AssetRef get home => const AssetRef('assets/icons/home.png');
  AssetRef get requests => const AssetRef('assets/icons/solid-plane.png');
  AssetRef get wallet => const AssetRef('assets/icons/wallet.png');
  AssetRef get profile => const AssetRef('assets/icons/profile-fill.png');
  AssetRef get notification => const AssetRef('assets/icons/notification.png');

  /// The bell the DESIGN uses — a filled mingcute glyph, exported as
  /// SVG so it stays crisp at any size. Distinct from [notification],
  /// which is the template's PNG placeholder.
  AssetRef get notificationBell =>
      const AssetRef('assets/icons/mingcute_notification_fill.svg');

  /// The cart, as the nav bar and the home shortcuts already draw it.
  AssetRef get cart => const AssetRef('assets/icons/boxicons_cart_filled.svg');

  /// The design's own stepper glyphs.
  AssetRef get plus => const AssetRef('assets/icons/ic_round_plus.svg');
  AssetRef get minus => const AssetRef('assets/icons/ic_round_minus.svg');

  /// The scan glyph on a booking's «رمز المسح» chip — the design's own
  /// boxicons mark, not Material's `qr_code_2`, which draws a plain
  /// three-corner square with none of the scatter.
  AssetRef get qrScan => const AssetRef('assets/icons/boxicons_qr_filled.svg');

  /// The gift glyph on the workshops tab's «اهداء» tile.
  AssetRef get gift => const AssetRef('assets/icons/famicons_gift.svg');

  AssetRef get arrowUp => const AssetRef('assets/icons/eva_arrow-up-fill.png');
  AssetRef get arrowDown =>
      const AssetRef('assets/icons/eva_arrow-down-fill.png');
  AssetRef get replay =>
      const AssetRef('assets/icons/material-symbols_replay-rounded.png');
}
