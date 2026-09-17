import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/shop_apis.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/api/envelope_list.dart';
import '../../../data/models/terracotta/booking/booking.dart';
import '../../../data/models/terracotta/booking/booking_status.dart';
import '../../../data/models/terracotta/commerce/order.dart';
import '../../_shared/locale_scoped_load.dart';

typedef LiveOrdersFetch =
    AsyncResult<List<Order>> Function({
      int? perPage,
      int? page,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef LiveBookingsFetch =
    AsyncResult<EnvelopeList<Booking>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// What is true RIGHT NOW — the two strips at the top of the home,
/// workshops and shop pages.
///
/// **`GET /api/home` answers neither of them.** Its `current_booking`
/// is the "continue your workshop" card further down the home page,
/// and that is a different question: it is the NEXT booking, this is
/// the session the customer is sitting in. So both are asked for
/// separately:
///
///   * the order → `GET /api/shop/orders`, the newest row the studio
///     has not finished with
///   * the workshop → `GET /api/workshops/bookings`, the row the desk
///     has SCANNED IN. `attending` is the only status that means now;
///     a confirmed booking three days out is not happening, and
///     putting it here would make the strip mean nothing.
///
/// **A `getIt` SINGLETON.** It feeds three TOP-LEVEL routes, and
/// `context.go` tears each of their `State`s down — a page-owned cubit
/// would re-ask on every tab switch, three times over. Pages must not
/// close it.
///
/// **[LocaleScopedLoad], because `workshop_title` is the server's.** The
/// money and the statuses read the same in both languages; the
/// workshop's name does not.
///
/// **Needs a session.** Both routes are the caller's own and answer 401
/// to a guest, so the pages ask only when there is an account and
/// [clear] is what happens when there is not.
@immutable
class LiveNowState {
  const LiveNowState({
    this.order,
    this.booking,
    this.next,
    this.loading = false,
  });

  /// The order worth chasing, or null when there is none.
  final Order? order;

  /// The session the customer is IN, or null.
  final Booking? booking;

  /// The seat already booked and not yet sat in — the soonest one.
  ///
  /// A DIFFERENT question from [booking]: that is the session they are
  /// in right now, this is the one they are coming back for. Both can
  /// be true at once, and the page draws them in that order.
  final Booking? next;

  final bool loading;

  /// Whether any strip has anything to draw.
  bool get hasAny => order != null || booking != null || next != null;

  LiveNowState copyWith({
    Order? order,
    Booking? booking,
    Booking? next,
    bool? loading,
    bool clearOrder = false,
    bool clearBooking = false,
    bool clearNext = false,
  }) => LiveNowState(
    order: clearOrder ? null : order ?? this.order,
    booking: clearBooking ? null : booking ?? this.booking,
    next: clearNext ? null : next ?? this.next,
    loading: loading ?? this.loading,
  );
}

class LiveNowCubit extends Cubit<LiveNowState> with LocaleScopedLoad {
  LiveNowCubit({LiveOrdersFetch? orders, LiveBookingsFetch? bookings})
    : _orders = orders ?? ShopApis.getOrders,
      _bookings = bookings ?? WorkshopApis.listBookings,
      super(const LiveNowState());

  final LiveOrdersFetch _orders;
  final LiveBookingsFetch _bookings;
  final _cancel = CancelToken();

  /// Whether an answer has arrived.
  ///
  /// NOT "is there anything live": nothing live is still an answer, and
  /// reading it as no-data re-asked the server on every tab switch for
  /// the customers who have neither — which is most of them.
  @override
  bool get hasData => _answered;
  bool _answered = false;

  @override
  Future<void> load() async {
    emit(state.copyWith(loading: true));

    // Both at once, and each awaited with its own type. Neither
    // failure is worth a word on screen: these strips are extra, and a
    // home page that shouts because an optional row did not arrive is
    // worse than one that simply does not show it.
    final asking = _orders(cancelToken: _cancel);
    final booking = _bookings(cancelToken: _cancel);

    final orders = await asking;
    final bookings = await booking;
    if (isClosed) return;

    _answered = true;
    emit(
      LiveNowState(
        order: switch (orders) {
          Success(:final value) => liveOrder(value),
          Failure() => null,
        },
        booking: switch (bookings) {
          Success(:final value) => attending(value.items),
          Failure() => null,
        },
        next: switch (bookings) {
          Success(:final value) => upcoming(value.items),
          Failure() => null,
        },
      ),
    );
  }

  Future<void> refresh(String locale) => refreshIn(locale);

  /// Signed out: nothing to ask for, and nothing to keep from whoever
  /// was signed in before.
  void clear() {
    _answered = false;
    emit(const LiveNowState());
  }

  /// The order the studio has not finished with.
  ///
  /// `completed` and `cancelled` are done, and an order awaiting
  /// payment IS worth chasing — it is the one with a clock on it.
  ///
  /// PUBLIC and pure: which row is "live" is the whole question this
  /// cubit answers, and it is worth asserting without a server.
  static Order? liveOrder(List<Order> orders) {
    for (final order in orders) {
      if (!order.status.isTerminal) return order;
    }
    return null;
  }

  /// The booking the desk has scanned in.
  ///
  /// `attending` is the ONLY status that means now. A confirmed
  /// booking three days out is not happening, and showing it here
  /// would make the strip mean nothing.
  static Booking? attending(List<Booking> bookings) {
    for (final booking in bookings) {
      if (booking.statusEnum == BookingStatus.attending) return booking;
    }
    return null;
  }

  /// The soonest seat still to be sat in.
  ///
  /// `GET /api/home` carries a `current_booking` and this deliberately
  /// does NOT read it: that key is unmodelled — no capture has ever
  /// contained one — and it answers only the home page, while the same
  /// row belongs above the workshops page too. The bookings list is
  /// already being fetched for [attending], so this is the same answer
  /// asked twice rather than a second request.
  ///
  /// **Not the one they are IN.** `attending` has its own strip, and a
  /// booking cannot be both the session happening now and the one
  /// still to come. Everything past — absent, preparing, completed,
  /// cancelled — is behind them; `pending_payment` is a held seat that
  /// is not theirs yet.
  ///
  /// Sorted by the DAY then the clock, both as the server wrote them:
  /// `booking_date` is `Y-m-d` and `start_time` is `HH:mm`, so the
  /// strings sort in the order the values do and nothing is parsed
  /// into a `DateTime` that would need a timezone. Times are already
  /// Asia/Riyadh.
  static Booking? upcoming(List<Booking> bookings) {
    Booking? soonest;
    for (final booking in bookings) {
      if (booking.statusEnum != BookingStatus.confirmed) continue;
      if (soonest == null || _when(booking).compareTo(_when(soonest)) < 0) {
        soonest = booking;
      }
    }
    return soonest;
  }

  static String _when(Booking booking) =>
      '${booking.bookingDate} ${booking.startTime}';

  @override
  Future<void> close() {
    _cancel.cancel('live now closed');
    return super.close();
  }
}
