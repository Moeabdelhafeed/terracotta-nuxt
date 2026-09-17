import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'notification_channels.dart';
import 'notification_payload.dart';
import 'notification_types.dart';

/// A time range during which non-urgent notifications are silenced
/// (displayed but without sound / vibration, or fully suppressed
/// depending on [suppressEntirely]).
///
/// Wraps around midnight — `start: 22:00, end: 08:00` means "from
/// 10 PM to 8 AM the next day".
@immutable
class QuietHours {
  const QuietHours({
    required this.start,
    required this.end,
    this.suppressEntirely = false,
    this.weekdayMask = 0x7F,
  });

  /// Disabled — nothing is ever in quiet hours.
  static const QuietHours disabled = QuietHours(
    start: ClockTime(0, 0),
    end: ClockTime(0, 0),
    weekdayMask: 0,
  );

  final ClockTime start;
  final ClockTime end;

  /// When true, quiet-hours notifications are dropped entirely.
  /// When false (default), they deliver silently (no sound/vibration).
  final bool suppressEntirely;

  /// Bitmask of active days. LSB = Monday, bit 6 = Sunday. `0x7F`
  /// means all days (default). `0x1F` = weekdays only.
  final int weekdayMask;

  bool get enabled => start != end || weekdayMask != 0;

  bool contains(DateTime moment) {
    if (!enabled) return false;
    // weekday: Monday = 1 … Sunday = 7. Bit index = weekday - 1.
    final dayBit = 1 << (moment.weekday - 1);
    if ((weekdayMask & dayBit) == 0) return false;

    final mins = moment.hour * 60 + moment.minute;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    if (s == e) return false;
    if (s < e) return mins >= s && mins < e;
    // Wrap-around (e.g. 22:00 → 08:00).
    return mins >= s || mins < e;
  }

  Map<String, dynamic> toJson() => {
    'start': '${start.hour}:${start.minute}',
    'end': '${end.hour}:${end.minute}',
    'suppress': suppressEntirely,
    'mask': weekdayMask,
  };

  factory QuietHours.fromJson(Map<String, dynamic> json) {
    final s = (json['start'] as String? ?? '0:0').split(':');
    final e = (json['end'] as String? ?? '0:0').split(':');
    return QuietHours(
      start: ClockTime(
        int.tryParse(s[0]) ?? 0,
        int.tryParse(s.elementAtOrNull(1) ?? '0') ?? 0,
      ),
      end: ClockTime(
        int.tryParse(e[0]) ?? 0,
        int.tryParse(e.elementAtOrNull(1) ?? '0') ?? 0,
      ),
      suppressEntirely: json['suppress'] as bool? ?? false,
      weekdayMask: json['mask'] as int? ?? 0x7F,
    );
  }
}

@immutable
class ClockTime {
  const ClockTime(this.hour, this.minute);
  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;
  @override
  int get hashCode => Object.hash(hour, minute);
}

/// How a notification should be presented, after preferences have
/// been consulted. Returned by [NotificationPreferences.evaluate].
enum NotificationPresentation {
  /// Full display — sound, vibration, heads-up (if priority warrants).
  full,

  /// Display but without sound/vibration/lights. User still sees it
  /// in the shade.
  silent,

  /// Drop entirely. Do not display.
  suppress,
}

/// Persistent user preferences for notifications:
///  - **Master switch** — toggle-all on/off.
///  - **Per-channel toggles** — mute specific categories (orders,
///    promos, …) independently.
///  - **Quiet hours** — silence non-critical traffic during a
///    window.
///
/// Persisted via [HydratedBloc.storage] (already initialized in
/// `main.dart`) under a dedicated key namespace so it doesn't tangle
/// with the `PreferencesCubit` state. Calling [evaluate] from the
/// notification pipeline decides whether to display.
///
/// Singleton via [instance] — access is cheap, no DI setup needed.
/// ```dart
/// NotificationPreferences.instance.setChannelMuted(
///   NotificationChannelsRegistry.promo.id, true);
///
/// final decision = NotificationPreferences.instance.evaluate(payload);
/// ```
class NotificationPreferences extends ChangeNotifier {
  NotificationPreferences._();

