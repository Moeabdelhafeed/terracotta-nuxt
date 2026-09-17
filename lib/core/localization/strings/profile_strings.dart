import '../../../data/models/terracotta/account/notification_filter.dart';
import '../../../generated/l10n.dart';
import '../tr.dart';

/// The account area. Not drawn in the design; built from the existing component vocabulary.
class ProfileStrings {
  ProfileStrings._();

  static String get title => Tr.t('profile_title', S.current.profile_title);

  static String get edit => Tr.t('profile_edit', S.current.profile_edit);

  static String get addresses =>
      Tr.t('profile_addresses', S.current.profile_addresses);

  static String get wallet => Tr.t('profile_wallet', S.current.profile_wallet);

  static String get notifications =>
      Tr.t('profile_notifications', S.current.profile_notifications);

  static String get orders => Tr.t('profile_orders', S.current.profile_orders);

  static String get devices =>
      Tr.t('profile_devices', S.current.profile_devices);

  static String get changePassword =>
      Tr.t('profile_change_password', S.current.profile_change_password);

  static String get logout => Tr.t('profile_logout', S.current.profile_logout);

  static String get deleteAccount =>
      Tr.t('profile_delete_account', S.current.profile_delete_account);

  /// The sign-out confirmation. Friendly on purpose: signing out is
  /// reversible and the customer loses nothing by it, so the dialog
  /// says so rather than sounding like a warning.
  static String get signOutTitle =>
      Tr.t('profile_sign_out_title', S.current.profile_sign_out_title);

  static String get signOutMessage =>
      Tr.t('profile_sign_out_message', S.current.profile_sign_out_message);

  /// The DESTRUCTIVE one. `DELETE /api/delete-account` is immediate,
  /// permanent and has no retention window, so the dialog names what
  /// goes with it rather than asking "are you sure".
  static String get deleteConfirm =>
      Tr.t('profile_delete_confirm', S.current.profile_delete_confirm);

  static String get deleteMessage =>
      Tr.t('profile_delete_message', S.current.profile_delete_message);

  static String get editName =>
      Tr.t('profile_edit_name', S.current.profile_edit_name);

  static String get nameLabel =>
      Tr.t('profile_name_label', S.current.profile_name_label);

  static String get nameHint =>
      Tr.t('profile_name_hint', S.current.profile_name_hint);

  static String get nameUpdated =>
      Tr.t('profile_name_updated', S.current.profile_name_updated);

  static String get currentPassword =>
      Tr.t('profile_current_password', S.current.profile_current_password);

  static String get currentPasswordHint => Tr.t(
    'profile_current_password_hint',
    S.current.profile_current_password_hint,
  );

  static String get passwordChanged =>
      Tr.t('profile_password_changed', S.current.profile_password_changed);

  static String get changePasswordMessage => Tr.t(
    'profile_change_password_message',
    S.current.profile_change_password_message,
  );

  static String get deleteWarning =>
      Tr.t('profile_delete_warning', S.current.profile_delete_warning);

  static String get addAddress =>
      Tr.t('profile_add_address', S.current.profile_add_address);

  static String get setDefault =>
      Tr.t('profile_set_default', S.current.profile_set_default);

  /// Named `defaultLabel` because `default` is a Dart keyword.
  static String get defaultLabel =>
      Tr.t('profile_default', S.current.profile_default);

  static String get noAddresses =>
      Tr.t('profile_no_addresses', S.current.profile_no_addresses);





  static String get notifFilterAll =>
      Tr.t('profile_notif_filter_all', S.current.profile_notif_filter_all);

  static String get notifFilterUnread => Tr.t(
    'profile_notif_filter_unread',
    S.current.profile_notif_filter_unread,
  );

  /// The name of one inbox tab.
  ///
  /// The SERVER owns this list — `GET /api/notifications` 422s any
  /// filter outside it — so the switch is exhaustive by construction
  /// and a new tab on the wire is a compile error here rather than a
  /// chip with no name.
  static String notifFilter(NotificationFilter filter) => switch (filter) {
    NotificationFilter.all => notifFilterAll,
    NotificationFilter.unread => notifFilterUnread,
    NotificationFilter.bookings => Tr.t(
      'profile_notif_filter_bookings',
      S.current.profile_notif_filter_bookings,
    ),
    NotificationFilter.reminders => Tr.t(
      'profile_notif_filter_reminders',
      S.current.profile_notif_filter_reminders,
    ),
    NotificationFilter.pieces => Tr.t(
      'profile_notif_filter_pieces',
      S.current.profile_notif_filter_pieces,
    ),
    NotificationFilter.orders => Tr.t(
      'profile_notif_filter_orders',
      S.current.profile_notif_filter_orders,
    ),
    NotificationFilter.gifts => Tr.t(
      'profile_notif_filter_gifts',
      S.current.profile_notif_filter_gifts,
    ),
    NotificationFilter.wallet => Tr.t(
      'profile_notif_filter_wallet',
      S.current.profile_notif_filter_wallet,
    ),
  };

  /// The filter is on and it matches nothing — which is a state the
  /// reader put the page in, not an empty inbox.
  static String get notifNoneInFilter => Tr.t(
    'profile_notif_none_in_filter',
    S.current.profile_notif_none_in_filter,
  );

  static String get noNotifications =>
      Tr.t('profile_no_notifications', S.current.profile_no_notifications);

  static String get markAllRead =>
      Tr.t('profile_mark_all_read', S.current.profile_mark_all_read);

  static String get noDevices =>
      Tr.t('profile_no_devices', S.current.profile_no_devices);

  static String get revoke => Tr.t('profile_revoke', S.current.profile_revoke);

  static String get thisDevice =>
      Tr.t('profile_this_device', S.current.profile_this_device);

  static String get noTransactions =>
      Tr.t('profile_no_transactions', S.current.profile_no_transactions);

  static String get orderDetail =>
      Tr.t('profile_order_detail', S.current.profile_order_detail);

  static String get cancelOrder =>
      Tr.t('profile_cancel_order', S.current.profile_cancel_order);

  /// Browsing without an account. The page still OPENS — what a guest
  /// cannot do is the rows that belong to a person.
  static String get guest => Tr.t('profile_guest', S.current.profile_guest);
  static String get guestHint =>
      Tr.t('profile_guest_hint', S.current.profile_guest_hint);

  /// «تواصل معنا» — the studio's own channels, from
  /// `GET /api/app-settings`.
  ///
  /// NOT the complaints screen. That one is called «إرسال شكوى» now:
  /// it files a formal complaint against an order, and it had been
  /// wearing the words a customer looks for when they simply want to
  /// message the studio.
  static String get contactUs =>
      Tr.t('profile_contact_us', S.current.profile_contact_us);

  static String get contactBody =>
      Tr.t('profile_contact_body', S.current.profile_contact_body);

  static String get contactSocial =>
      Tr.t('profile_contact_social', S.current.profile_contact_social);

  /// `app_settings` answered with nothing under `contact` and
  /// `social`. Said out loud — an empty sheet reads as a failure.
  static String get contactEmpty =>
      Tr.t('profile_contact_empty', S.current.profile_contact_empty);

  /// A GUEST opened the inbox. `GET /api/notifications` answers 401
  /// for them — verified live, even for a registered guest — so the
  /// page says what it is for instead of asking and being evicted.
  static String get notifSignedOut => Tr.t(
    'profile_notif_signed_out',
    S.current.profile_notif_signed_out,
  );

  static String get notifSignedOutBody => Tr.t(
    'profile_notif_signed_out_body',
    S.current.profile_notif_signed_out_body,
  );
}
