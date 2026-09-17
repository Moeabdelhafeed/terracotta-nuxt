import '../../../generated/l10n.dart';
import '../tr.dart';

/// The FRONT DESK's own words.
///
/// A separate namespace because the desk is a different app behind the
/// same sign-in: its reader is staff, not a customer, and its
/// vocabulary is theirs — «حضر ٣ من ٥», «ابدأ الجلسة», «غائب».
abstract final class ScanStrings {
  const ScanStrings._();

  static String get deskTitle =>
      Tr.t('scan_desk_title', S.current.scan_desk_title);

  static String get today => Tr.t('scan_today', S.current.scan_today);

  /// «لا توجد جلسات محجوزة اليوم» — or «في ذلك اليوم» when the desk is
  /// looking at another date.
  ///
  /// The strip above this can move a week either way, and the empty
  /// state said «اليوم» whatever it was showing — so a desk checking
  /// next Tuesday was told nothing was booked TODAY, which is a
  /// different fact and a true one.
  static String noSessions({required bool today}) => today
      ? Tr.t('scan_no_sessions', S.current.scan_no_sessions)
      : Tr.t('scan_no_sessions_day', S.current.scan_no_sessions_day);

  static String noSessionsBody({required bool today}) => today
      ? Tr.t('scan_no_sessions_body', S.current.scan_no_sessions_body)
      : Tr.t(
          'scan_no_sessions_body_day',
          S.current.scan_no_sessions_body_day,
        );

  static String get scanCode =>
      Tr.t('scan_scan_code', S.current.scan_scan_code);

  static String get enterCode =>
      Tr.t('scan_enter_code', S.current.scan_enter_code);

  static String get codeHint =>
      Tr.t('scan_code_hint', S.current.scan_code_hint);

  static String get startSession =>
      Tr.t('scan_start_session', S.current.scan_start_session);

  static String get finishSession =>
      Tr.t('scan_finish_session', S.current.scan_finish_session);

  /// The warning before Start. It is the one irreversible thing the
  /// desk can do — everyone unscanned becomes absent, and a no-show is
  /// never refunded.
  static String get startWarningTitle =>
      Tr.t('scan_start_warning_title', S.current.scan_start_warning_title);

  static String get startWarningBody =>
      Tr.t('scan_start_warning_body', S.current.scan_start_warning_body);

  static String get finishWarningTitle =>
      Tr.t('scan_finish_warning_title', S.current.scan_finish_warning_title);

  static String get finishWarningBody =>
      Tr.t('scan_finish_warning_body', S.current.scan_finish_warning_body);

  // ─── A session that has been finished ─────────────────────
  //
  // Finish CLOSES check-in. Every code scanned against that session
  // then answers 422 whatever the booking's status and whoever is
  // standing at the desk, so the controls come off the screen — a
  // button whose only possible outcome is an error is worse than no
  // button.

  static String get sessionClosed =>
      Tr.t('scan_session_closed', S.current.scan_session_closed);

  static String sessionClosedAt(String time) => Tr.t(
    'scan_session_closed_at',
    S.current.scan_session_closed_at(time),
  );

  static String get checkInClosedBody => Tr.t(
    'scan_check_in_closed_body',
    S.current.scan_check_in_closed_body,
  );

  // ─── Who has not photographed their pieces ────────────────
  //
  // Photos can only be uploaded while a booking is `attending`. Once
  // Finish runs the booking moves on and NO piece can ever be added to
  // it again — so this is the last moment the studio can do anything
  // about it, which is why it hangs off that button and nowhere else.

  static String piecesProgress(String done, String expected) => Tr.t(
    'scan_pieces_progress',
    S.current.scan_pieces_progress(done, expected),
  );

  static String get finishMissingTitle => Tr.t(
    'scan_finish_missing_title',
    S.current.scan_finish_missing_title,
  );

  static String get finishMissingBody => Tr.t(
    'scan_finish_missing_body',
    S.current.scan_finish_missing_body,
  );

  static String get finishAllDone =>
      Tr.t('scan_finish_all_done', S.current.scan_finish_all_done);

  /// One person the desk has to go and find. BY NAME — "3 bookings"
  /// does not tell them who to look for.
  static String missingRow(String name, String done, String expected) => Tr.t(
    'scan_missing_row',
    S.current.scan_missing_row(name, done, expected),
  );

  static String get finishAnyway =>
      Tr.t('scan_finish_anyway', S.current.scan_finish_anyway);

  static String get sessionStarted =>
      Tr.t('scan_session_started', S.current.scan_session_started);

  static String get sessionFinished =>
      Tr.t('scan_session_finished', S.current.scan_session_finished);

  /// «حضر ٣ من ٥» — heads, not bookings.
  static String arrived(String arrived, String total) =>
      Tr.t('scan_arrived', S.current.scan_arrived(arrived, total));

  /// The second phase of a party's check-in. The server wrote NOTHING
  /// and is asking.
  static String get howManyTitle =>
      Tr.t('scan_how_many_title', S.current.scan_how_many_title);

  static String howManyBody(String name, String count) =>
      Tr.t('scan_how_many_body', S.current.scan_how_many_body(name, count));

  static String get confirmCount =>
      Tr.t('scan_confirm_count', S.current.scan_confirm_count);

  static String checkedIn(String name) =>
      Tr.t('scan_checked_in', S.current.scan_checked_in(name));

  static String alreadyIn(String name) =>
      Tr.t('scan_already_in', S.current.scan_already_in(name));

  static String get pointCamera =>
      Tr.t('scan_point_camera', S.current.scan_point_camera);

  static String get cameraDenied =>
      Tr.t('scan_camera_denied', S.current.scan_camera_denied);

  static String get signOut => Tr.t('scan_sign_out', S.current.scan_sign_out);

  /// «٥ من ٨» — booked of capacity.
  static String seats(String booked, String capacity) =>
      Tr.t('scan_seats', S.current.scan_seats(booked, capacity));

  // ─── Looking at another day ───────────────────────────────

  static String get previousDay =>
      Tr.t('scan_previous_day', S.current.scan_previous_day);

  static String get nextDay => Tr.t('scan_next_day', S.current.scan_next_day);

  static String get backToToday =>
      Tr.t('scan_back_to_today', S.current.scan_back_to_today);

  /// Why Start and Finish are missing on any day but this one. The
  /// server refuses them outright — 422 keyed `booking_date`.
  static String get notToday =>
      Tr.t('scan_not_today', S.current.scan_not_today);
}
