import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/workshop/availability_calendar.dart';
import '../../../data/models/terracotta/workshop/workshop_slot.dart';
import 'booking_schedule_state.dart';

typedef CalendarFetch =
    AsyncResult<AvailabilityCalendar> Function(
      String workshopId, {
      int? days,
      int? peopleCount,
      CancelToken? cancelToken,
    });

typedef SlotsFetch =
    AsyncResult<List<WorkshopSlot>> Function(
      String workshopId, {
      required String date,
      int? peopleCount,
      CancelToken? cancelToken,
    });

/// Choosing when to come.
///
/// Two endpoints, one of them twice:
///
///   * `GET /api/workshops/{id}/availability` with NO `date` answers the
///     calendar — `max_available_seats` and the `blocked_dates` to grey
///     out. It takes `people_count`, and the answer CHANGES with it: a
///     day with two seats left is open to a pair and blocked to a trio.
///     So changing the party size re-asks.
///   * the same path WITH `date` answers that day's sessions.
class BookingScheduleCubit extends Cubit<BookingScheduleState> {
  BookingScheduleCubit({
    required this.workshopId,
    this.maxPeoplePerBooking = 1,
    int initialPeople = 1,
    CalendarFetch? calendar,
    SlotsFetch? slots,
  }) : _calendar = calendar ?? WorkshopApis.getAvailabilityCalendar,
       _slots = slots ?? _defaultSlots,
       // THE PARTY THE CALLER ALREADY KNOWS ABOUT, which «لوّن قطعتك»
       // does — see `BookingScheduleArgs.people`. The first calendar
       // is asked FOR that many, so the blocked days are the ones
       // blocked for them rather than for a party of one, and
       // `_loadCalendar` clamps it down if the workshop cannot take
       // them.
       super(
         BookingScheduleState(
           people: initialPeople < 1 ? 1 : initialPeople,
           maxPeople: maxPeoplePerBooking < 1 ? 1 : maxPeoplePerBooking,
         ),
       );

  final String workshopId;

  /// The workshop's own ceiling, from the catalogue row the tab already
  /// had. The calendar's own number can be LOWER — see
  /// `BookingScheduleState.maxPeople`.
  final int maxPeoplePerBooking;

  final CalendarFetch _calendar;
  final SlotsFetch _slots;
  final _cancel = CancelToken();

  /// How far ahead the date strip runs.
  static const days = 14;

  static AsyncResult<List<WorkshopSlot>> _defaultSlots(
    String workshopId, {
    required String date,
    int? peopleCount,
    CancelToken? cancelToken,
  }) => WorkshopApis.getAvailability(
    workshopId,
    date: date,
    peopleCount: peopleCount,
    cancelToken: cancelToken,
  );

  /// Whether the calendar has ever answered. What separates the FIRST
  /// load, which has nothing to show, from a re-ask, which does.
  bool _hasCalendar = false;

  Future<void> load() => _loadCalendar(state.people);

  Future<void> _loadCalendar(int people) async {
    // Placeholders only when there is NOTHING to keep.
    //
    // Changing the party size re-asks the calendar, and blanking both
    // strips while it answers emptied the page under the customer's
    // finger — they tapped a number and the number disappeared. The
    // strips stay; only the blocked days change.
    emit(
      state.copyWith(loadingCalendar: !_hasCalendar, clearError: true),
    );

    final result = await _calendar(
      workshopId,
      days: days,
      peopleCount: people,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        _hasCalendar = true;
        // The LOWER of the two ceilings. A workshop that seats eight
        // with three left offers one, two and three — offering eight
        // and refusing at checkout is the version that wastes the
        // customer's time.
        final ceiling = value.maxAvailableSeats < maxPeoplePerBooking
            ? value.maxAvailableSeats
            : maxPeoplePerBooking;

        emit(
          state.copyWith(
            maxPeople: ceiling < 1 ? 0 : ceiling,
            // A party bigger than what is left is not a choice any more.
            people: people > ceiling && ceiling >= 1 ? ceiling : people,
            blockedDates: value.blockedDates.toSet(),
            loadingCalendar: false,
          ),
        );
      case Failure(:final error):
        emit(state.copyWith(loadingCalendar: false, error: error));
    }
  }

  /// A different party size re-asks the calendar: the blocked days are
  /// computed FOR that many people.
  Future<void> selectPeople(int people) async {
    if (people == state.people) return;
    emit(state.copyWith(people: people, clearSlot: true, slots: const []));
    await _loadCalendar(people);

    // The day already chosen may not take the new party.
    final date = state.date;
    if (date != null && !state.blockedDates.contains(date)) {
      await selectDate(date, force: true);
    } else if (date != null) {
      emit(state.copyWith(date: null, slots: const [], clearSlot: true));
    }
  }

  Future<void> selectDate(String date, {bool force = false}) async {
    if (!force && date == state.date) return;
    if (state.blockedDates.contains(date)) return;

    emit(
      state.copyWith(
        date: date,
        // The ids are PER DAY. Keeping one across a change of date
        // would book a different session from the one on screen.
        clearSlot: true,
        slots: const [],
        loadingSlots: true,
        clearError: true,
      ),
    );

    final result = await _slots(
      workshopId,
      date: date,
      peopleCount: state.people,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(slots: value, loadingSlots: false));
      case Failure(:final error):
        emit(state.copyWith(loadingSlots: false, error: error));
    }
  }

  void selectSlot(WorkshopSlot slot) {
    if (!canTake(slot, state.people)) return;
    emit(state.copyWith(selectedSlotId: slot.workshopSlotId));
  }

  /// Whether this session can take a party of [people].
  ///
  /// Three ways it cannot, and all three are drawn the same because all
  /// three end in a refusal:
  ///
  ///   * `is_full` — no seats at all.
  ///   * `has_conflict` — the customer already holds an overlapping
  ///     booking, and booking anyway answers 422 keyed to
  ///     `workshop_slot_id`.
  ///   * FEWER SEATS THAN THE PARTY. Two left cannot take three, and
  ///     `remaining` is on every row — so the screen can say so rather
  ///     than letting the customer find out at checkout.
  static bool canTake(WorkshopSlot slot, int people) {
    if (slot.isFull ?? false) return false;
    if (slot.hasConflict ?? false) return false;
    final left = slot.remaining;
    if (left != null && left < people) return false;
    return true;
  }

  @override
  Future<void> close() {
    _cancel.cancel('schedule closed');
    return super.close();
  }
}
