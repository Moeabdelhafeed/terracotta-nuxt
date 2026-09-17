import 'package:dio/dio.dart';

import '../../../core/types/result.dart';
import '../../models/terracotta/scan/scan_result.dart';
import '../../models/terracotta/scan/scan_session.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// The FRONT DESK's four calls.
///
/// ## A different app behind the same sign-in
///
/// `/api/login` answers `is_scanner: true` for a staff account, and
/// these routes sit behind `role:scanner` — the customer routes behind
/// `role:user`. The two are mutually exclusive: a scanner calling the
/// shop gets 403 and a customer calling these gets 403. So the token
/// decides which app the reader is in, and there is no mode to pick.
///
/// ## What the desk actually does, in order
///
/// Open the day ([sessions]), scan people in as they arrive
/// ([checkIn]), press Start when the session begins ([startSession] —
/// which marks everyone unscanned ABSENT and is not undoable), then
/// Finish at the end ([finishSession]).
class ScanApis {
  const ScanApis._();

  static ApiLogConfig logSessions = kApiLogVerbose;
  static ApiLogConfig logCheckIn = kApiLogVerbose;
  static ApiLogConfig logSession = kApiLogVerbose;

  /// The desk's day. Defaults to today when [date] is null.
  ///
  /// Built from the BOOKINGS, so a session nobody booked does not
  /// appear — there is nobody to check in.
  static AsyncResult<ScanDay> sessions({
    String? date,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<ScanDay>(
      TerracottaEndpoints.scanSessions,
      queryParameters: {if (date != null) 'date': date},
      fromJson: ScanDay.fromJson,
      logRequest: logSessions.request,
      logResponse: logSessions.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Checks a booking in from its code.
  ///
  /// [code] is the eight digits OR the booking's `qr_token` — the
  /// server accepts either, which is why a typed code and a scanned
  /// one go through the same call.
  ///
  /// **Leave [checkedInCount] null on the first scan.** A party of one
  /// checks straight in; a bigger party comes back `needs_count: true`
  /// having written NOTHING, and the desk scans again with the real
  /// headcount. See [ScanResult].
  ///
  /// Refusals: 404 for a code that matches nothing, 422 keyed `code`
  /// for a booking that is not checkinable (wrong day, cancelled,
  /// already past this stage), 422 keyed `checked_in_count` when the
  /// number is larger than the party.
  static AsyncResult<ScanResult> checkIn({
    required String code,
    int? checkedInCount,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<ScanResult>(
      TerracottaEndpoints.scanCheckIn,
      data: {
        'code': code,
        if (checkedInCount != null) 'checked_in_count': checkedInCount,
      },
      fromJson: ScanResult.fromJson,
      logRequest: logCheckIn.request,
      logResponse: logCheckIn.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Starts the session: everyone checked in becomes `attending` and
  /// **everyone who is not becomes `absent`**.
  ///
  /// Not undoable from here, and no money moves — a no-show is never
  /// refunded. A late arrival can still be scanned afterwards and is
  /// admitted.
  ///
  /// 422 keyed `booking_date` on any date but today: a session can only
  /// be started on the day it runs.
  static AsyncResult<Map<String, dynamic>> startSession({
    required int workshopId,
    required int workshopSlotId,
    required String bookingDate,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => _session(
    TerracottaEndpoints.scanSessionStart,
    workshopId: workshopId,
    workshopSlotId: workshopSlotId,
    bookingDate: bookingDate,
    cancelToken: cancelToken,
    timeout: timeout,
  );

  /// Finishes it: everyone attending moves on — to `preparing`, or
  /// straight to `completed` for a workshop the customer takes home
  /// the same day. No-shows stay as they are.
  static AsyncResult<Map<String, dynamic>> finishSession({
    required int workshopId,
    required int workshopSlotId,
    required String bookingDate,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => _session(
    TerracottaEndpoints.scanSessionFinish,
    workshopId: workshopId,
    workshopSlotId: workshopSlotId,
    bookingDate: bookingDate,
    cancelToken: cancelToken,
    timeout: timeout,
  );

  /// Both session calls take the same three fields and answer
  /// `data: null`, so they differ only by path.
  static AsyncResult<Map<String, dynamic>> _session(
    String path, {
    required int workshopId,
    required int workshopSlotId,
    required String bookingDate,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      path,
      data: {
        'workshop_id': workshopId,
        'workshop_slot_id': workshopSlotId,
        'booking_date': bookingDate,
      },
      fromJson: (json) => json,
      logRequest: logSession.request,
      logResponse: logSession.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
