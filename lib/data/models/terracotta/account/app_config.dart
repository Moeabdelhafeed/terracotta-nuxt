// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// Live tenant configuration — `GET /api/config`.
///
/// Public (no bearer token, only the standard device headers) and the
/// FIRST call the app makes. Everything about the auth UI is decided
/// here at runtime, not at build time: which identifier the login form
/// asks for, whether a password field or an OTP field is drawn, whether
/// social buttons exist at all, whether a guest may browse. Fetch it on
/// splash and cache it; hardcoding any of it means the studio flipping a
/// switch in the CMS ships a broken build.
///
/// **[identifiers] is the login form's shape AND the `type` the login
/// call requires.** `POST /api/login` 422s with
/// `{"type": ["The type field is required."]}` unless you send the
/// identifier kind (`phone` / `email` / `username`) alongside the
/// credential — it is never inferred from the value. Read it through
/// [identifierKinds] and send the matching wire string.
///
/// **The `has_*_field` flags do NOT mirror [identifiers].** The live
/// capture returns `identifiers: ["phone"]` while all three of
/// [hasUsernameField], [hasEmailField] and [hasPhoneField] are `false`.
/// They are separate switches — [identifiers] says what you may sign in
/// WITH, the flags say what the register/profile form additionally
/// COLLECTS. Do not derive one from the other.
///
/// **Social login is off on the live tenant** and the payload says so
/// three different ways: `social_providers: []`,
/// `max_social_accounts: 0`, `social_auth_available: false`. Gate the
/// whole section on [showsSocialButtons] rather than on any single flag.
///
/// [allowedEmailDomains] and [allowedPhoneCountries] are the sentinel
/// string `"all"` on the live server, NOT a list. When the studio
/// restricts them this is expected to become a delimited string
/// (`"SA"`) — keep it a String and parse at the call site; typing it as
/// a list would throw today.
///
/// Every key is present and non-null in the live capture, so every field
/// is required. Empty lists arrive as `[]`, never as null.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    /// Identifier kinds accepted at login (`["phone"]` live). Also the
    /// value the login call's mandatory `type` field must carry.
    required List<String> identifiers,

    /// Whether the register/profile form collects a username.
    required bool hasUsernameField,

    /// Whether the register/profile form collects an email.
    required bool hasEmailField,

    /// Whether the register/profile form collects a phone number.
    required bool hasPhoneField,

    /// Firebase provider ids offered for social login
    /// (`["google.com", "apple.com"]`). Empty on the live tenant.
    required List<String> socialProviders,

    /// How many social accounts one user may link. `0` live.
    required int maxSocialAccounts,

    /// Master switch for the social login section.
    required bool socialAuthAvailable,

    /// OTPs are delivered over WhatsApp rather than SMS. Changes the
    /// copy on the verification screen, not the flow.
    required bool isOtpWhatsapp,

    /// More than one device may hold a live session at once. When
    /// false, `GET /api/devices` always returns exactly one row.
    required bool multiSession,

    /// Registered accounts are enabled.
    required bool appUsers,

    /// Guests may browse and buy without an account (`true` live).
    required bool appGuests,

    /// WHETHER THE STUDIO IS SELLING GIFT CREDIT AT ALL.
    ///
    /// **Not on the live payload yet** — probed 2026-09-16, `/api/config`
    /// carries neither this nor any other gift flag, and `/docs.openapi`
    /// has no `allow_gift` in it. Modelled nullable so its ABSENCE is
    /// not a switch-off: a build that hid the gift tile the moment the
    /// key went missing would take a live feature off every screen the
    /// first time the endpoint was redeployed.
    ///
    /// Read it through [allowsGift], which answers true until the
    /// server says otherwise.
    bool? allowGift,

    /// `"password"` (live) or `"otp"`. Read via [mode].
    required String authMode,

    /// `"all"`, or a restriction expression. Not a list.
    required String allowedEmailDomains,

    /// `"all"` live — which is why a non-Saudi `+962…` number logs in.
    /// Not a list.
    required String allowedPhoneCountries,

    /// THE BROADCAST TOPICS this backend publishes to.
    ///
    /// Nine of them live: an `all` / `guests` / `users` base, each on
    /// its own and once per language. A device subscribes to the ones
    /// that describe it — see `NotificationTopics`.
    ///
    /// **This is the authority, and guessing is worse than useless.**
    /// The app used to invent names by convention and suffix them per
    /// flavor (`all_dev`); the server publishes no suffix at all, so
    /// every subscription went to a topic nobody sends to — and a
    /// subscription to a topic that does not exist fails SILENTLY.
    ///
    /// Empty on a server that predates the field, which simply means
    /// no broadcasts.
    @Default(<FcmTopic>[]) List<FcmTopic> fcmTopics,
  }) = _AppConfig;

  const AppConfig._();

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  /// [authMode] resolved. Unknown modes fall back to
  /// [AuthMode.password] — the form that always works.
  AuthMode get mode => AuthMode.fromWire(authMode);

  /// [identifiers] resolved, unknown entries dropped rather than
  /// rendered as a field nobody can fill.
  List<AuthIdentifier> get identifierKinds => identifiers
      .map(AuthIdentifier.fromWire)
      .where((i) => i != AuthIdentifier.unknown)
      .toList(growable: false);

  /// Draw the social login section only when all three switches agree.
  /// Whether to offer gift credit. TRUE until the server says no.
  ///
  /// An absent key is not a no — see [allowGift].
  bool get allowsGift => allowGift ?? true;

  bool get showsSocialButtons =>
      socialAuthAvailable &&
      socialProviders.isNotEmpty &&
      maxSocialAccounts > 0;
}

