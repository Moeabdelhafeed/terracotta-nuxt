import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `scroll_` key prefix family — the scroll shell's
/// chrome: the way back to the top, the progress strip, the "there is
/// new content above you" pill.
///
/// Every one of them was a hard-coded English literal inside
/// `scrollable/` and a second copy inside `list/`.
class ScrollStrings {
  ScrollStrings._();

  static String get toTop => Tr.t('scroll.to_top', S.current.scroll_to_top);
  static String get progress =>
      Tr.t('scroll.progress', S.current.scroll_progress);
  static String newItems(int count) =>
      Tr.t('scroll.new_items', S.current.scroll_new_items(count));
}
