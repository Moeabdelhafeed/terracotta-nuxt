import '../models/terracotta/account/app_config.dart';

/// WHICH BROADCAST TOPICS this device belongs on.
///
/// ## What topics are for here
///
/// Everything the app has seen so far is addressed to ONE customer — a
/// booking confirmed, an order on its way — and the server sends those
/// to the device token it already holds, which is why pushes worked
/// with no topic at all. A studio-wide ANNOUNCEMENT has no device
/// list: it goes to a topic, and a device that never subscribed never
/// hears it.
///
/// ## The names come from the server
///
/// `GET /api/config` returns `fcm_topics`, nine of them: an `all`,
/// `guests` and `users` base, each on its own and once per language.
///
/// **They are read, never guessed.** This used to invent names by
/// convention and suffix them per flavor — `all_dev`, `all_en_dev` —
/// and the server publishes no suffix at all, so every subscription
/// went to a topic nobody sends to. FCM accepts a subscription to any
/// well-formed name, so that failed **silently**: the device was
/// happily subscribed to nine topics that did not exist.
///
/// ## Who a device is
///
/// Two things decide it, and both change while the app is running: the
/// language being read, and whether there is an account. So this is
/// re-resolved on a language change AND on sign-in and sign-out — a
/// reader who signs in moves off `guests` and onto `users`, and one
/// who switches to Arabic stops being sent English announcements.
class NotificationTopics {
  const NotificationTopics._();

  /// The topics a reader in [languageCode] belongs on.
  ///
  /// Empty when the server published none, which simply means no
  /// broadcasts — not a reason to fall back to invented names.
  static List<String> forReader(
    List<FcmTopic> published, {
    required String languageCode,
    required bool signedIn,
  }) => [
    for (final topic in published)
      if (topic.appliesTo(languageCode: languageCode, signedIn: signedIn))
        topic.name,
  ];
}
