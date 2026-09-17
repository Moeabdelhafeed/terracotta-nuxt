import '../../../data/models/terracotta/account/complaint.dart';
import '../../../generated/l10n.dart';
import '../tr.dart';

/// «تواصل معنا» — telling the studio something went wrong.
class ComplaintStrings {
  ComplaintStrings._();

  static String get title => Tr.t('complaint_title', S.current.complaint_title);

  static String get newOne => Tr.t('complaint_new', S.current.complaint_new);

  static String get mine => Tr.t('complaint_mine', S.current.complaint_mine);

  static String get empty => Tr.t('complaint_empty', S.current.complaint_empty);

  static String get emptyBody =>
      Tr.t('complaint_empty_body', S.current.complaint_empty_body);

  static String get type => Tr.t('complaint_type', S.current.complaint_type);

  static String get reference =>
      Tr.t('complaint_reference', S.current.complaint_reference);

  static String get referenceHint => Tr.t(
    'complaint_reference_hint',
    S.current.complaint_reference_hint,
  );

  static String get message =>
      Tr.t('complaint_message', S.current.complaint_message);

  static String get messageHint =>
      Tr.t('complaint_message_hint', S.current.complaint_message_hint);

  static String get name => Tr.t('complaint_name', S.current.complaint_name);

  static String get contact =>
      Tr.t('complaint_contact', S.current.complaint_contact);

  static String get send => Tr.t('complaint_send', S.current.complaint_send);

  static String get sent => Tr.t('complaint_sent', S.current.complaint_sent);

  /// What the complaint is ABOUT, in the customer's words.
  ///
  /// Mapped, never printed raw — the wire sends `order`, `workshop`,
  /// `delivery`, `payment`, `other`, and an unrecognised one is
  /// "something else", which is exactly what it is to this build.
  static String kind(ComplaintType type) => switch (type) {
    ComplaintType.order => Tr.t(
      'complaint_type_order',
      S.current.complaint_type_order,
    ),
    ComplaintType.workshop => Tr.t(
      'complaint_type_workshop',
      S.current.complaint_type_workshop,
    ),
    ComplaintType.delivery => Tr.t(
      'complaint_type_delivery',
      S.current.complaint_type_delivery,
    ),
    ComplaintType.payment => Tr.t(
      'complaint_type_payment',
      S.current.complaint_type_payment,
    ),
    ComplaintType.other => Tr.t(
      'complaint_type_other',
      S.current.complaint_type_other,
    ),
  };

  /// Where it got to.
  ///
  /// The studio owns this set and can add to it, so an unknown state
  /// reads as OPEN rather than inventing a word: the customer's
  /// question is whether anyone still has it.
  static String status(ComplaintStatus status) => switch (status) {
    ComplaintStatus.opened || ComplaintStatus.unknown => Tr.t(
      'complaint_status_new',
      S.current.complaint_status_new,
    ),
    ComplaintStatus.inProgress => Tr.t(
      'complaint_status_in_progress',
      S.current.complaint_status_in_progress,
    ),
    ComplaintStatus.resolved => Tr.t(
      'complaint_status_resolved',
      S.current.complaint_status_resolved,
    ),
    ComplaintStatus.closed => Tr.t(
      'complaint_status_closed',
      S.current.complaint_status_closed,
    ),
  };

  /// «إرسال شكوى» — what the row in «حسابي» says.
  ///
  /// [title] is the screen's own heading and stays «تواصل معنا» where
  /// the design puts it; this is the ROW, which had to give that name
  /// back to the contact sheet. Filing a complaint and messaging the
  /// studio are different errands and a customer should not have to
  /// guess which one a row means.
  static String get sendTitle =>
      Tr.t('complaint_send_title', S.current.complaint_send_title);
}
