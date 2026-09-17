/// How a piece of page chrome arrives when its route opens.
///
/// Shared by the app bar and the bottom nav so the two ends of a screen
/// can be told to arrive the same way, and so "staggered" means one
/// thing in the codebase rather than two.
enum EntranceKind {
  /// Already there. The default everywhere — chrome that animates in on
  /// every route change is chrome that is late on every route change.
  none,

  /// Travels in from its own edge: a bottom bar rises, a top bar drops.
  slide,

  fade,

  /// Grows from its own middle.
  scale,

  /// Travels and fades together, which reads as one movement.
  slideFade,

  /// Each child arrives after the one before it, in READING order.
  staggered,

  /// The surface slides and fades as a whole, AND its children stagger
  /// on top of that. Two movements that read as one arrival with depth
  /// to it, rather than a row of parts assembling themselves.
  slideFadeStaggered,
}

/// Whether this kind staggers its children at all.
bool isStaggered(EntranceKind kind) =>
    kind == EntranceKind.staggered || kind == EntranceKind.slideFadeStaggered;

/// Where one child's slice of a staggered entrance begins.
///
/// The index is already the reading position: a `Row` lays its children
/// out right-to-left under RTL, so child zero is the rightmost one —
/// which is where an Arabic reader starts. Mirroring the interval on
/// top of that runs the stagger from the wrong end of the bar in both
/// directions at once, which is exactly the bug this function exists to
/// stop being written again.
///
/// [spread] is how far into the entrance the LAST child starts; past
/// halfway and the tail of a five-item bar arrives after the page has
/// already settled.
double staggerStart({
  required int index,
  required int count,
  required double spread,
}) {
  if (count <= 1) return 0;
  final step = spread / (count - 1);
  return (step * index).clamp(0.0, 1.0);
}
