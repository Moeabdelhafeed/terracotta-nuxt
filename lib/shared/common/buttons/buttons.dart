/// Barrel for all pre-built button components. Import from here when
/// a screen needs several button types — saves per-widget imports.
///
/// ```dart
/// import 'package:terracotta/shared/buttons/buttons.dart';
/// ```
///
/// Organized by the underlying `Global*Button` primitive each one
/// wraps: `elevated/`, `outlined/`, `text/`, `icon/`.
///
/// ## Canonical icon-button contract
///
/// Every widget under `icon/` exposes the same standard surface in
/// addition to its domain fields — keeps the catalog consistent and
/// callers predictable:
///
/// | prop        | type                  | default |
/// |-------------|-----------------------|---------|
/// | `onPressed` | `VoidCallback?`       | — (or domain-specific default) |
/// | `iconSize`  | `double?`             | per-button default |
/// | `color`     | `Color?`              | theme |
/// | `tooltip`   | `String?`             | none |
/// | `enabled`   | `bool`                | `true` |
/// | `style`     | `ButtonStateStyle?`   | merges over defaults (escape hatch) |
///
/// Domain fields (`isFavorite`, `isHidden`, `value`, …) come on top.
/// The `style` escape hatch lets callers override anything the preset
/// locks in (width, elevation, gradient) without the button needing
/// to expose a flag for each.
library;

// ─── Actions (one class per action, `variant:` picks the look) ──
export 'actions/action_button_base.dart';
export 'actions/add_button.dart';
export 'actions/cancel_button.dart';
export 'actions/clear_button.dart';
export 'actions/close_action_button.dart';
export 'actions/confirm_button.dart';
export 'actions/copy_button.dart';
export 'actions/delete_button.dart';
export 'actions/edit_button.dart';
export 'actions/logout_button.dart';
export 'actions/refresh_button.dart';
export 'actions/retry_button.dart';
export 'actions/save_button.dart';
export 'actions/search_button.dart';
export 'actions/send_button.dart';
export 'actions/share_button.dart';

// ─── Elevated ────────────────────────────────────────────────────
export 'elevated/gradient_elevated_button.dart';
export 'elevated/social_sign_in_button.dart';
export 'elevated/success_elevated_button.dart';
export 'elevated/warning_elevated_button.dart';
// ─── Icon ────────────────────────────────────────────────────────
export 'icon/back_icon_button.dart';
export 'icon/copy_icon_button.dart';
export 'icon/favorite_icon_button.dart';
export 'icon/filter_icon_button.dart';
export 'icon/info_icon_button.dart';
export 'icon/menu_icon_button.dart';
export 'icon/mic_icon_button.dart';
export 'icon/more_icon_button.dart';
export 'icon/my_location_icon_button.dart';
export 'icon/notification_icon_button.dart';
export 'icon/offer_view_icon_button.dart';
export 'icon/toggle_visibility_icon_button.dart';
export 'icon/user_direction_icon_button.dart';
export 'icon/zoom_in_icon_button.dart';
export 'icon/zoom_out_icon_button.dart';
// ─── Outlined ────────────────────────────────────────────────────
export 'outlined/dashed_outlined_button.dart';
export 'outlined/selectable_chip_button.dart';
export 'outlined/success_outlined_button.dart';
// ─── Text ────────────────────────────────────────────────────────
export 'text/link_text_button.dart';
export 'text/read_more_text_button.dart';
export 'text/skip_text_button.dart';
export 'text/trailing_icon_text_button.dart';
