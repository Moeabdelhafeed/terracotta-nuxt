import 'package:freezed_annotation/freezed_annotation.dart';

import 'social_account.dart';

part 'social_account_list.freezed.dart';
part 'social_account_list.g.dart';

/// `GET /api/social-accounts` — linked providers, plus what the server
/// will still accept.
///
/// [allowedProviders] is admin-controlled and is EMPTY on the current
/// dev server (`config.social_providers` is `[]`), which is why the app
/// draws no social buttons. Read it at runtime rather than hardcoding
/// a provider list, so enabling Google in the CMS needs no app release.
@freezed
abstract class SocialAccountList with _$SocialAccountList {
  const factory SocialAccountList({
    @Default(<SocialAccount>[]) List<SocialAccount> socialAccounts,
    @Default(<String>[]) List<String> allowedProviders,
    int? maxAccounts,
    bool? canLinkMore,
  }) = _SocialAccountList;

  const SocialAccountList._();

  factory SocialAccountList.fromJson(Map<String, dynamic> json) =>
      _$SocialAccountListFromJson(json);

  /// Whether to draw the social sign-in row at all.
  bool get hasAnyProvider => allowedProviders.isNotEmpty;
}
