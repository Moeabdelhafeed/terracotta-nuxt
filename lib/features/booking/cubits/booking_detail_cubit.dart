import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/booking/booking.dart';

typedef BookingFetch =
    AsyncResult<Booking> Function(
      String bookingId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef BookingCancel =
    AsyncResult<Map<String, dynamic>> Function(
      String bookingId, {
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef BookingReschedule =
    AsyncResult<Booking> Function(
      String bookingId, {
      required int workshopSlotId,
      required String bookingDate,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef BookingDeliveryChoice =
    AsyncResult<Booking> Function(
      String bookingId, {
      required String method,
      int? addressId,
      double? lat,
      double? lng,
      String? phone,
      bool? useWallet,
      String? address,
      CancelToken? cancelToken,
      Duration? timeout,
    });

/// «تفاصيل الحجز» — one booking, as the server has it.
///
/// ## What this replaced
///
/// The screen read `MyBookingSample.byId()`. Every frame the design
/// draws could be looked at, and nothing on it was real: the code
/// under the QR belonged to a fixture, «الغاء» opened a dialog that
/// confirmed nothing, and «تغيير الموعد» opened a sheet that picked a
/// slot and threw it away. The page looked finished and did nothing.
///
/// ## The server decides what may be done to a booking
///
/// [Booking.canCancel] and [Booking.canEdit] are the authority — not
/// the status, and not `editable_until`, which the model's own doc
/// says outright. A booking inside its cancellation window answers
/// true; one whose window has passed answers false, and the buttons
/// are not drawn at all rather than drawn to fail.
class BookingDetailState {
  const BookingDetailState({
    this.booking,
    this.loading = true,
    this.working = false,
    this.error,
  });

  /// The server's row. Null before the first answer.
  final Booking? booking;

  /// The FIRST load, which has nothing to show.
  final bool loading;

  /// A cancel or a reschedule is in flight — one press to the
  /// customer, and the page must not offer it twice.
  final bool working;

  final AppException? error;

  BookingDetailState copyWith({
    Booking? booking,
    bool? loading,
    bool? working,
    AppException? error,
    bool clearError = false,
  }) => BookingDetailState(
    booking: booking ?? this.booking,
    loading: loading ?? this.loading,
    working: working ?? this.working,
    error: clearError ? null : error ?? this.error,
  );
}

class BookingDetailCubit extends Cubit<BookingDetailState> {
  BookingDetailCubit({
    required this.bookingId,
    BookingFetch? fetch,
    BookingCancel? cancel,
    BookingReschedule? reschedule,
    BookingDeliveryChoice? chooseDelivery,
  }) : _fetch = fetch ?? WorkshopApis.getBooking,
       _cancel = cancel ?? WorkshopApis.cancelBooking,
       _reschedule = reschedule ?? WorkshopApis.rescheduleBooking,
       _chooseDelivery = chooseDelivery ?? WorkshopApis.chooseDelivery,
       super(const BookingDetailState());

  final String bookingId;
  final BookingFetch _fetch;
  final BookingCancel _cancel;
  final BookingReschedule _reschedule;
  final BookingDeliveryChoice _chooseDelivery;
  final _cancelToken = CancelToken();

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    switch (await _fetch(bookingId, cancelToken: _cancelToken)) {
      case Success(:final value):
        if (isClosed) return;
        emit(state.copyWith(booking: value, loading: false));
      case Failure(:final error):
        if (isClosed) return;
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// Call it off. Answers whether the server agreed.
  ///
  /// The booking is RE-READ rather than patched here: cancelling
  /// refunds seats to the wallet and moves the status, and the row
  /// that comes back is the one that says so.
  Future<bool> cancel() async {
    if (state.working) return false;
    emit(state.copyWith(working: true, clearError: true));

    switch (await _cancel(bookingId, cancelToken: _cancelToken)) {
      case Success():
        if (isClosed) return false;
        emit(state.copyWith(working: false));
        await load();
        return true;
      case Failure(:final error):
        if (isClosed) return false;
        emit(state.copyWith(working: false, error: error));
        return false;
    }
  }

  /// «ستستلمها بنفسك» — the customer will collect the piece.
  ///
  /// **This is a WRITE, not a local flag.** The page used to set its
  /// own field and stop, so a customer who chose to collect had told
  /// nobody but their own screen and the studio went on preparing a
  /// delivery. `pickup` is the whole body; there is no separate pay
  /// step for it.
  ///
  /// Switching also credits whatever delivery took from the wallet and
  /// drops that fee's VAT off the booking, so the answer replaces the
  /// row rather than patching it.
  Future<bool> choosePickup() async {
    if (state.working) return false;
    emit(state.copyWith(working: true, clearError: true));

    final result = await _chooseDelivery(
      bookingId,
      method: 'pickup',
      cancelToken: _cancelToken,
    );
    if (isClosed) return false;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(booking: value, working: false));
        return true;
      case Failure(:final error):
        emit(state.copyWith(working: false, error: error));
        return false;
    }
  }

  /// A different day, or a different session on the same day.
  Future<bool> reschedule({
    required int workshopSlotId,
    required String bookingDate,
  }) async {
    if (state.working) return false;
    emit(state.copyWith(working: true, clearError: true));

    final result = await _reschedule(
      bookingId,
      workshopSlotId: workshopSlotId,
      bookingDate: bookingDate,
      cancelToken: _cancelToken,
    );
    if (isClosed) return false;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(booking: value, working: false));
        return true;
      case Failure(:final error):
        emit(state.copyWith(working: false, error: error));
        return false;
    }
  }

  @override
  Future<void> close() {
    _cancelToken.cancel('booking detail closed');
    return super.close();
  }
}
