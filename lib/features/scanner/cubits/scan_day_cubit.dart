import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/scan_apis.dart';
import '../../../data/models/terracotta/scan/scan_result.dart';
import '../../../data/models/terracotta/scan/scan_session.dart';

typedef ScanSessionsFetch =
    AsyncResult<ScanDay> Function({
      String? date,
      CancelToken? cancelToken,
      Duration? timeout,
    });

class ScanDayState {
  const ScanDayState({
    this.day,
    this.date,
    this.loading = true,
    this.working = false,
    this.error,
  });

  final ScanDay? day;

  /// `Y-m-d` being shown. Null means today, as the server reads it.
  final String? date;

  final bool loading;

  /// A check-in, a start or a finish is in flight.
  final bool working;

  final AppException? error;

  List<ScanSession> get sessions => day?.sessions ?? const [];
  bool get hasData => day != null;

  ScanDayState copyWith({
    ScanDay? day,
    String? date,
    bool? loading,
    bool? working,
    AppException? error,
    bool clearError = false,
  }) => ScanDayState(
    day: day ?? this.day,
    date: date ?? this.date,
    loading: loading ?? this.loading,
    working: working ?? this.working,
    error: clearError ? null : error ?? this.error,
  );
}

/// The desk's day.
///
/// One cubit for the whole screen, because the day IS the screen: the
/// sessions, who is on them and how many have arrived all come from
/// the same request, and every action the desk takes changes that same
/// answer. Re-reading it after each one is both simplest and correct —
/// the counts move for reasons other than this device.
class ScanDayCubit extends Cubit<ScanDayState> {
  ScanDayCubit({ScanSessionsFetch? fetch})
    : _fetch = fetch ?? ScanApis.sessions,
      super(const ScanDayState());

  final ScanSessionsFetch _fetch;
  final _cancel = CancelToken();

  /// The day the desk is looking at, `Y-m-d`.
  ///
  /// The SERVER's answer where there is one — it decides what "today"
  /// means, on the studio's clock rather than this device's.
  String get shownDate => state.day?.date ?? state.date ?? _deviceToday();

  /// Whether that day is today, which is the only day Start and Finish
  /// work on. The server refuses any other with a 422 keyed
  /// `booking_date`, so the controls are not offered at all.
  bool get isToday {
    final shown = state.date;
    // Null means "no date asked for", which is today by definition.
    return shown == null || shown == _deviceToday();
  }

  /// Steps the day by [days] and re-reads.
  Future<void> shiftDay(int days) {
    final at = DateTime.tryParse(shownDate);
    if (at == null) return load();
    return load(date: _iso(at.add(Duration(days: days))));
  }

  /// Back to the day the desk actually works on.
  Future<void> goToToday() => load(date: _deviceToday());

  /// This device's date, as a fallback for stepping. The SERVER's
  /// `date` is preferred everywhere it exists — the studio's clock is
  /// the one the sessions run on.
  static String _deviceToday() => _iso(DateTime.now());

  static String _iso(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  Future<void> load({String? date}) async {
    // THE LIST IS EMPTIED when the day changes, and kept when it does
    // not.
    //
    // A refresh of the same day should leave what is on screen alone —
    // a desk mid-session must not watch its queue blink. But stepping
    // to another day and leaving yesterday's sessions up, under
    // tomorrow's date, is worse than showing nothing: the desk would
    // read a list that belongs to a different day.
    final changed = date != null && date != state.date;
    emit(
      ScanDayState(
        day: changed ? null : state.day,
        date: date ?? state.date,
        loading: true,
      ),
    );

    switch (await _fetch(date: date ?? state.date, cancelToken: _cancel)) {
      case Success(:final value):
        if (isClosed) return;
        emit(state.copyWith(day: value, loading: false));
      case Failure(:final error):
        if (isClosed) return;
        // The day already on screen STAYS. A desk mid-session should
        // not lose its list because one refresh failed.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// Scans a code. Answers what the server made of it, or null when
  /// the call itself failed.
  ///
  /// **Does not re-read the day when the answer is `needs_count`** —
  /// nothing was written, and the desk is about to scan again with a
  /// headcount.
  Future<ScanResult?> checkIn(String code, {int? count}) async {
    if (state.working) return null;
    emit(state.copyWith(working: true, clearError: true));

    final result = await ScanApis.checkIn(
      code: code,
      checkedInCount: count,
      cancelToken: _cancel,
    );
    if (isClosed) return null;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(working: false));
        if (!value.needsCount) await load();
        return value;
      case Failure(:final error):
        emit(state.copyWith(working: false, error: error));
        return null;
    }
  }

  /// Starts a session — and marks everyone unscanned absent.
  Future<bool> start(ScanSession session) =>
      _move(session, ScanApis.startSession);

  /// Finishes it.
  Future<bool> finish(ScanSession session) =>
      _move(session, ScanApis.finishSession);

  Future<bool> _move(
    ScanSession session,
    AsyncResult<Map<String, dynamic>> Function({
      required int workshopId,
      required int workshopSlotId,
      required String bookingDate,
      CancelToken? cancelToken,
      Duration? timeout,
    })
    call,
  ) async {
    if (state.working) return false;
    emit(state.copyWith(working: true, clearError: true));

    final result = await call(
      workshopId: session.workshopId,
      workshopSlotId: session.workshopSlotId,
      // The DAY ON SCREEN. The server refuses any date but today, and
      // sending the device's own date would disagree with the list the
      // desk is looking at.
      bookingDate: state.day?.date ?? state.date ?? '',
      cancelToken: _cancel,
    );
    if (isClosed) return false;

    switch (result) {
      case Success():
        emit(state.copyWith(working: false));
        await load();
        return true;
      case Failure(:final error):
        emit(state.copyWith(working: false, error: error));
        return false;
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel('scan day closed');
    return super.close();
  }
}