/// How the tenant authenticates — `auth_mode` from `GET /api/config`.
enum AuthMode {
  /// Credential + password. The live dev server's mode.
  password('password'),

  /// Credential + a one-time code, delivered by SMS or (when
  /// `is_otp_whatsapp`) WhatsApp.
  otp('otp');

  const AuthMode(this.wire);

  /// The value as it arrives from the API.
  final String wire;

  /// Resolves a wire value, falling back to [password] rather than
  /// throwing — a mode added in the CMS must not crash a shipped build,
  /// and the password form is the safe thing to draw.
  static AuthMode fromWire(String? value) =>
      values.firstWhere((m) => m.wire == value, orElse: () => password);
}

/// A credential kind — an entry of `identifiers`, and the `type` value
/// `POST /api/login` demands.
enum AuthIdentifier {
  phone('phone'),
  email('email'),
  username('username'),

  /// A kind this build does not know how to render. Dropped from
  /// [AppConfig.identifierKinds] instead of drawn.
  unknown('unknown');

  const AuthIdentifier(this.wire);

  /// The value as it arrives from the API, and the value to send back
  /// as the login `type`.
  final String wire;

  /// Resolves a wire value, falling back to [unknown] rather than
  /// throwing.
  static AuthIdentifier fromWire(String? value) =>
      values.firstWhere((i) => i.wire == value, orElse: () => unknown);
}

/// One broadcast topic the backend publishes to.
///
/// [name] is what FCM is given. [base] is the audience it describes —
/// `all`, `guests` or `users` — and [lang] narrows it to readers of one
/// language, or is null for every language.
///
/// The two halves are sent separately from [name] so the app can pick
/// by MEANING rather than by parsing the string: a fourth base tomorrow
/// needs no new parsing here.
@freezed
abstract class FcmTopic with _$FcmTopic {
  const factory FcmTopic({
    required String name,
    required String base,
    String? lang,
  }) = _FcmTopic;

  const FcmTopic._();

  factory FcmTopic.fromJson(Map<String, dynamic> json) =>
      _$FcmTopicFromJson(json);

  /// Whether this topic describes a reader in [languageCode] who is
  /// (or is not) signed in.
  bool appliesTo({required String languageCode, required bool signedIn}) {
    if (lang != null && lang != languageCode) return false;
    return switch (base) {
      'all' => true,
      'users' => signedIn,
      'guests' => !signedIn,
      // A base nobody has told the app about. Left alone rather than
      // guessed at — a broadcast group the app subscribes to by
      // accident is worse than one it misses.
      _ => false,
    };
  }
}
