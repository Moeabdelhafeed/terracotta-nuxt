/// The staggered rhythm both gallery grids are laid out on.
///
/// One table, two callers: the album list and the opened album. They
/// have to agree with themselves — the grid lays a tile out at the
/// extractor's answer and the tile paints at whatever box it is given,
/// so two rules would put a 225-tall card in a 147-tall slot — and
/// they should agree with EACH OTHER, because the sheet opens on top
/// of the list and a different rhythm reads as a different screen.
abstract final class MasonryHeights {
  /// Four heights, cycled. Not random: the extractor is called on
  /// every layout pass, so a value that changed between passes would
  /// make tiles jump while the reader scrolls.
  static const table = [173.0, 199.0, 225.0, 147.0];

  /// Keyed on the row's ID, not its position — the position changes
  /// when a page of results is appended and the tile would resize
  /// under the reader's thumb.
  static double forId(int id) => table[id % table.length];
}
