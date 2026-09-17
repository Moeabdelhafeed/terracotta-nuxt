// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'home_banner.dart';
import 'home_category.dart';
import 'home_product_card.dart';

part 'home_payload.freezed.dart';
part 'home_payload.g.dart';

/// The whole of `GET /api/home` — every rail the landing screen draws,
/// in one round trip.
///
/// Five keys, all present in the live capture: [banners] (10),
/// [categories] (4), [currentBooking] (null), [featuredProducts] (4) and
/// [offers] (5). The screen is a vertical stack of these; render each
/// section only when its list is non-empty rather than reserving space
/// for a rail the CMS emptied.
///
/// **[featuredProducts] and [offers] are the same shape and they
/// overlap** — two products appear in both. See [HomeProductCard]; they
/// are two editorial rails, not a partition.
///
/// **[currentBooking] is `null` in every capture and its shape is
/// therefore UNVERIFIED**, which is why it is a raw map rather than a
/// model. Nothing in the samples shows a populated one — not the
/// bookings list, not the booking detail, both of which are their own
/// endpoints with their own shapes. Typing it as a guessed model would
/// throw at parse time for the first user who actually has a booking,
/// on the home screen, at launch. Treat it as an "is there one?" flag
/// (see [hasCurrentBooking]) and fetch the real booking from the
/// bookings endpoint; replace this with a proper model only once a
/// capture with a live booking exists.
@freezed
abstract class HomePayload with _$HomePayload {
  const factory HomePayload({
    /// Hero carousel. 10 in the capture, each with its own link type.
    required List<HomeBanner> banners,

    /// Shop category tiles. 4 in the capture.
    required List<HomeCategory> categories,

    /// The user's in-progress booking, if any. **Shape unverified —
    /// null in every capture.** See the class doc before typing it.
    Map<String, dynamic>? currentBooking,

    /// Editorial "featured" rail. Overlaps [offers].
    required List<HomeProductCard> featuredProducts,

    /// Discounted products rail. Overlaps [featuredProducts]. Every
    /// entry in the capture has a non-null `sale_price`, but the shape
    /// permits null — do not assume a discount is present.
    required List<HomeProductCard> offers,
  }) = _HomePayload;

  const HomePayload._();

  factory HomePayload.fromJson(Map<String, dynamic> json) =>
      _$HomePayloadFromJson(json);

  /// Whether the home screen should show the "resume your booking"
  /// strip. The only safe question to ask of [currentBooking] until its
  /// shape is captured.
  bool get hasCurrentBooking =>
      currentBooking != null && currentBooking!.isNotEmpty;
}