  static final NotificationPreferences instance = NotificationPreferences._();

  static const _storageKey = 'notification_preferences_v1';
  Storage get _storage => HydratedBloc.storage;

  bool _masterEnabled = true;
  final Map<String, bool> _mutedChannels = {};
  QuietHours _quietHours = QuietHours.disabled;

  /// Load from storage. Idempotent — safe to call on every app start.
  void load() {
    final raw = _storage.read(_storageKey);
    if (raw is Map) {
      _masterEnabled = raw['master'] as bool? ?? true;
      final muted = raw['muted'] as Map? ?? {};
      _mutedChannels
        ..clear()
        ..addAll(
          muted.map((k, v) => MapEntry(k.toString(), v as bool? ?? false)),
        );
      final qh = raw['quietHours'] as Map?;
      if (qh != null) {
        _quietHours = QuietHours.fromJson(qh.cast<String, dynamic>());
      }
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.write(_storageKey, {
      'master': _masterEnabled,
      'muted': _mutedChannels,
      'quietHours': _quietHours.toJson(),
    });
    notifyListeners();
  }

  // ─── Master switch ───────────────────────────────────────────────

  bool get masterEnabled => _masterEnabled;
  set masterEnabled(bool value) {
    if (_masterEnabled == value) return;
    _masterEnabled = value;
    _persist();
  }

  // ─── Per-channel ─────────────────────────────────────────────────

  /// True when the given channel ID is muted. Unknown IDs default to
  /// not-muted.
  bool isChannelMuted(String channelId) => _mutedChannels[channelId] ?? false;

  /// True when the channel serving [type] is muted.
  bool isTypeMuted(NotificationType type) {
    return isChannelMuted(NotificationChannelsRegistry.forType(type).id);
  }

  void setChannelMuted(String channelId, bool muted) {
    if ((_mutedChannels[channelId] ?? false) == muted) return;
    if (muted) {
      _mutedChannels[channelId] = true;
    } else {
      _mutedChannels.remove(channelId);
    }
    _persist();
  }

  void setTypeMuted(NotificationType type, bool muted) {
    setChannelMuted(NotificationChannelsRegistry.forType(type).id, muted);
  }

  List<String> get mutedChannels => List.unmodifiable(
    _mutedChannels.keys.where((k) => _mutedChannels[k] == true),
  );

  // ─── Quiet hours ─────────────────────────────────────────────────

  QuietHours get quietHours => _quietHours;

  set quietHours(QuietHours value) {
    _quietHours = value;
    _persist();
  }

  // ─── Evaluate ────────────────────────────────────────────────────

  /// Decide how a given [payload] should be presented *right now*.
  /// Route the decision through the notification pipeline before
  /// displaying.
  ///
  /// Resolution:
  ///  - Master disabled → [suppress].
  ///  - Channel muted → [suppress] (unless priority is `max`, which
  ///    treats as [silent] — system/security alerts bypass mutes).
  ///  - In quiet hours + priority ≤ `normal` → [silent] (or
  ///    [suppress] when [QuietHours.suppressEntirely]).
  ///  - Otherwise → [full].
  NotificationPresentation evaluate(
    NotificationPayload payload, {
    DateTime? now,
  }) {
    if (!_masterEnabled) return NotificationPresentation.suppress;

    final priority = payload.effectivePriority;
    if (isTypeMuted(payload.type)) {
      return priority == NotificationPriority.max
          ? NotificationPresentation.silent
          : NotificationPresentation.suppress;
    }

    final moment = now ?? DateTime.now();
    if (_quietHours.contains(moment) &&
        priority.index <= NotificationPriority.normal.index) {
      return _quietHours.suppressEntirely
          ? NotificationPresentation.suppress
          : NotificationPresentation.silent;
    }

    return NotificationPresentation.full;
  }
}
