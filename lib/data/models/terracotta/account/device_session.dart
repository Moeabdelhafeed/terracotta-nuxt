// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_session.freezed.dart';
part 'device_session.g.dart';

/// One active session — `GET /api/devices` → `data.devices[]`.
///
/// The "logged in on these devices" list, and the row a
/// `DELETE /api/devices/{id}` revokes. Only meaningful when
/// `GET /api/config` → `multi_session` is true; otherwise there is
/// always exactly one row.
///
/// **[isCurrent] marks the session making the request** — it is
/// resolved from the `X-Device-Id` header, not from anything the client
/// tracks. It is the row whose "sign out" button must warn (or be
/// disabled), because revoking it logs the user out of the app they are
/// standing in. Use [isCurrent], never a locally stored id.
///
/// **THE LIST IS NOT SORTED.** The live capture came back in id order
/// `21, 22, 19, 20` — neither newest-first, nor [lastSeenAt] descending,
/// nor current-first. Sort it yourself before rendering.
///
/// [deviceName] was NULL on all four captured sessions, so its type is
/// inferred from the spec (`string, nullable`) rather than observed.
/// Fall back to [platform] + [userAgent] for a label; do not assume a
/// human-readable name will ever arrive.
///
/// [platform] is derived SERVER-side from the request, not from what
/// the client claims: the captured rows say `"web"` for a `curl` user
/// agent even though the `X-Platform` header drives most of this API.
/// Values seen/documented: `web`, `ios`, `android`. Read via
/// [platformKind].
///
/// [ip] is the raw remote address and is shown to the customer as a
/// security signal — do not log or transmit it anywhere else.
@freezed
abstract class DeviceSession with _$DeviceSession {
  const factory DeviceSession({
    required int id,

    /// Human label for the device. Null on every captured session.
    String? deviceName,

    /// `"web"` / `"ios"` / `"android"`. Read via [platformKind].
    required String platform,

    /// Remote address the session was last seen from.
    required String ip,

    /// Raw user agent (`"curl/8.7.1"` in the capture).
    required String userAgent,

    /// Last activity. Populated here even though the account-level
    /// `last_seen_at` on `GET /api/user` is null.
    required DateTime lastSeenAt,

    required DateTime createdAt,

    /// True for the session that made this request. Revoking it signs
    /// the app out.
    required bool isCurrent,
  }) = _DeviceSession;

  const DeviceSession._();

  factory DeviceSession.fromJson(Map<String, dynamic> json) =>
      _$DeviceSessionFromJson(json);

  /// [platform] resolved. An unrecognised platform comes back as
  /// [DevicePlatform.unknown] and should render with a generic device
  /// icon rather than being hidden.
  DevicePlatform get platformKind => DevicePlatform.fromWire(platform);
}

/// Where a session is running — `platform` on a device row.
enum DevicePlatform {
  ios('ios'),
  android('android'),
  web('web'),

  /// A platform this build does not know. Still a real, revocable
  /// session — show it with a generic icon, never drop it from the
  /// list.
  unknown('unknown');

  const DevicePlatform(this.wire);

  /// The value as it arrives from the API.
  final String wire;

  /// Resolves a wire value, falling back to [unknown] rather than
  /// throwing — a platform added server-side (desktop, a watch app)
  /// must not crash the sessions screen.
  static DevicePlatform fromWire(String? value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => unknown);
}
