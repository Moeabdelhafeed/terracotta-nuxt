import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `notifications_channel_` key prefix family —
/// Android notification channel names/descriptions shown in OS
/// settings. Channel `id`s stay stable; only display copy localizes.
class NotificationChannelStrings {
  NotificationChannelStrings._();

  static String get transactionalName => Tr.t(
    'notifications.channel_transactional_name',
    S.current.notifications_channel_transactional_name,
  );
  static String get transactionalDescription => Tr.t(
    'notifications.channel_transactional_description',
    S.current.notifications_channel_transactional_description,
  );
  static String get messagesName => Tr.t(
    'notifications.channel_messages_name',
    S.current.notifications_channel_messages_name,
  );
  static String get messagesDescription => Tr.t(
    'notifications.channel_messages_description',
    S.current.notifications_channel_messages_description,
  );
  static String get promoName => Tr.t(
    'notifications.channel_promo_name',
    S.current.notifications_channel_promo_name,
  );
  static String get promoDescription => Tr.t(
    'notifications.channel_promo_description',
    S.current.notifications_channel_promo_description,
  );
  static String get systemName => Tr.t(
    'notifications.channel_system_name',
    S.current.notifications_channel_system_name,
  );
  static String get systemDescription => Tr.t(
    'notifications.channel_system_description',
    S.current.notifications_channel_system_description,
  );
  static String get generalName => Tr.t(
    'notifications.channel_general_name',
    S.current.notifications_channel_general_name,
  );
  static String get generalDescription => Tr.t(
    'notifications.channel_general_description',
    S.current.notifications_channel_general_description,
  );
}
