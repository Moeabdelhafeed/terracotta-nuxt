import 'package:flutter/foundation.dart';

/// What the sheet collected, on its way to the checkout.
///
/// `POST /api/gifts` takes `recipient_name` (required), `message` and
/// `recipient_phone` — all three are NOTES shown on the redeem screen,
/// not a lookup: the gift is claimed by whoever opens `share_url`, not
/// by a matched account. So nothing here is validated against a
/// customer, and an empty message is a gift with no note rather than a
/// failure.
///
/// The AMOUNT is not in here. It is admin-set — `GET /api/gifts/package`
/// answers it — and is not the purchaser's to choose.
@immutable
class GiftDraft {
  const GiftDraft({
    required this.recipientName,
    this.message,
    this.recipientPhone,
  });

  /// Who it is for, as the purchaser types it.
  final String recipientName;

  /// A note shown to the recipient. Null when they wrote none — the
  /// wire wants a missing key rather than an empty string.
  final String? message;

  /// The recipient's number in E.164, when the purchaser gave one.
  ///
  /// OPTIONAL, and the spec says why: it is "a contact note for the
  /// purchaser's own reference". Nothing is sent to it — the gift is
  /// claimed by whoever opens `share_url` — so this must never be what
  /// gates the way on.
  final String? recipientPhone;

  /// Whether there is enough to buy with. The name is the only thing
  /// the server requires.
  bool get isComplete => recipientName.trim().isNotEmpty;

  /// The wire shape, with the blanks left out.
  Map<String, dynamic> toJson() => {
    'recipient_name': recipientName.trim(),
    if ((message ?? '').trim().isNotEmpty) 'message': message!.trim(),
    if ((recipientPhone ?? '').trim().isNotEmpty)
      'recipient_phone': recipientPhone!.trim(),
  };
}
