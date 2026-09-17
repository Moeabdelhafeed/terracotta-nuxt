import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../_shared/terracotta_image.dart';

/// The piece the customer just added, arcing into the cart glyph.
///
/// An OVERLAY, not a `Hero`. A Hero flies between routes, and nothing
/// is being pushed here: the page stays exactly where it is and only
/// the picture travels. It is also why this takes rectangles rather
/// than widgets — by the time it runs, both ends are already on screen
/// and their positions are all it needs.
///
/// The flight is only ever started AFTER the server has taken the item.
/// An animation that lands in the cart is a promise, and one made for a
/// request that then failed is a lie the customer discovers at
/// checkout.
Future<void> showFlyToCart({
  required OverlayState overlay,
  required ApiImage image,
  required Rect from,
  required Rect to,
  Duration duration = AppDurations.slow,
}) async {
  final entry = OverlayEntry(
    builder: (context) =>
        _Flight(image: image, from: from, to: to, duration: duration),
  );
  overlay.insert(entry);
  // Plus a beat, so the last frame is seen before the entry goes.
  await Future<void>.delayed(duration + AppDurations.micro);
  entry.remove();
}

class _Flight extends StatefulWidget {
  const _Flight({
    required this.image,
    required this.from,
    required this.to,
    required this.duration,
  });

  final ApiImage image;
  final Rect from;
  final Rect to;
  final Duration duration;

  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final t = Curves.easeInOutCubic.transform(_controller.value);
      final rect = Rect.lerp(widget.from, widget.to, t)!;

      // An ARC, not a straight line: the piece rises before it falls
      // into the cart, which is what makes it read as being carried
      // rather than dragged.
      final lift = -60.0 * (1 - (2 * t - 1) * (2 * t - 1));

      // The flight's coordinate space is PHYSICAL: both ends came from
      // `localToGlobal`, which has already accounted for the direction
      // the page was laid out in. Pinning the direction here says that
      // once, rather than every widget under it having to opt out of
      // being mirrored a second time.
      //
      // Without it a Stack aligns its children to
      // `AlignmentDirectional.topStart` — the RIGHT edge in Arabic — so
      // the same numbers were measured from the opposite side and the
      // piece flew to the mirror image of where the cart is.
      return Directionality(
        textDirection: TextDirection.ltr,
        child: IgnorePointer(
          child: Stack(
            children: [
              // A TRANSFORM rather than a positioned inset: these are
              // SCREEN coordinates taken from `localToGlobal`, so they
              // are already mirrored by the direction the page was laid
              // out in. A directional inset here would mirror them twice.
              Transform.translate(
                offset: rect.topLeft.translate(0, lift),
                child: SizedBox(
                  width: rect.width,
                  height: rect.height,
                  child: Opacity(
                    // Gone by the time it lands, so it does not sit on top
                    // of the glyph it flew into.
                    opacity: t < 0.85 ? 1 : (1 - t) / 0.15,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: TerracottaImage(image: widget.image),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
