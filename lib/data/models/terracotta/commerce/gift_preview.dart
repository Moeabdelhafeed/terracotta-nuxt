// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'gift_preview.freezed.dart';
part 'gift_preview.g.dart';

/// What the RECIPIENT sees — `GET /api/gifts/{token}`.
///
/// **Public on purpose.** Possession of the token is what grants
/// access, and whoever opens a share link usually has no account at
/// all. Verified live on 2026-09-10: an unknown token answers **404**,
/// not 401, so this call can be made before anyone has signed in and a
/// miss never looks like a dead session.
///
/// **Deliberately narrower than the buyer's own [Gift].** It never
/// carries what the purchaser paid, their discount code, or the
/// recipient's phone — somebody forwarded a link, they were not handed
/// a receipt. Never render this through the buyer's model or the other
/// way round.
///
/// **[amount] is a decimal STRING** (`"200.00"`), like every other
/// money field on this API. Display it as it arrived.
///
/// **[isClaimable] is the only thing the button may read.** It is not
/// `!isRedeemed`: a gift can also be unclaimable because it was never
/// paid for, because gifting has been switched off, or because the
/// reader is the person who bought it. Deriving the button from
/// [isRedeemed] would offer a Claim that the server then refuses.
///
/// [deepLink] and [storeLinks] exist for the WEBSITE's "Open in app"
/// button. The app already is the app — it has no use for either, and
/// they are modelled only so the key-coverage guard stays honest about
/// what the server sends.
@freezed
abstract class GiftPreview with _$GiftPreview {
  const factory GiftPreview({
    /// The share token from the link. The id for every call here.
    required String token,

    /// Who it was addressed to, as the buyer typed it.
    required String recipientName,

    /// The buyer's note. Empty when they left it blank.
    @Default('') String message,

    /// Face value as a decimal string. Never parsed.
    required String amount,

    /// Who it is from, as the buyer typed it.
    @Default('') String from,

    required bool isRedeemed,

    /// When it was claimed. Null while it still stands.
    DateTime? redeemedAt,

    /// Whether a Claim button may be drawn at all — see the class doc.
    required bool isClaimable,

    /// `terracotta://gift/{token}` — the website's "Open in app"
    /// target. The app is already here.
    String? deepLink,

    /// Where to install the app. The website's buttons, not ours.
    @Default(<GiftStoreLink>[]) List<GiftStoreLink> storeLinks,
  }) = _GiftPreview;

  factory GiftPreview.fromJson(Map<String, dynamic> json) =>
      _$GiftPreviewFromJson(json);
}

/// One store button on the website's gift page.
@freezed
abstract class GiftStoreLink with _$GiftStoreLink {
  const factory GiftStoreLink({
    /// `app_store` or `google_play`. An OPEN set — the CMS holds
    /// these, so match the ones you handle and ignore the rest.
    required String type,
    required String url,
  }) = _GiftStoreLink;

  factory GiftStoreLink.fromJson(Map<String, dynamic> json) =>
      _$GiftStoreLinkFromJson(json);
}
