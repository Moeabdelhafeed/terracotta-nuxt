import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// Strings for the two stacks — `GlobalCardStack` and
/// `GlobalLayeredStack`.
///
/// A swipe deck and a pile are both invisible to a screen reader
/// without these: there is no scroll axis to announce, and a swipe is
/// not a gesture assistive tech can make.
class StackStrings {
  StackStrings._();

  /// "Card 2 of 5" — the deck's position. Deliberately not the page
  /// family's `Page x of y`: a card is not a page, and a deck that
  /// SHRINKS as it is used counts differently from one that does not.
  static String cardOf(int index, int total) => Tr.t(
    'stack.card_of',
    S.current.stack_card_of(
      AppNumbers.decimal(index),
      AppNumbers.decimal(total),
    ),
  );

  /// "Item 2 of 5" — a layered stack does not consume anything, so
  /// nothing here is a "card" being dealt.
  static String layerOf(int index, int total) => Tr.t(
    'stack.layer_of',
    S.current.stack_layer_of(
      AppNumbers.decimal(index),
      AppNumbers.decimal(total),
    ),
  );

  static String get swipeLeft =>
      Tr.t('stack.swipe_left', S.current.stack_swipe_left);
  static String get swipeRight =>
      Tr.t('stack.swipe_right', S.current.stack_swipe_right);
  static String get swipeUp => Tr.t('stack.swipe_up', S.current.stack_swipe_up);
  static String get swipeDown =>
      Tr.t('stack.swipe_down', S.current.stack_swipe_down);
}
