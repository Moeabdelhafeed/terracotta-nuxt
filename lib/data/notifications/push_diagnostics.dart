import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// What actually happened to the push pipeline on THIS device.
///
/// ## Why this exists
///
/// Every failure mode in FCM topics is silent, and they look identical
/// from the outside — "the studio sent a broadcast and nothing
/// arrived":
///
///   * the app subscribed to a name nobody publishes to (the old
///     flavor-suffixed guesses, `all_dev`);
///   * the subscription call itself failed, and `subscribeToTopic`
///     warns and swallows;
///   * the device is subscribed correctly and the SERVER is not
///     sending to a topic at all;
///   * the message arrived and something downstream dropped it.
///
/// FCM has no API to ask which topics a device is on, so the first two
/// cannot be read back — they have to be recorded as they happen. The
/// last two are told apart by ONE field: [RemoteMessage.from] is
/// `/topics/<name>` for a topic broadcast and the sender id for a
/// message addressed to this device's token. That single string is the
/// answer to "is it us or is it them".
///
/// ## What it cannot see
///
/// A push that arrives while the app is TERMINATED or backgrounded is
/// handled in a separate isolate, which does not share this memory. So
/// [received] holds foreground arrivals, taps that opened the app, and
/// the cold-start message — not a notification that landed silently in
/// the tray. For that, watch the device's own log:
/// `tools/watch_push.sh`.
///
/// Debug-and-dev instrument. It keeps [_cap] entries and nothing else.
class PushDiagnostics {
  PushDiagnostics._();

  static final PushDiagnostics instance = PushDiagnostics._();

  /// Rebuilt whenever anything below changes, so a screen can watch it.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static const _cap = 40;

  String? _token;

  /// This device's FCM registration token — what a message addressed
  /// to one customer is sent to.
  String? get token => _token;

  final List<TopicAttempt> _topics = [];

  /// Every subscribe and unsubscribe this run tried, newest last.
  List<TopicAttempt> get topics => List.unmodifiable(_topics);

  /// The names the app most recently decided this reader belongs on.
  List<String> wanted = const [];

  /// What the server published in `fcm_topics`, before filtering.
  List<String> published = const [];

  /// What happened to `GET /api/config`, the call the topic names come
  /// from.
  ///
  /// **This is the line that was missing.** An empty [published] can
  /// mean the call never ran, ran and failed, or succeeded with no
  /// topics — three different faults that looked identical, because
  /// `TopicSubscription.apply()` returns on an empty list without a
  /// word and a release build prints no log at all.
  String configState = 'not attempted';

  final List<PushReceipt> _received = [];

  /// Messages this isolate saw, newest first.
  List<PushReceipt> get received => List.unmodifiable(_received.reversed);

  void recordToken(String? value) {
    _token = value;
    _bump();
  }

  void recordConfig(String state) {
    configState = state;
    _bump();
  }

  void recordPublished(List<String> names) {
    published = List.unmodifiable(names);
    _bump();
  }

  void recordWanted(List<String> names) {
    wanted = List.unmodifiable(names);
    _bump();
  }

  void recordTopic(TopicAttempt attempt) {
    _topics
      ..removeWhere((t) => t.topic == attempt.topic)
      ..add(attempt);
    _bump();
  }

  void recordMessage(RemoteMessage message, {required String stage}) {
    _received.add(PushReceipt.of(message, stage: stage));
    if (_received.length > _cap) _received.removeAt(0);
    _bump();
  }

  void clear() {
    _topics.clear();
    _received.clear();
    _bump();
  }

  void _bump() => revision.value++;

  /// Everything above as one block of text, for pasting into a bug
  /// report or handing to whoever runs the backend.
  String report() {
    final out = StringBuffer()
      ..writeln('── push diagnostics ──')
      ..writeln('token: ${_token ?? "(none)"}')
      ..writeln('GET /api/config: $configState')
      ..writeln('published by server: ${published.join(", ")}')
      ..writeln('this reader belongs on: ${wanted.join(", ")}')
      ..writeln('')
      ..writeln('subscriptions (${_topics.length}):');
    for (final t in _topics) {
      out.writeln('  ${t.line}');
    }
    out
      ..writeln('')
      ..writeln('messages seen by this isolate (${_received.length}):');
    if (_received.isEmpty) {
      out.writeln('  (none — see tools/watch_push.sh for background ones)');
    }
    for (final r in received) {
      out.writeln('  ${r.line}');
    }
    return out.toString();
  }
}

/// One subscribe or unsubscribe, and whether FCM took it.
@immutable
class TopicAttempt {
  const TopicAttempt({
    required this.topic,
    required this.subscribed,
    required this.at,
    this.error,
  });

  final String topic;

  /// True for a subscribe, false for an unsubscribe.
  final bool subscribed;

  final DateTime at;

  /// Null when it went through. `subscribeToTopic` catches and warns,
  /// so without this the failure leaves no trace at all.
  final String? error;

  bool get ok => error == null;

  String get line {
    final verb = subscribed ? 'subscribe' : 'unsubscribe';
    final mark = ok ? '✓' : '✗';
    return '$mark $verb $topic${error == null ? '' : ' — $error'}';
  }
}

/// One message that reached this isolate.
@immutable
class PushReceipt {
  const PushReceipt({
    required this.at,
    required this.stage,
    required this.from,
    required this.messageId,
    required this.hasNotification,
    required this.dataKeys,
    this.title,
  });

  factory PushReceipt.of(RemoteMessage m, {required String stage}) =>
      PushReceipt(
        at: DateTime.now(),
        stage: stage,
        from: m.from,
        messageId: m.messageId,
        hasNotification: m.notification != null,
        dataKeys: m.data.keys.toList(growable: false),
        title: m.notification?.title,
      );

  final DateTime at;

  /// `foreground`, `opened` or `cold-start` — how the app saw it.
  final String stage;

  /// **THE FIELD THAT ANSWERS THE QUESTION.** `/topics/<name>` when
  /// the message was broadcast to a topic; the sender id when it was
  /// addressed to this device's token.
  final String? from;

  final String? messageId;

  /// Whether it carried a `notification` block. A DATA-ONLY message is
  /// never displayed by the OS on its own — the app has to draw it,
  /// which it only does while running.
  final bool hasNotification;

  final List<String> dataKeys;
  final String? title;

  /// Whether this arrived over a topic rather than to the token.
  bool get viaTopic => from?.startsWith('/topics/') ?? false;

  /// The topic it came from, or null when it was sent to the token.
  String? get topic =>
      viaTopic ? from!.substring('/topics/'.length) : null;

  String get line {
    final clock = at.toIso8601String().substring(11, 19);
    final route = viaTopic ? 'topic:$topic' : 'token';
    final kind = hasNotification ? 'notification' : 'data-only';
    return '$clock $stage $route $kind '
        '${title ?? ''} ${dataKeys.isEmpty ? '' : dataKeys}'.trim();
  }
}
