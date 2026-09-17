import 'package:flutter/widgets.dart';

/// How the scrollable behaves when it reaches a boundary AND the
/// reader keeps dragging. Matters when scrollables nest — a list
/// inside a page body.
enum BoundaryBehavior {
  /// Overscroll bounces or clamps depending on physics. No
  /// coordination with parents.
  isolated,

  /// At the boundary, surplus drag is reported as an
  /// `OverscrollNotification`. An ancestor `GlobalScrollable` with
  /// `passThroughAtEdge: true` catches it and applies the delta to
  /// its own position — the page keeps scrolling once the inner list
  /// is spent.
  passThroughToParent,
}

/// Physics preset. The widget composes the matching [ScrollPhysics].
enum ScrollableMode {
  /// Platform default — bouncing on iOS / macOS, clamping elsewhere.
  platform,

  /// `BouncingScrollPhysics` everywhere. Required for pull-up /
  /// pull-down overscroll detection.
  bounce,

  /// `ClampingScrollPhysics` everywhere. Cleaner edges, and it emits
  /// the `OverscrollNotification` that
  /// [BoundaryBehavior.passThroughToParent] rides on.
  clamp,
}

/// Which edge effect is drawn at the start / end of a viewport.
enum EdgeFadeMode {
  none,

  /// Colour gradient (surface → transparent). Content disappears into
  /// the page colour. Looks like fog; wrong over a photograph.
  scrim,

  /// `ShaderMask` with `BlendMode.dstIn` — pixels at the edge become
  /// literally transparent, whatever is behind them.
  ///
  /// The one to reach for on a page shell: a single saveLayer, and it
  /// is skipped outright while neither band is showing.
  shader,

  /// A dark gradient inset from the edge — the content reads as
  /// recessed into a well.
  innerShadow,
}

/// How an item arrives.
///
/// Shared by the list's `animateChanges`, the grid's, and the
/// scroll-in animator that lives in this folder — which is why it
/// lives HERE rather than in `list/`, where the animator had to import
/// the list module to name its own parameter.
/// How an item arrives.
///
/// Shared by the list's `animateChanges`, the grid's, and the
/// scroll-in animator that lives in this folder — which is why it
/// lives HERE rather than in `list/`, where the animator had to import
/// the list module to name its own parameter.
enum ListItemAnimation {
  /// Slide from zero height + fade. The default.
  fadeSize,

  /// Slide in from the LEFT + fade. Physical: it keeps its side in
  /// every language.
  slideFromLeft,

  /// Slide in from the RIGHT + fade. Physical.
  slideFromRight,

  /// Slide in from where the reading starts + fade. **Mirrors**: the
  /// left in English, the right in Arabic.
  ///
  /// The physical pair keeps its side on purpose — a row that arrives
  /// from the side its own control is on should not swap when the app
  /// is translated. This pair is for the other case: content that
  /// arrives "from the beginning", which is a different edge in a
  /// different language.
  slideFromStart,

  /// Slide in from where the reading ends + fade. **Mirrors.**
  slideFromEnd,

  /// Slide up from below + fade.
  slideFromBottom,

  /// Slide down from above + fade.
  slideFromTop,

  /// Scale in from zero + fade.
  scale,

  /// Pure fade, no size change.
  fade,
}

/// Where the scroll-progress strip sits on the box.
enum ScrollProgressPlacement {
  /// Against the top edge — the reading-progress bar every article
  /// page has.
  top,

  /// Against the bottom edge.
  bottom,
}

/// Resolves a [ScrollPhysics] for a [ScrollableMode].
///
/// `null` means "let the framework pick" — `ScrollConfiguration` or
/// the platform default.
ScrollPhysics? resolvePhysics(ScrollableMode mode, {ScrollPhysics? caller}) {
  if (caller != null) return caller;
  return switch (mode) {
    ScrollableMode.platform => null,
    ScrollableMode.bounce => const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    ScrollableMode.clamp => const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
  };
}

/// Resolves the mirroring members of [ListItemAnimation] against the
/// reading direction.
///
/// This is the same split the navigation transitions make:
/// `slideFromRight` keeps its side in every language, and
/// `slideFromStart` / `slideFromEnd` follow the reader. Call it once,
/// at build time — the physical members pass straight through, so it
/// is safe on any value.
extension ListItemAnimationDirection on ListItemAnimation {
  ListItemAnimation resolveDirection(TextDirection direction) {
    final rtl = direction == TextDirection.rtl;
    return switch (this) {
      ListItemAnimation.slideFromStart =>
        rtl
            ? ListItemAnimation.slideFromRight
            : ListItemAnimation.slideFromLeft,
      ListItemAnimation.slideFromEnd =>
        rtl
            ? ListItemAnimation.slideFromLeft
            : ListItemAnimation.slideFromRight,
      _ => this,
    };
  }

  /// The same animation coming from the other side — what a
  /// direction-aware list uses when the reader scrolls back.
  ListItemAnimation get flipped => switch (this) {
    ListItemAnimation.slideFromTop => ListItemAnimation.slideFromBottom,
    ListItemAnimation.slideFromBottom => ListItemAnimation.slideFromTop,
    ListItemAnimation.slideFromLeft => ListItemAnimation.slideFromRight,
    ListItemAnimation.slideFromRight => ListItemAnimation.slideFromLeft,
    ListItemAnimation.slideFromStart => ListItemAnimation.slideFromEnd,
    ListItemAnimation.slideFromEnd => ListItemAnimation.slideFromStart,
    _ => this,
  };
}
