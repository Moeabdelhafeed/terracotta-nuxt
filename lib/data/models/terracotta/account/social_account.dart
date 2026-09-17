// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_account.freezed.dart';
part 'social_account.g.dart';

/// A linked social identity —
/// `GET /api/social-accounts` → `data.social_accounts[]`, and the row
/// `POST /api/link-social-account` creates.
///
/// The response wraps the list next to the tenant's limits:
/// `{"social_accounts": [], "allowed_providers": [], "max_accounts": 0,
/// "can_link_more": true}`.
///
/// **SHAPE IS PROVISIONAL — the live capture came back EMPTY, because
/// social login is switched OFF on this tenant.** `GET /api/config`
/// agrees three ways: `social_providers: []`, `max_social_accounts: 0`,
/// `social_auth_available: false`. Not one field below has been seen on
/// the wire; the names and types come from the OpenAPI example. Every
/// field is nullable except [id]. **Re-verify before shipping the
/// linked-accounts screen.**
///
/// **`can_link_more` is `true` while `max_accounts` is `0`** in the same
/// live payload — they contradict each other. Gate the "link another
/// account" button on `AppConfig.showsSocialButtons` instead of
/// trusting either flag alone.
///
/// [provider] is a FIREBASE provider id (`"google.com"`, `"apple.com"`)
/// — the dotted form, not a bare `"google"`. Linking goes through
/// Firebase and the token's email must match the account's, so the
/// same string is what you pass to the Firebase SDK. Read via [kind].
@freezed
abstract class SocialAccount with _$SocialAccount {
  const factory SocialAccount({
    required int id,

    /// Firebase provider id, dotted (`"google.com"`). Read via [kind].
    String? provider,

    /// Email the provider asserted. Must match the account's email for
    /// the link to have been accepted.
    String? email,

    /// Display name from the provider.
    String? name,
  }) = _SocialAccount;

  const SocialAccount._();

  factory SocialAccount.fromJson(Map<String, dynamic> json) =>
      _$SocialAccountFromJson(json);

  /// [provider] resolved. Unknown providers come back as
  /// [SocialProvider.unknown] — still a real link the customer may
  /// want to remove, so render it with the raw [provider] string
  /// rather than hiding the row.
  SocialProvider get kind => SocialProvider.fromWire(provider);
}

/// A social login provider, in Firebase's dotted id form.
enum SocialProvider {
  google('google.com'),
  apple('apple.com'),
  facebook('facebook.com'),

  /// A provider this build has no button for. Show the row, use the
  /// raw wire string as its label.
  unknown('unknown');

  const SocialProvider(this.wire);

  /// The value as it arrives from the API, and the id the Firebase SDK
  /// expects.
  final String wire;

  /// Resolves a wire value, falling back to [unknown] rather than
  /// throwing — the CMS's `allowed_providers` list is editable and a
  /// shipped build must survive a provider it has never heard of.
  static SocialProvider fromWire(String? value) =>
      values.firstWhere((p) => p.wire == value, orElse: () => unknown);
}
