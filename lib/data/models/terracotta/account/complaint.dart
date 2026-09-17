// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'complaint.freezed.dart';
part 'complaint.g.dart';

/// A complaint the customer filed — `GET /api/complaints` (a bare list
/// in `data`), and the echo of `POST /api/complaints`.
///
/// **The POST is open to guests; the GET is not.** Someone whose order
/// went wrong may have no account, or may be locked out of one, and
/// that is exactly when a complaints channel has to work — so an
/// unauthenticated `POST` is accepted with `name` + `contact` supplied
/// instead. It can never be tied to an account afterwards, which means
/// a guest's complaint will NOT appear in this list. Do not draw an
/// empty history as "you have no complaints" for a guest; draw the sign
/// in prompt.
///
/// The POST also sits on the strict `auth` rate limiter — 5 per minute,
/// shared with login and register — not on the loose `api` one. A retry
/// loop on submit will lock the customer out of logging in.
///
/// **[resolvedAt] is the reliable "is it closed" signal, not [status].**
/// [status] is a CMS-editable string: only `"new"` has been captured
/// live and the spec adds `"resolved"`, so any other value this build
/// has never heard of resolves to [ComplaintStatus.unknown]. A row with
/// a non-null [resolvedAt] is done regardless of what [status] says —
/// see [isResolved].
///
/// [reference] is the studio's ticket number as a STRING
/// (`"48392017"`) — not an int, and null until the studio assigns one
/// (null on both captured rows).
///
/// [type] is one of a documented, closed set — order, workshop,
/// delivery, payment, other — and is what the submit form's picker
/// offers. Read via [kind].
///
/// Timestamps carry an offset (`2026-08-26T11:45:48+00:00`) and are UTC.
@freezed
abstract class Complaint with _$Complaint {
  const factory Complaint({
    required int id,

    /// What it is about (`"delivery"`). Read via [kind].
    required String type,

    /// The customer's own words. Never localized, never a key.
    required String message,

    /// Studio ticket number, as a String. Null until assigned.
    String? reference,

    /// CMS-editable workflow state (`"new"`). Read via [statusKind],
    /// but prefer [isResolved].
    required String status,

    required DateTime createdAt,

    /// When the studio closed it. Null while open.
    DateTime? resolvedAt,
  }) = _Complaint;

  const Complaint._();

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);

  /// [type] resolved, falling back to [ComplaintType.other].
  ComplaintType get kind => ComplaintType.fromWire(type);

  /// [status] resolved. Unknown states come back as
  /// [ComplaintStatus.unknown] — show the raw [status] string rather
  /// than claiming a state.
  ComplaintStatus get statusKind => ComplaintStatus.fromWire(status);

  /// The studio has closed this one. Keyed off [resolvedAt], which is a
  /// timestamp the server sets, rather than off the editable [status].
  bool get isResolved => resolvedAt != null;
}

/// What a complaint is about — the closed set the submit form offers
/// and `type` echoes back.
enum ComplaintType {
  order('order'),
  workshop('workshop'),
  delivery('delivery'),
  payment('payment'),

  /// The documented catch-all, and the fallback for anything this
  /// build does not recognise.
  other('other');

  const ComplaintType(this.wire);

  /// The value as it arrives from the API, and the value to send on
  /// `POST /api/complaints`.
  final String wire;

  /// Resolves a wire value, falling back to [other] rather than
  /// throwing — a category added in the CMS must not crash the
  /// complaints list, and "other" is exactly what it is to this build.
  static ComplaintType fromWire(String? value) =>
      values.firstWhere((t) => t.wire == value, orElse: () => other);
}

/// Where a complaint got to.
///
/// The four the server defines — `new`, `in_progress`, `resolved`,
/// `closed` — and a fallback, because the set is the studio's and a
/// shipped app must survive a fifth.
enum ComplaintStatus {
  /// Filed, nobody has picked it up. The server's own default.
  opened('new'),

  /// Someone at the studio is on it.
  inProgress('in_progress'),

  /// Dealt with. The studio stamps `resolved_at` with it.
  resolved('resolved'),

  /// Shut without being resolved.
  closed('closed'),

  /// A workflow state this build has never heard of. Render neutrally;
  /// do not assume open or shut.
  unknown('unknown');

  const ComplaintStatus(this.wire);

  /// The value as it arrives from the API.
  final String wire;

  /// Whether the studio still has it open.
  bool get isOpen => this == opened || this == inProgress;

  static ComplaintStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => unknown);
}
