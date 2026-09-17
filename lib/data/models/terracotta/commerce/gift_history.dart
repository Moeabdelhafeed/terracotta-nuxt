import 'package:freezed_annotation/freezed_annotation.dart';

import 'gift.dart';

part 'gift_history.freezed.dart';
part 'gift_history.g.dart';

/// Which side of a gift a row is — `GET /api/gifts/history`.
enum GiftDirection {
  /// The reader BOUGHT it.
  sent('sent'),

  /// The reader CLAIMED it. Not "addressed to them": `recipient_name`
  /// is free text the buyer typed and whoever opens the share link
  /// gets the credit, so a gift only lands here once redeemed.
  received('received');

  const GiftDirection(this.wire);

  final String wire;

  /// Unknown spellings read as [sent], which is the row shape that
  /// carries everything — a received row missing its narrow fields
  /// renders blank, where a sent row missing them is normal.
  static GiftDirection fromWire(String? value) =>
      value == received.wire ? received : sent;
}

/// The whole story, both directions — `GET /api/gifts/history`.
///
/// ## Two shapes in one list
///
/// Every row names its [GiftDirection] and **the two are not the same
/// object**. A `sent` row is the buyer's own receipt: the full gift
/// payload, byte for byte what `GET /api/gifts` returns, with its
/// `share_url` and whether it has been claimed. A `received` row is
/// deliberately narrower — what was credited, who it came from, the
/// note. What the buyer paid, the code they used and the token are the
/// BUYER's, and the server will never put them on a received row.
///
/// So this parses into a sealed [GiftHistoryEntry] rather than one
/// model with half its fields null: the compiler is then what stops a
/// screen reading `share_url` off a gift somebody else bought.
///
/// ## The totals do not follow the filter
///
/// `?direction=received` narrows the LIST and leaves [totals] alone —
/// which is what lets both sides be labelled before either is opened.
@immutable
class GiftHistory {
  const GiftHistory({
    this.totals = const GiftTotals(),
    this.gifts = const <GiftHistoryEntry>[],
  });

  /// HAND-WRITTEN, not generated. The rows are a SEALED union and
  /// json_serializable cannot write a `toJson` for one — and nothing
  /// ever sends this shape back, so the generated half would be a
  /// method that exists to fail.
  factory GiftHistory.fromJson(Map<String, dynamic> json) => GiftHistory(
    totals: switch (json['totals']) {
      final Map<String, dynamic> totals => GiftTotals.fromJson(totals),
      _ => const GiftTotals(),
    },
    gifts: [
      // PAGINATED OR NOT. Without `per_page` this is a plain list;
      // with it, Laravel's paginator object with the rows under
      // `data`. The app asks for the whole list, and reading both
      // shapes costs one line.
      for (final row in switch (json['gifts']) {
        final List<dynamic> rows => rows,
        final Map<String, dynamic> page => page['data'] as List<dynamic>? ?? const [],
        _ => const <dynamic>[],
      })
        if (row is Map<String, dynamic>) GiftHistoryEntry.fromJson(row),
    ],
  );

  final GiftTotals totals;

  /// Newest first — the server orders by id descending, because a gift
  /// bought and claimed in the same second ties on the timestamp.
  final List<GiftHistoryEntry> gifts;

  bool get isEmpty => gifts.isEmpty;
}

/// The counts and sums over the WHOLE history, never the filtered view.
@freezed
abstract class GiftTotals with _$GiftTotals {
  const factory GiftTotals({
    /// Every gift bought, INCLUDING unpaid and abandoned ones.
    @JsonKey(name: 'sent_count') @Default(0) int sentCount,

    /// Sum of `total_price` over PAID purchases only — a hold that
    /// lapsed is not money anybody spent. A decimal STRING.
    @JsonKey(name: 'sent_total_paid') @Default('0.00') String sentTotalPaid,

    @JsonKey(name: 'received_count') @Default(0) int receivedCount,

    /// Sum of the `amount` credited. A decimal STRING.
    @JsonKey(name: 'received_total') @Default('0.00') String receivedTotal,
  }) = _GiftTotals;

  factory GiftTotals.fromJson(Map<String, dynamic> json) =>
      _$GiftTotalsFromJson(json);
}

/// One row of the history — see [GiftHistory] for why this is sealed.
sealed class GiftHistoryEntry {
  const GiftHistoryEntry();

  factory GiftHistoryEntry.fromJson(Map<String, dynamic> json) =>
      switch (GiftDirection.fromWire(json['direction'] as String?)) {
        GiftDirection.received => ReceivedGift.fromJson(json),
        GiftDirection.sent => SentGift(Gift.fromJson(json)),
      };

  GiftDirection get direction;

  /// What the row is worth, from whichever side. A decimal STRING.
  String get amount;

  /// Newest first is the server's order; this is what a row prints.
  DateTime get createdAt;
}

/// A gift the reader BOUGHT — their own receipt, whole.
final class SentGift extends GiftHistoryEntry {
  const SentGift(this.gift);

  final Gift gift;

  @override
  GiftDirection get direction => GiftDirection.sent;

  @override
  String get amount => gift.amount;

  @override
  DateTime get createdAt => gift.createdAt;
}

/// A gift the reader CLAIMED.
///
/// Narrower on purpose: no `total_price`, no `discount_code`, no
/// `token`, no `share_url`. Those are the buyer's, and asking for them
/// here is asking for something that will never arrive.
final class ReceivedGift extends GiftHistoryEntry {
  const ReceivedGift({
    required this.id,
    required this.amount,
    required this.createdAt,
    this.message,
    this.from,
    this.redeemedAt,
  });

  factory ReceivedGift.fromJson(Map<String, dynamic> json) => ReceivedGift(
    id: (json['id'] as num?)?.toInt() ?? 0,
    amount: json['amount'] as String? ?? '0.00',
    message: json['message'] as String?,
    // The purchaser's name. NULLABLE — the spec says so outright.
    from: json['from'] as String?,
    redeemedAt: DateTime.tryParse(json['redeemed_at'] as String? ?? ''),
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  final int id;

  @override
  final String amount;

  final String? message;

  /// Who bought it, or null when the server does not say.
  final String? from;

  final DateTime? redeemedAt;

  @override
  final DateTime createdAt;

  @override
  GiftDirection get direction => GiftDirection.received;
}
