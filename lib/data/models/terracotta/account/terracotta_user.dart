// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'terracotta_user.freezed.dart';
part 'terracotta_user.g.dart';

/// The signed-in (or guest) principal — `GET /api/user`.
///
/// Returned RAW, not wrapped in a `user` key: the envelope's `data` IS
/// this object. The same shape is what `PUT /api/update-profile` echoes
/// back. This is the Terracotta account record and is deliberately
/// separate from the template's `User` in `data/models/auth/user/` —
/// that one is the generic starter shape, this one is the live wire.
///
/// **[walletBalance] IS A DECIMAL STRING** (`"0.00"`). Every monetary
/// value in this API is. Never parse it to a double to do arithmetic
/// with it — the wallet is applied against order totals server-side and
/// binary floats will disagree with what the customer is charged.
///
/// **[isActive] IS AN `int`, NOT A `bool`.** The live server sends
/// `"is_active": 1` — an uncast Laravel tinyint. The OpenAPI spec
/// claims `true`, and it is wrong for this endpoint. Typing it `bool`
/// throws at parse and takes the whole account screen with it. Read it
/// through [isAccountActive]. If a *different* endpoint (the guest
/// bootstrap, whose spec example does show `true`) is ever parsed into
/// this model, this is the field that will break first.
///
/// **Guests are users here too.** [isGuest] + [guestId] describe an
/// account created from the `X-Device-Id` header alone: it has an [id],
/// it can hold a cart, and it is promoted in place when the person
/// registers with the same device id. [name] and [phone] are therefore
/// NULLABLE — the live capture is a registered user and carries both,
/// but the guest record the API documents carries a generated name and
/// no phone at all.
///
/// **There is no `email` key.** This tenant is phone-only
/// (`GET /api/config` → `identifiers: ["phone"]`). An adopter who turns
/// on the email identifier must add `String? email` here; nothing in
/// the live capture proves its type today.
///
/// [verifiedAt] is null until the OTP is confirmed. [platform],
/// [guestId] and [lastSeenAt] are null in the capture — [guestId] is a
/// UUID string (it mirrors `X-Device-Id`), NOT an int, despite every
/// other id in this API being an int.
@freezed
abstract class TerracottaUser with _$TerracottaUser {
  const factory TerracottaUser({
    required int id,

    /// Display name. Null-safe on purpose: a guest record may not
    /// carry one.
    String? name,

    /// E.164 phone (`"+962700000000"`). The login identifier on this
    /// tenant. Null for a guest.
    String? phone,

    /// When the identifier was confirmed by OTP. Null while unverified.
    DateTime? verifiedAt,

    /// `1` / `0` on the wire, NOT a bool. Read [isAccountActive].
    ///
    /// DEFAULTED, like the two flags under it. The full user comes
    /// back on `login` and `GET /api/user`, but the spec's
    /// registration examples carry a LEANER one — id, name, phone,
    /// `is_active`, `verified_at`, `created_at` and no more. Declared
    /// `required`, a shape missing any of them throws inside
    /// `fromJson`, and the caller sees a request that plainly
    /// succeeded reported as a parse error. That is exactly what
    /// `AuthSession.token` did on 2026-09-17.
    ///
    /// An active account is the overwhelmingly common case and the
    /// only one worth assuming; the two flags below default to the
    /// answer that grants nothing.
    @Default(1) int isActive,

    /// True when this record was created from a device id rather than
    /// a registration.
    @Default(false) bool isGuest,

    /// App-review account — used to hide flows from the store reviewer.
    @Default(false) bool isReviewer,

    /// Platform the account was created on (`"web"`, `"ios"`,
    /// `"android"`). Null in the live capture.
    String? platform,

    /// UUID that mirrors the `X-Device-Id` header, present on guest
    /// records. A STRING, not an int.
    String? guestId,

    /// Last activity timestamp. Null in the live capture — prefer the
    /// per-device `last_seen_at` on `GET /api/devices`, which is
    /// populated.
    DateTime? lastSeenAt,

    /// Locale code the account is set to (`"en"`). Drives the language
    /// the server renders notification titles/bodies in.
    ///
    /// NULL on an account that has never chosen one — which includes
    /// every account the moment it is created. `POST /api/register`
    /// answers with `current_lang: null`, and this field being required
    /// meant a successful registration threw while parsing its own
    /// response: the account existed on the server and the app reported
    /// a failure. Verified live 2026-08-29.
    String? currentLang,

    required DateTime createdAt,

    /// Absent on the LEAN user the registration shapes carry — see
    /// [isActive].
    DateTime? updatedAt,

    /// Store credit as a DECIMAL STRING (`"0.00"`). Never a double.
    @Default('0.00') String walletBalance,

    /// False for an OTP-only or social-only account — gates whether the
    /// "change password" row is drawn.
    ///
    /// Defaults to FALSE, which draws nothing. Absent it is either a
    /// lean registration user — where no profile is on screen — or an
    /// account that has no password, and offering "change password"
    /// to somebody who has none is the worse of the two mistakes.
    @Default(false) bool hasPassword,
  }) = _TerracottaUser;

  const TerracottaUser._();

  factory TerracottaUser.fromJson(Map<String, dynamic> json) =>
      _$TerracottaUserFromJson(json);

  /// [isActive] as the boolean it means.
  bool get isAccountActive => isActive == 1;

  /// The identifier has been confirmed by OTP.
  bool get isVerified => verifiedAt != null;

  /// There is store credit worth showing. String compare against the
  /// zero literals — do NOT parse to a double for this.
  bool get hasWalletCredit =>
      walletBalance != '0.00' && walletBalance != '0' && walletBalance != '0.0';
}
