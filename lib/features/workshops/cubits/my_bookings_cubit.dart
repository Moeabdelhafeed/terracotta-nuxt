import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/api/envelope_list.dart';
import '../../../data/models/terracotta/booking/booking.dart';
import '../../_shared/locale_scoped_load.dart';

typedef BookingsFetch =
    AsyncResult<EnvelopeList<Booking>> Function({
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «ورشاتي» — the caller's own bookings.
///
/// `GET /api/workshops/bookings`, unpaginated: the paginated sibling
/// returns the raw Laravel paginator as a map, and this screen is a
/// history short enough to arrive whole.
///
/// **[LocaleScopedLoad], because `workshop_title` is written by the
/// server.** A booking's own figures are decimal strings that read the
/// same in both languages, but the workshop's NAME is not — so a
/// language switch has to re-ask, exactly like the catalogue beside it.
///
/// **A `getIt` SINGLETON**, like every other tab cubit: «ورشاتي» lives
/// on the workshops tab, which is a top-level route, and `context.go`
/// tears its `State` down — a page-owned cubit would re-request on
/// every visit. The page must not close it.
///
/// **Needs a session.** A guest gets 401, so the page asks only when
/// there is an account; [signedOut] is what it says instead.
@immutable
class MyBookingsState {
  const MyBookingsState({
    this.bookings = const [],
    this.statusCounts = const {},
    this.loading = false,
    this.signedOut = false,
    this.error,
  });

  final List<Booking> bookings;

  /// `meta.status_counts` — how many bookings the customer has of each
  /// status, ACROSS THEIR WHOLE HISTORY.
  ///
  /// The server's own tally rather than one counted off [bookings], and
  /// the difference matters the day this list paginates: the numbers on
  /// the filter chips must not shrink to "how many are loaded". Empty
  /// when the server sent no `meta` — the chips then fall back to
  /// counting the rows, which is right for exactly the case where
  /// every row is present.
  final Map<String, int> statusCounts;

  /// The FIRST load, which has nothing to show.
  final bool loading;

  /// There is no account, so there is nothing to ask for. Told apart
  /// from an empty history: the two are different sentences and only
  /// one of them has a way forward.
  final bool signedOut;

  final AppException? error;

  bool get hasData => bookings.isNotEmpty;

  MyBookingsState copyWith({
    List<Booking>? bookings,
    Map<String, int>? statusCounts,
    bool? loading,
    bool? signedOut,
    AppException? error,
    bool clearError = false,
  }) => MyBookingsState(
    bookings: bookings ?? this.bookings,
    statusCounts: statusCounts ?? this.statusCounts,
    loading: loading ?? this.loading,
    signedOut: signedOut ?? this.signedOut,
    error: clearError ? null : error ?? this.error,
  );
}

class MyBookingsCubit extends Cubit<MyBookingsState> with LocaleScopedLoad {
  MyBookingsCubit({BookingsFetch? fetch})
    : _fetch = fetch ?? WorkshopApis.listBookings,
      super(const MyBookingsState());

  final BookingsFetch _fetch;
  final _cancel = CancelToken();

  /// Whether there are rows on screen to keep.
  ///
  /// A history that came back EMPTY is still an answer, so this is not
  /// `bookings.isNotEmpty` — otherwise a customer with no bookings
  /// re-asked the server on every visit to the tab.
  @override
  bool get hasData => _answered;
  bool _answered = false;

  @override
  Future<void> load() async {
    emit(state.copyWith(loading: true, signedOut: false, clearError: true));

    switch (await _fetch(cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        _answered = true;
        emit(
          state.copyWith(
            bookings: value.items,
            statusCounts: value.intMap('status_counts'),
            loading: false,
          ),
        );
      case Failure(:final error):
        if (isClosed) return;
        // What is on screen STAYS. A failed refresh is not a reason to
        // blank a list the customer was reading.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// A pull, or the language changing. Unconditional.
  Future<void> refresh(String locale) => refreshIn(locale);

  /// Signed out: there is nothing to ask for, and nothing to keep from
  /// whoever was signed in before.
  void clear() {
    _answered = false;
    emit(const MyBookingsState(signedOut: true));
  }

  @override
  Future<void> close() {
    _cancel.cancel('my bookings closed');
    return super.close();
  }
}
