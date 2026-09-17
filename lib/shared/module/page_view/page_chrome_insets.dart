import 'package:flutter/material.dart';

/// The sticky-chrome measurements every deck in the page family needs.
///
/// A header and a footer are OVERLAYS — they paint over the content
/// rather than taking a row of their own — and the indicator is
/// aligned against the same box, so without this it lands underneath
/// them: a footer bar draws straight over the dots.
///
/// Shared rather than copied. The page view solved it first and the
/// two carousels had the identical bug in identical code; a third copy
/// is how the indicator overlay and the A-Z scrubber drifted before
/// they were extracted.
mixin PageChromeInsets<T extends StatefulWidget> on State<T> {
  /// Wrap the header and the footer in `KeyedSubtree`s with these.
  final GlobalKey headerKey = GlobalKey(debugLabel: 'deck header');
  final GlobalKey footerKey = GlobalKey(debugLabel: 'deck footer');

  double _headerExtent = 0;
  double _footerExtent = 0;

  /// Whether the deck's own box reaches the screen edge, per edge.
  ///
  /// `SafeArea` applies the DEVICE's inset wherever it is put, and a
  /// deck is usually not at the edge — in a card halfway down a page
  /// it pushed the footer up by the home indicator's height and left a
  /// strip of content showing underneath it.
  bool atTopEdge = false;
  bool atBottomEdge = false;

  /// Call from `build`. Runs the measurement after the frame that laid
  /// the chrome out, and only when there is something to measure or a
  /// stale measurement to clear — leaving it out when the builders go
  /// away is how a removed footer kept its height forever.
  void scheduleChromeMeasure({required bool hasChrome}) {
    if (!hasChrome && _headerExtent == 0 && _footerExtent == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureChrome());
  }

  /// The indicator's padding plus room for whatever shares its edge.
  ///
  /// Both edges are added whichever way the indicator is aligned:
  /// padding on the far side grows the box away from the edge it is
  /// pinned to, so it costs nothing and the alignment stays the only
  /// thing deciding where the marks sit.
  EdgeInsets chromeInset(
    EdgeInsetsGeometry base, {
    double extraBottom = 0,
  }) {
    final resolved = base.resolve(Directionality.of(context));
    return resolved.copyWith(
      top: resolved.top + _headerExtent,
      bottom: resolved.bottom + _footerExtent + extraBottom,
    );
  }

  /// Reads the chrome's real height, and where the deck sits.
  ///
  /// A `LayoutBuilder` cannot do this: it knows what the Stack was
  /// GIVEN, not what a caller's header chose to be.
  void _measureChrome() {
    // FIRST: this runs a frame late, and by then the deck may be gone
    // — reading `context` on an unmounted State throws.
    if (!mounted) return;
    final header = _extentOf(headerKey);
    final footer = _extentOf(footerKey);

    var top = false;
    var bottom = false;
    final box = context.findRenderObject();
    if (box is RenderBox && box.attached && box.hasSize) {
      final origin = box.localToGlobal(Offset.zero);
      final screen = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context);
      // Within a point of the edge, because a fractional layout offset
      // is not "somewhere else".
      top = origin.dy <= padding.top + 1;
      bottom =
          origin.dy + box.size.height >= screen.height - padding.bottom - 1;
    }

    if (header == _headerExtent &&
        footer == _footerExtent &&
        top == atTopEdge &&
        bottom == atBottomEdge) {
      return;
    }
    setState(() {
      _headerExtent = header;
      _footerExtent = footer;
      atTopEdge = top;
      atBottomEdge = bottom;
    });
  }

  double _extentOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : 0;
  }
}
