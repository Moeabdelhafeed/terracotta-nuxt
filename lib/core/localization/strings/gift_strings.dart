import '../../../generated/l10n.dart';
import '../tr.dart';

/// Gifting — buy a balance for someone and share the link.
class GiftStrings {
  GiftStrings._();

  static String get title => Tr.t('gift_title', S.current.gift_title);

  static String amount(String amount) =>
      Tr.t('gift_amount', S.current.gift_amount(amount));

  static String get recipientName =>
      Tr.t('gift_recipient_name', S.current.gift_recipient_name);

  static String get recipientPhone =>
      Tr.t('gift_recipient_phone', S.current.gift_recipient_phone);

  static String get recipientPhoneHint => Tr.t(
    'gift_recipient_phone_hint',
    S.current.gift_recipient_phone_hint,
  );

  static String get message => Tr.t('gift_message', S.current.gift_message);

  /// The line under «اهداء رصيد ٢٠٠ ريال» on the coral card — what the
  /// gift IS, in the design's own words.
  static String get heroBody =>
      Tr.t('gift_hero_body', S.current.gift_hero_body);

  /// What to do now that it is bought: the link is how the recipient
  /// redeems, and nothing is sent for the purchaser.
  static String get purchasedBody =>
      Tr.t('gift_purchased_body', S.current.gift_purchased_body);

  /// An EXAMPLE, not an instruction — the label above the box already
  /// says what the box is for.
  static String get recipientHint =>
      Tr.t('gift_recipient_hint', S.current.gift_recipient_hint);

  static String get messageHint =>
      Tr.t('gift_message_hint', S.current.gift_message_hint);

  static String get confirmAndPay =>
      Tr.t('gift_confirm_and_pay', S.current.gift_confirm_and_pay);

  static String get purchasedTitle =>
      Tr.t('gift_purchased_title', S.current.gift_purchased_title);

  static String get shareLink =>
      Tr.t('gift_share_link', S.current.gift_share_link);

  static String get empty => Tr.t('gift_empty', S.current.gift_empty);

  // ─── The sheet's two halves ───────────────────────────────────
  static String get tabSend =>
      Tr.t('gift_tab_send', S.current.gift_tab_send);

  static String get tabMine =>
      Tr.t('gift_tab_mine', S.current.gift_tab_mine);

  /// «إلى سارة» — who a gift on the list was bought for.
  static String forName(String name) =>
      Tr.t('gift_for', S.current.gift_for(name));

  /// «من نور» — who a CLAIMED gift came from, when the server names
  /// them. `from` is nullable in the spec.
  static String fromName(String name) =>
      Tr.t('gift_from', S.current.gift_from(name));

  /// The same row when it does not.
  static String get fromSomeone =>
      Tr.t('gift_from_someone', S.current.gift_from_someone);

  // ─── The history's own filter ─────────────────────────────────
  static String get filterAll =>
      Tr.t('gift_filter_all', S.current.gift_filter_all);

  static String get filterSent =>
      Tr.t('gift_filter_sent', S.current.gift_filter_sent);

  static String get filterReceived =>
      Tr.t('gift_filter_received', S.current.gift_filter_received);

  /// Said about the FILTER, not about the history — «لم ترسل أي هدية
  /// بعد» under a chip that is showing nothing is a different sentence
  /// from «ليس لديك هدايا».
  static String get noneSent =>
      Tr.t('gift_none_sent', S.current.gift_none_sent);

  static String get noneReceived =>
      Tr.t('gift_none_received', S.current.gift_none_received);

  /// The hold lapsed and the link is dead.
  static String get stateCancelled =>
      Tr.t('gift_state_cancelled', S.current.gift_state_cancelled);

  static String get stateClaimed =>
      Tr.t('gift_state_claimed', S.current.gift_state_claimed);

  static String get stateUnclaimed =>
      Tr.t('gift_state_unclaimed', S.current.gift_state_unclaimed);

  /// Bought but never paid for — the gift exists and the link does
  /// nothing until it settles.
  static String get stateUnpaid =>
      Tr.t('gift_state_unpaid', S.current.gift_state_unpaid);

  static String get copyLink =>
      Tr.t('gift_copy_link', S.current.gift_copy_link);

  static String get linkCopied =>
      Tr.t('gift_link_copied', S.current.gift_link_copied);

  // ─── The RECIPIENT's side — `terracotta://gift/{token}` ───

  /// «هدية لك» — the claim screen's heading. Addressed to whoever
  /// opened the link, who is usually not a customer yet.
  static String get claimTitle =>
      Tr.t('gift_claim_title', S.current.gift_claim_title);

  static String claimFrom(String name) =>
      Tr.t('gift_claim_from', S.current.gift_claim_from(name));

  static String claimTo(String name) =>
      Tr.t('gift_claim_to', S.current.gift_claim_to(name));

  static String get claimCta =>
      Tr.t('gift_claim_cta', S.current.gift_claim_cta);

  /// Shown under the button when there is no account behind it. The
  /// button still draws — the gate is at the tap, not at the door.
  static String get claimSignedOut =>
      Tr.t('gift_claim_signed_out', S.current.gift_claim_signed_out);

  static String get claimAlready =>
      Tr.t('gift_claim_already', S.current.gift_claim_already);

  /// Unclaimable for a reason the payload does not name — never paid
  /// for, gifting switched off, or the reader bought it themselves.
  static String get claimUnavailable =>
      Tr.t('gift_claim_unavailable', S.current.gift_claim_unavailable);

  static String get claimDoneTitle =>
      Tr.t('gift_claim_done_title', S.current.gift_claim_done_title);

  /// Both figures are decimal STRINGS, passed through as they arrived.
  static String claimDoneBody(String amount, String balance) => Tr.t(
    'gift_claim_done_body',
    S.current.gift_claim_done_body(amount, balance),
  );

  static String get claimOpenWallet =>
      Tr.t('gift_claim_open_wallet', S.current.gift_claim_open_wallet);

  /// A 404 — a mistyped link, or one that never existed.
  static String get claimNotFound =>
      Tr.t('gift_claim_not_found', S.current.gift_claim_not_found);

  /// The way out for someone with nothing to claim.
  static String get claimBrowse =>
      Tr.t('gift_claim_browse', S.current.gift_claim_browse);
}
