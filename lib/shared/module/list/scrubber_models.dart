/// Which edge the A-Z scrubber lives on.
///
/// `start` / `end` are DIRECTIONAL — the strip follows the reading
/// side, so it lands under the thumb in Arabic too. `top` / `bottom`
/// lay it out horizontally, for a list whose sections read across
/// rather than down.
enum ScrubberPlacement {
  start,
  end,
  top,
  bottom;

  /// Whether the strip runs across rather than down.
  bool get isHorizontal =>
      this == ScrubberPlacement.top || this == ScrubberPlacement.bottom;
}
