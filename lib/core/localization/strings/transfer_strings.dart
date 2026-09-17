import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// Moving what a visitor collected into the account they just made.
///
/// **Never the word "migrate".** It is a database operation, not
/// something a customer does with a cup they liked. Every line here
/// names the THINGS — «قطعتان في سلتك» — because the reader is deciding
/// about those, not about a mechanism.
class TransferStrings {
  TransferStrings._();

  static String get title => Tr.t('transfer_title', S.current.transfer_title);
  static String get body => Tr.t('transfer_body', S.current.transfer_body);

  /// Counts go through `localizeDigits`: an ICU plural interpolates in
  /// ASCII even under `ar`.
  static String basket(int count) => AppNumbers.localizeDigits(
    Tr.t('transfer_basket', S.current.transfer_basket(count)),
  );
  static String saved(int count) => AppNumbers.localizeDigits(
    Tr.t('transfer_saved', S.current.transfer_saved(count)),
  );

  /// «عنوانان» — the addresses on the device.
  ///
  /// A visitor filling in a delivery address is about to buy something,
  /// so this is the group they most want to keep.
  static String addresses(int count) => AppNumbers.localizeDigits(
    Tr.t('transfer_addresses', S.current.transfer_addresses(count)),
  );

  static String get confirm =>
      Tr.t('transfer_confirm', S.current.transfer_confirm);
  static String get skip => Tr.t('transfer_skip', S.current.transfer_skip);

  /// Leaving them behind DELETES them, and the sheet says so before it
  /// happens — the customer picked these one at a time.
  static String get discardTitle =>
      Tr.t('transfer_discard_title', S.current.transfer_discard_title);
  static String get discardBody =>
      Tr.t('transfer_discard_body', S.current.transfer_discard_body);
  static String get discardConfirm =>
      Tr.t('transfer_discard_confirm', S.current.transfer_discard_confirm);

  static String done(int count) => AppNumbers.localizeDigits(
    Tr.t('transfer_done', S.current.transfer_done(count)),
  );

  /// Some pieces sold out while they were browsing. Said plainly rather
  /// than swallowed — a basket that quietly arrives shorter is worse
  /// than one that explains itself.
  static String partial(int count) => AppNumbers.localizeDigits(
    Tr.t('transfer_partial', S.current.transfer_partial(count)),
  );
}
