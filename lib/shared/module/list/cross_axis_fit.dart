/// How a HORIZONTAL list decides its own height.
///
/// A horizontal viewport is handed its cross-axis extent by its
/// parent — it cannot work out how tall its children are without
/// laying them out, which is the thing virtualisation exists to avoid.
/// So anything but [parent] builds every item, and is right for a
/// strip of cards rather than a long list.
enum ListCrossAxisFit {
  /// The parent decides. The default, and the only one that keeps the
  /// list virtualised.
  parent,

  /// As tall as the tallest item in the WHOLE list — a fixed height,
  /// worked out once.
  tallestItem,

  /// As tall as the tallest item currently ON SCREEN, and it animates
  /// as that changes.
  ///
  /// The strip breathes with the content: scroll a tall card into
  /// view and it grows to meet it, scroll past and it settles back.
  /// Costs a measurement pass per scroll frame, which is cheap for a
  /// strip and another reason this is not for long lists.
  tallestVisible;

  bool get isFitted => this != ListCrossAxisFit.parent;
}
